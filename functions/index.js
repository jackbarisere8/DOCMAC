'use strict';

const admin = require('firebase-admin');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions/logger');

const {
  normalizeEmail,
  emailKey,
  hashCode,
  generateCode,
  generateToken,
  constantTimeEqual,
  isAcceptablePassword,
  sha256Hex,
} = require('./lib/security');
const { normalizeHandle, directChatId } = require('./lib/chat');
const { sendResetCode } = require('./lib/mail');

admin.initializeApp();

const REGION = 'us-central1';

// Bound to the functions below. Create them before deploying:
//   firebase functions:secrets:set RESET_OTP_PEPPER
//   firebase functions:secrets:set RESEND_API_KEY
const SECRETS = ['RESET_OTP_PEPPER', 'RESEND_API_KEY'];

const CODE_TTL_MS = 10 * 60 * 1000;
const TOKEN_TTL_MS = 10 * 60 * 1000;
const MAX_ATTEMPTS = 5;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_PER_WINDOW = 5;
const WINDOW_MS = 60 * 60 * 1000;

const CODE_PATTERN = /^\d{6}$/;
const TOKEN_PATTERN = /^[a-f0-9]{64}$/;

class ResetError extends Error {
  constructor(code) {
    super(code);
    this.code = code;
  }
}

function isEmulator() {
  return process.env.FUNCTIONS_EMULATOR === 'true';
}

function pepper() {
  const value = process.env.RESET_OTP_PEPPER;
  if (typeof value === 'string' && value.length >= 16) return value;
  if (isEmulator()) return 'docmac-emulator-only-pepper';
  throw new Error('RESET_OTP_PEPPER is not configured.');
}

function fail(res, status, error, extra = {}) {
  return res.status(status).json({ ok: false, error, ...extra });
}

function nowTimestamp() {
  return admin.firestore.Timestamp.fromMillis(Date.now());
}

/**
 * Counts a request against the per-address window. Runs for every address,
 * including ones with no account, so the endpoint's timing and status cannot
 * reveal which emails are registered.
 */
async function consumeThrottle(key) {
  const ref = admin
    .firestore()
    .collection('passwordResetThrottle')
    .doc(key);
  const now = Date.now();

  return admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() : null;

    const windowStart = data?.windowStartedAt?.toMillis?.() ?? 0;
    const lastSent = data?.lastSentAt?.toMillis?.() ?? 0;
    let count = typeof data?.count === 'number' ? data.count : 0;
    let windowStartedAt = windowStart;

    if (now - windowStart >= WINDOW_MS) {
      count = 0;
      windowStartedAt = now;
    }

    if (now - lastSent < RESEND_COOLDOWN_MS) {
      return {
        allowed: false,
        retryAfter: Math.ceil((RESEND_COOLDOWN_MS - (now - lastSent)) / 1000),
      };
    }

    if (count >= MAX_PER_WINDOW) {
      return {
        allowed: false,
        retryAfter: Math.max(1, Math.ceil((WINDOW_MS - (now - windowStart)) / 1000)),
      };
    }

    tx.set(
      ref,
      {
        count: count + 1,
        windowStartedAt: admin.firestore.Timestamp.fromMillis(windowStartedAt),
        lastSentAt: admin.firestore.Timestamp.fromMillis(now),
      },
      { merge: true },
    );

    return { allowed: true };
  });
}

async function findUserByEmail(email) {
  try {
    return await admin.auth().getUserByEmail(email);
  } catch (error) {
    if (error?.code === 'auth/user-not-found') return null;
    throw error;
  }
}

/**
 * Step 1 — issue a six-digit code.
 *
 * Always resolves as a success for well-formed addresses. A caller must not be
 * able to tell "code sent" from "no such account".
 */
exports.resetRequest = onRequest(
  {
    region: REGION,
    cors: true,
    secrets: SECRETS,
    timeoutSeconds: 30,
    memory: '256MiB',
  },
  async (req, res) => {
    if (req.method !== 'POST') return fail(res, 405, 'method_not_allowed');

    const email = normalizeEmail(req.body?.email);
    if (!email) return fail(res, 400, 'invalid_email');

    const key = emailKey(email);

    try {
      const throttle = await consumeThrottle(key);
      if (!throttle.allowed) {
        return fail(res, 429, 'rate_limited', {
          retryAfterSeconds: throttle.retryAfter,
        });
      }

      const user = await findUserByEmail(email);
      // Every well-formed address gets the same response shape. Returning
      // `expiresInSeconds` only for registered accounts would let a caller
      // enumerate which emails have Docmac accounts.
      const body = {
        ok: true,
        expiresInSeconds: Math.round(CODE_TTL_MS / 1000),
      };
      if (!user) return res.status(200).json(body);

      const code = generateCode();
      const createdAt = Date.now();

      await admin
        .firestore()
        .collection('passwordResetCodes')
        .doc(key)
        .set({
          uid: user.uid,
          codeHash: hashCode(email, code, pepper()),
          attempts: 0,
          createdAt: admin.firestore.Timestamp.fromMillis(createdAt),
          expiresAt: admin.firestore.Timestamp.fromMillis(createdAt + CODE_TTL_MS),
        });

      const delivered = await sendResetCode({
        to: email,
        code,
        minutes: Math.round(CODE_TTL_MS / 60000),
        apiKey: process.env.RESEND_API_KEY,
        from: process.env.RESET_FROM_EMAIL || 'Docmac <no-reply@docmac.app>',
      });

      if (!delivered) {
        logger.error('Reset code stored but not delivered.', { key });
      }

      // Local emulator only, and only when explicitly opted in. This keeps the
      // flow testable without a mail provider and can never run in production.
      if (isEmulator() && process.env.ALLOW_DEV_CODE === 'true') {
        body.devCode = code;
      }

      return res.status(200).json(body);
    } catch (error) {
      logger.error('resetRequest failed.', { message: error?.message });
      return fail(res, 500, 'server_error');
    }
  },
);

/**
 * Step 2 — trade a valid code for a short-lived, single-use reset token.
 * The code is destroyed as soon as it succeeds.
 */
exports.resetVerify = onRequest(
  {
    region: REGION,
    cors: true,
    secrets: SECRETS,
    timeoutSeconds: 30,
    memory: '256MiB',
  },
  async (req, res) => {
    if (req.method !== 'POST') return fail(res, 405, 'method_not_allowed');

    const email = normalizeEmail(req.body?.email);
    const code = String(req.body?.code ?? '').trim();

    if (!email) return fail(res, 400, 'invalid_email');
    if (!CODE_PATTERN.test(code)) return fail(res, 400, 'invalid_code');

    try {
      const db = admin.firestore();
      const ref = db.collection('passwordResetCodes').doc(emailKey(email));
      const snap = await ref.get();

      if (!snap.exists) return fail(res, 400, 'invalid_code');

      const data = snap.data();
      const expiresAt = data?.expiresAt?.toMillis?.() ?? 0;

      if (expiresAt <= Date.now()) {
        await ref.delete().catch(() => {});
        return fail(res, 400, 'code_expired');
      }

      if ((data?.attempts ?? 0) >= MAX_ATTEMPTS) {
        return fail(res, 429, 'too_many_attempts');
      }

      const expected = data?.codeHash;
      const provided = hashCode(email, code, pepper());

      if (typeof expected !== 'string' || !constantTimeEqual(provided, expected)) {
        await ref.update({
          attempts: admin.firestore.FieldValue.increment(1),
        });
        return fail(res, 400, 'invalid_code');
      }

      const uid = data?.uid;
      if (typeof uid !== 'string' || uid.length === 0) {
        await ref.delete().catch(() => {});
        return fail(res, 400, 'invalid_code');
      }

      await ref.delete();

      const token = generateToken();
      const issuedAt = Date.now();

      await db
        .collection('passwordResetTokens')
        .doc(sha256Hex(`${token}:${pepper()}`))
        .set({
          uid,
          used: false,
          createdAt: admin.firestore.Timestamp.fromMillis(issuedAt),
          expiresAt: admin.firestore.Timestamp.fromMillis(issuedAt + TOKEN_TTL_MS),
        });

      return res.status(200).json({
        ok: true,
        token,
        expiresInSeconds: Math.round(TOKEN_TTL_MS / 1000),
      });
    } catch (error) {
      logger.error('resetVerify failed.', { message: error?.message });
      return fail(res, 500, 'server_error');
    }
  },
);

/**
 * Step 3 — set the new password with the Admin SDK, then revoke every existing
 * refresh token so a stolen session cannot survive a reset.
 */
exports.resetComplete = onRequest(
  {
    region: REGION,
    cors: true,
    secrets: SECRETS,
    timeoutSeconds: 30,
    memory: '256MiB',
  },
  async (req, res) => {
    if (req.method !== 'POST') return fail(res, 405, 'method_not_allowed');

    const token = String(req.body?.token ?? '');
    const password = req.body?.password;

    if (!TOKEN_PATTERN.test(token)) return fail(res, 400, 'invalid_token');
    if (!isAcceptablePassword(password)) return fail(res, 400, 'weak_password');

    const tokenRef = admin
      .firestore()
      .collection('passwordResetTokens')
      .doc(sha256Hex(`${token}:${pepper()}`));

    let uid;
    try {
      uid = await admin.firestore().runTransaction(async (tx) => {
        const snap = await tx.get(tokenRef);
        if (!snap.exists) throw new ResetError('invalid_token');

        const data = snap.data();
        if (data?.used === true) throw new ResetError('invalid_token');
        if ((data?.expiresAt?.toMillis?.() ?? 0) <= Date.now()) {
          throw new ResetError('invalid_token');
        }

        tx.update(tokenRef, {
          used: true,
          usedAt: nowTimestamp(),
        });

        return data?.uid;
      });
    } catch (error) {
      if (error instanceof ResetError) return fail(res, 400, error.code);
      logger.error('resetComplete token check failed.', { message: error?.message });
      return fail(res, 500, 'server_error');
    }

    if (typeof uid !== 'string' || uid.length === 0) {
      return fail(res, 400, 'invalid_token');
    }

    try {
      await admin.auth().updateUser(uid, { password });
      await admin.auth().revokeRefreshTokens(uid);
      await tokenRef.delete().catch(() => {});

      logger.info('Password reset completed.', { uid });
      return res.status(200).json({ ok: true });
    } catch (error) {
      logger.error('resetComplete update failed.', {
        uid,
        code: error?.code,
        message: error?.message,
      });

      if (error?.code === 'auth/weak-password') {
        return fail(res, 400, 'weak_password');
      }
      return fail(res, 500, 'server_error');
    }
  },
);

/**
 * Returns the canonical 1:1 chat for the caller and a peer. The chat id is
 * derived from the two UIDs, so both people land in the same conversation no
 * matter who opens it first. Only this function may create chat documents;
 * clients are denied by `firestore.rules`.
 */
exports.ensureDirectChat = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    memory: '256MiB',
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Sign in to start a talk.');
    }

    const currentUid = request.auth.uid;
    const data = request.data && typeof request.data === 'object' ? request.data : {};
    let peerUid =
      typeof data.peerUid === 'string' ? data.peerUid.trim() : '';
    const requestedHandle = normalizeHandle(data.peerHandle);

    const db = admin.firestore();

    if (!peerUid && requestedHandle) {
      const handleSnap = await db.collection('handles').doc(requestedHandle).get();
      const handleData = handleSnap.exists ? handleSnap.data() : null;
      if (!handleData || handleData.kind !== 'user') {
        throw new HttpsError('not-found', 'That username is not on Docmac.');
      }
      peerUid = String(handleData.ownerId || '');
    }

    if (!peerUid) {
      throw new HttpsError('invalid-argument', 'Choose someone to talk to.');
    }
    if (peerUid === currentUid) {
      throw new HttpsError('failed-precondition', 'You cannot start a talk with yourself.');
    }

    let currentAuth;
    let peerAuth;
    try {
      [currentAuth, peerAuth] = await Promise.all([
        admin.auth().getUser(currentUid),
        admin.auth().getUser(peerUid),
      ]);
    } catch (error) {
      if (error?.code === 'auth/user-not-found') {
        throw new HttpsError('not-found', 'That account no longer exists.');
      }
      throw new HttpsError('internal', 'Could not resolve that account.');
    }

    const [currentProfileSnap, peerProfileSnap] = await Promise.all([
      db.collection('publicProfiles').doc(currentUid).get(),
      db.collection('publicProfiles').doc(peerUid).get(),
    ]);
    const currentProfile = currentProfileSnap.exists
      ? currentProfileSnap.data()
      : null;
    const peerProfile = peerProfileSnap.exists ? peerProfileSnap.data() : null;

    const currentName =
      (currentProfile?.displayName || currentAuth.displayName || '').trim() ||
      currentAuth.email?.split('@')[0] ||
      'Docmac member';
    const peerName =
      (peerProfile?.displayName || peerAuth.displayName || '').trim() ||
      peerAuth.email?.split('@')[0] ||
      'Docmac member';
    const currentHandle =
      typeof currentProfile?.username === 'string'
        ? currentProfile.username
        : null;
    const peerHandle =
      typeof peerProfile?.username === 'string'
        ? peerProfile.username
        : requestedHandle;

    const chatId = directChatId(currentUid, peerUid);
    const chatRef = db.collection('chats').doc(chatId);
    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.runTransaction(async (tx) => {
      const snapshot = await tx.get(chatRef);
      if (!snapshot.exists) {
        tx.set(chatRef, {
          id: chatId,
          type: 'direct',
          isGroup: false,
          participantIds: [currentUid, peerUid],
          participantNames: {
            [currentUid]: currentName,
            [peerUid]: peerName,
          },
          participantHandles: {
            ...(currentHandle ? { [currentUid]: currentHandle } : {}),
            ...(peerHandle ? { [peerUid]: peerHandle } : {}),
          },
          createdBy: currentUid,
          createdAt: now,
          updatedAt: now,
          lastMessage: '',
          lastMessageAt: null,
          lastSenderId: null,
          unreadCount: 0,
        });
      } else {
        const existing = snapshot.data() || {};
        const participants = Array.isArray(existing.participantIds)
          ? existing.participantIds
          : [];
        if (!participants.includes(currentUid) || !participants.includes(peerUid)) {
          throw new HttpsError(
            'permission-denied',
            'This conversation belongs to other accounts.',
          );
        }
        tx.set(
          chatRef,
          {
            participantNames: {
              ...(existing.participantNames || {}),
              [currentUid]: currentName,
              [peerUid]: peerName,
            },
            participantHandles: {
              ...(existing.participantHandles || {}),
              ...(currentHandle ? { [currentUid]: currentHandle } : {}),
              ...(peerHandle ? { [peerUid]: peerHandle } : {}),
            },
            updatedAt: now,
          },
          { merge: true },
        );
      }

      tx.set(
        chatRef.collection('members').doc(currentUid),
        {
          uid: currentUid,
          displayName: currentName,
          handle: currentHandle,
          joinedAt: now,
        },
        { merge: true },
      );
      tx.set(
        chatRef.collection('members').doc(peerUid),
        {
          uid: peerUid,
          displayName: peerName,
          handle: peerHandle,
          joinedAt: now,
        },
        { merge: true },
      );
    });

    return {
      chatId,
      peerUid,
      peerName,
      peerHandle,
    };
  },
);

async function deleteMatching(db, query) {
  const snapshot = await query.get();
  for (const doc of snapshot.docs) {
    await db.recursiveDelete(doc.ref);
  }
  return snapshot.size;
}

/**
 * Permanently deletes the caller's account and owned data. The callable uses
 * the authenticated UID, so one account can never ask the server to delete a
 * different account. Delivered messages in another person's conversation are
 * intentionally retained; the deleted account is removed from the chat's
 * participant list and can no longer read it.
 */
exports.deleteAccount = onCall(
  {
    region: REGION,
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Sign in to delete your account.');
    }

    const uid = request.auth.uid;
    const db = admin.firestore();

    const userRef = db.collection('users').doc(uid);
    const userSnap = await userRef.get();
    const username = userSnap.exists ? userSnap.data()?.username : null;

    if (typeof username === 'string' && username) {
      const usernameRef = db.collection('usernames').doc(username);
      const usernameSnap = await usernameRef.get();
      if (usernameSnap.exists && usernameSnap.data()?.uid === uid) {
        await usernameRef.delete();
      }

      const userHandleRef = db.collection('handles').doc(username);
      const userHandleSnap = await userHandleRef.get();
      if (
        userHandleSnap.exists &&
        userHandleSnap.data()?.ownerId === uid &&
        userHandleSnap.data()?.kind === 'user'
      ) {
        await userHandleRef.delete();
      }
    }

    await db.recursiveDelete(userRef);
    await db.recursiveDelete(db.collection('publicProfiles').doc(uid));

    // Operator handles and relays owned by this account.
    await deleteMatching(db, db.collection('handles').where('ownerId', '==', uid));
    await deleteMatching(db, db.collection('relays').where('ownerId', '==', uid));

    // Scheduled calls are private to their organizer.
    await deleteMatching(
      db,
      db.collection('callSchedules').where('organizerId', '==', uid),
    );

    // Remove this account from conversations. Chats with other participants
    // stay intact so their delivered history is not destroyed.
    const chats = await db
      .collection('chats')
      .where('participantIds', 'array-contains', uid)
      .get();

    for (const chat of chats.docs) {
      const data = chat.data() || {};
      const participants = Array.isArray(data.participantIds)
        ? data.participantIds.filter((id) => id !== uid)
        : [];

      await chat.ref.collection('members').doc(uid).delete().catch(() => {});

      if (participants.length === 0) {
        await db.recursiveDelete(chat.ref);
        continue;
      }

      const names = { ...(data.participantNames || {}) };
      const handles = { ...(data.participantHandles || {}) };
      delete names[uid];
      delete handles[uid];
      const isGroup = data.isGroup === true || data.type === 'group';
      await chat.ref.set(
        {
          participantIds: participants,
          participantNames: names,
          participantHandles: handles,
          ...(!isGroup && participants.length === 1
            ? { name: 'Deleted account' }
            : {}),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    // Best-effort object cleanup. Accounts created before Storage was enabled
    // have no bucket, so absence is not an error.
    try {
      await admin.storage().bucket().deleteFiles({ prefix: `users/${uid}/` });
    } catch (error) {
      logger.warn('Account media cleanup skipped.', {
        uid,
        code: error?.code,
        message: error?.message,
      });
    }

    try {
      await admin.auth().deleteUser(uid);
    } catch (error) {
      if (error?.code !== 'auth/user-not-found') {
        logger.error('Auth account deletion failed.', {
          uid,
          code: error?.code,
          message: error?.message,
        });
        throw new HttpsError(
          'internal',
          'Your data was removed but the sign-in record could not be deleted. Contact support.',
        );
      }
    }

    logger.info('Account deleted.', { uid });
    return { ok: true };
  },
);
