import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const PROJECT_ID = 'demo-docmac-rules';
const ALICE = 'alice';
const BOB = 'bob';
const CAROL = 'carol';
const CHAT_ID = 'direct_alice__bob';
const TS = Timestamp.fromDate(new Date('2026-01-01T00:00:00Z'));

let testEnv;

function dbFor(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function anonDb() {
  return testEnv.unauthenticatedContext().firestore();
}

async function seed() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    // New-style direct chat with membership documents.
    await setDoc(doc(db, 'chats', CHAT_ID), {
      participantIds: [ALICE, BOB],
      participantNames: { [ALICE]: 'Alice', [BOB]: 'Bob' },
      participantHandles: { [ALICE]: 'alice', [BOB]: 'bob' },
      lastMessage: 'hello',
      lastMessageAt: TS,
      lastSenderId: ALICE,
      unreadCount: 0,
      updatedAt: TS,
    });
    await setDoc(doc(db, 'chats', CHAT_ID, 'members', ALICE), {
      uid: ALICE,
    });
    await setDoc(doc(db, 'chats', CHAT_ID, 'members', BOB), { uid: BOB });
    await setDoc(doc(db, 'chats', CHAT_ID, 'messages', 'msg1'), {
      id: 'msg1',
      chatId: CHAT_ID,
      senderId: BOB,
      text: 'hi Alice',
      createdAt: TS,
      isRead: false,
    });

    // Legacy chat without membership documents.
    await setDoc(doc(db, 'chats', 'legacy_alice__carol'), {
      participantIds: [ALICE, CAROL],
      unreadCount: 0,
      updatedAt: TS,
    });

    // A chat that neither Alice nor BOB's other contexts may read.
    await setDoc(doc(db, 'chats', 'private_bob__carol'), {
      participantIds: [BOB, CAROL],
      unreadCount: 0,
      updatedAt: TS,
    });

    await setDoc(doc(db, 'publicProfiles', ALICE), {
      uid: ALICE,
      username: 'alice',
      displayName: 'Alice',
      updatedAt: TS,
    });
    await setDoc(doc(db, 'users', ALICE), {
      uid: ALICE,
      phoneNumber: '+10000000000',
    });
    await setDoc(doc(db, 'usernames', 'alice'), { uid: ALICE });
    await setDoc(doc(db, 'handles', 'alice'), {
      kind: 'user',
      ownerId: ALICE,
    });
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seed();
});

after(async () => {
  await testEnv.cleanup();
});

describe('chats', () => {
  it('lets a member read a chat through its membership document', async () => {
    await assertSucceeds(getDoc(doc(dbFor(ALICE), 'chats', CHAT_ID)));
  });

  it('lets a legacy participant read a chat without membership documents', async () => {
    await assertSucceeds(
      getDoc(doc(dbFor(ALICE), 'chats', 'legacy_alice__carol')),
    );
  });

  it('denies a non-member reading someone else\'s chat', async () => {
    await assertFails(
      getDoc(doc(dbFor(ALICE), 'chats', 'private_bob__carol')),
    );
  });

  it('denies unauthenticated reads', async () => {
    await assertFails(getDoc(doc(anonDb(), 'chats', CHAT_ID)));
  });

  it('denies client chat creation even for the listed participants', async () => {
    await assertFails(
      setDoc(doc(dbFor(ALICE), 'chats', 'direct_alice__carol'), {
        participantIds: [ALICE, CAROL],
        unreadCount: 0,
        updatedAt: TS,
      }),
    );
  });

  it('allows the inbox query filtered by participantIds', async () => {
    await assertSucceeds(
      getDocs(
        query(
          collection(dbFor(ALICE), 'chats'),
          where('participantIds', 'array-contains', ALICE),
        ),
      ),
    );
  });

  it('denies an unfiltered chat list that could expose other chats', async () => {
    await assertFails(getDocs(collection(dbFor(ALICE), 'chats')));
  });

  it('denies client chat deletion', async () => {
    await assertFails(deleteDoc(doc(dbFor(ALICE), 'chats', CHAT_ID)));
  });

  it('denies rewriting participant membership', async () => {
    await assertFails(
      updateDoc(doc(dbFor(ALICE), 'chats', CHAT_ID), {
        participantIds: [ALICE, CAROL],
      }),
    );
  });

  it('allows a member to refresh the message preview as themselves', async () => {
    await assertSucceeds(
      updateDoc(doc(dbFor(ALICE), 'chats', CHAT_ID), {
        lastMessage: 'updated preview',
        lastMessageAt: TS,
        lastSenderId: ALICE,
        updatedAt: TS,
      }),
    );
  });

  it('denies a preview update that spoofs another sender', async () => {
    await assertFails(
      updateDoc(doc(dbFor(ALICE), 'chats', CHAT_ID), {
        lastMessage: 'spoofed',
        lastMessageAt: TS,
        lastSenderId: BOB,
        updatedAt: TS,
      }),
    );
  });

  it('allows a member to clear the unread count', async () => {
    await assertSucceeds(
      updateDoc(doc(dbFor(ALICE), 'chats', CHAT_ID), {
        unreadCount: 0,
        updatedAt: TS,
      }),
    );
  });

  it('denies ordinary members writing membership documents', async () => {
    await assertFails(
      setDoc(doc(dbFor(ALICE), 'chats', CHAT_ID, 'members', CAROL), {
        uid: CAROL,
      }),
    );
  });
});

describe('messages', () => {
  function validMessage(overrides = {}) {
    return {
      id: 'msg2',
      chatId: CHAT_ID,
      senderId: ALICE,
      text: 'hello Bob',
      createdAt: TS,
      isRead: false,
      ...overrides,
    };
  }

  it('lets a member create their own text message', async () => {
    await assertSucceeds(
      setDoc(
        doc(dbFor(ALICE), 'chats', CHAT_ID, 'messages', 'msg2'),
        validMessage(),
      ),
    );
  });

  it('denies spoofing another sender', async () => {
    await assertFails(
      setDoc(
        doc(dbFor(ALICE), 'chats', CHAT_ID, 'messages', 'msg2'),
        validMessage({ senderId: BOB }),
      ),
    );
  });

  it('denies a message whose stored chatId does not match the path', async () => {
    await assertFails(
      setDoc(
        doc(dbFor(ALICE), 'chats', CHAT_ID, 'messages', 'msg2'),
        validMessage({ chatId: 'private_bob__carol' }),
      ),
    );
  });

  it('denies extra message fields', async () => {
    await assertFails(
      setDoc(doc(dbFor(ALICE), 'chats', CHAT_ID, 'messages', 'msg2'), {
        ...validMessage(),
        admin: true,
      }),
    );
  });

  it('denies empty message text', async () => {
    await assertFails(
      setDoc(
        doc(dbFor(ALICE), 'chats', CHAT_ID, 'messages', 'msg2'),
        validMessage({ text: '' }),
      ),
    );
  });

  it('denies a non-member sending into the chat', async () => {
    await assertFails(
      setDoc(
        doc(dbFor(ALICE), 'chats', 'private_bob__carol', 'messages', 'msg2'),
        validMessage({ chatId: 'private_bob__carol' }),
      ),
    );
  });

  it('lets a member mark a message read', async () => {
    await assertSucceeds(
      updateDoc(doc(dbFor(ALICE), 'chats', CHAT_ID, 'messages', 'msg1'), {
        isRead: true,
      }),
    );
  });

  it('denies rewriting message content', async () => {
    await assertFails(
      updateDoc(doc(dbFor(ALICE), 'chats', CHAT_ID, 'messages', 'msg1'), {
        text: 'rewritten',
      }),
    );
  });

  it('denies client message deletion', async () => {
    await assertFails(
      deleteDoc(doc(dbFor(ALICE), 'chats', CHAT_ID, 'messages', 'msg1')),
    );
  });

  it('lets a member list the conversation history', async () => {
    await assertSucceeds(
      getDocs(collection(dbFor(ALICE), 'chats', CHAT_ID, 'messages')),
    );
  });

  it('denies a non-member listing the conversation history', async () => {
    await assertFails(
      getDocs(
        collection(dbFor(ALICE), 'chats', 'private_bob__carol', 'messages'),
      ),
    );
  });
});

describe('publicProfiles', () => {
  it('lets a signed-in user read the public directory', async () => {
    await assertSucceeds(
      getDoc(doc(dbFor(BOB), 'publicProfiles', ALICE)),
    );
  });

  it('denies unauthenticated directory reads', async () => {
    await assertFails(getDoc(doc(anonDb(), 'publicProfiles', ALICE)));
  });

  it('denies broad directory listing', async () => {
    await assertFails(getDocs(collection(dbFor(BOB), 'publicProfiles')));
  });

  it('lets an owner create their public profile', async () => {
    await assertSucceeds(
      setDoc(doc(dbFor(CAROL), 'publicProfiles', CAROL), {
        uid: CAROL,
        username: 'carol',
        displayName: 'Carol',
        updatedAt: TS,
      }),
    );
  });

  it('denies writing another user\'s public profile', async () => {
    await assertFails(
      setDoc(doc(dbFor(BOB), 'publicProfiles', ALICE), {
        uid: ALICE,
        username: 'alice',
        displayName: 'Not Alice',
        updatedAt: TS,
      }),
    );
  });

  it('denies an invalid username', async () => {
    await assertFails(
      setDoc(doc(dbFor(CAROL), 'publicProfiles', CAROL), {
        uid: CAROL,
        username: 'Bad Name',
        displayName: 'Carol',
        updatedAt: TS,
      }),
    );
  });

  it('allows a display-name update that keeps the username', async () => {
    await assertSucceeds(
      setDoc(
        doc(dbFor(ALICE), 'publicProfiles', ALICE),
        {
          uid: ALICE,
          username: 'alice',
          displayName: 'Alice Updated',
          updatedAt: TS,
        },
        { merge: true },
      ),
    );
  });

  it('denies changing the username on an existing profile', async () => {
    await assertFails(
      updateDoc(doc(dbFor(ALICE), 'publicProfiles', ALICE), {
        username: 'alice2',
      }),
    );
  });

  it('denies deleting a public profile from a client', async () => {
    await assertFails(deleteDoc(doc(dbFor(ALICE), 'publicProfiles', ALICE)));
  });
});

describe('private users', () => {
  it('lets an owner read their private document', async () => {
    await assertSucceeds(getDoc(doc(dbFor(ALICE), 'users', ALICE)));
  });

  it('denies reading another user\'s private document', async () => {
    await assertFails(getDoc(doc(dbFor(BOB), 'users', ALICE)));
  });

  it('denies listing the users collection', async () => {
    await assertFails(getDocs(collection(dbFor(ALICE), 'users')));
  });

  it('lets an owner write their private document', async () => {
    await assertSucceeds(
      setDoc(
        doc(dbFor(ALICE), 'users', ALICE),
        { uid: ALICE, phoneNumber: '+10000000001' },
        { merge: true },
      ),
    );
  });

  it('denies writing another user\'s private document', async () => {
    await assertFails(
      setDoc(
        doc(dbFor(BOB), 'users', ALICE),
        { uid: ALICE, phoneNumber: '+19999999999' },
        { merge: true },
      ),
    );
  });

  it('denies client deletion of a private document', async () => {
    await assertFails(deleteDoc(doc(dbFor(ALICE), 'users', ALICE)));
  });
});

describe('username claims', () => {
  it('lets a user create their own username claim', async () => {
    await assertSucceeds(
      setDoc(doc(dbFor(CAROL), 'usernames', 'carol'), { uid: CAROL }),
    );
  });

  it('denies claiming a username for another account', async () => {
    await assertFails(
      setDoc(doc(dbFor(BOB), 'usernames', 'bob2'), { uid: ALICE }),
    );
  });

  it('denies listing usernames for enumeration', async () => {
    await assertFails(getDocs(collection(dbFor(ALICE), 'usernames')));
  });

  it('denies transferring an existing username to another account', async () => {
    await assertFails(
      updateDoc(doc(dbFor(ALICE), 'usernames', 'alice'), { uid: BOB }),
    );
  });

  it('allows an idempotent username claim rewrite', async () => {
    await assertSucceeds(
      setDoc(doc(dbFor(ALICE), 'usernames', 'alice'), { uid: ALICE }),
    );
  });

  it('denies moving a handle to another owner', async () => {
    await assertFails(
      updateDoc(doc(dbFor(ALICE), 'handles', 'alice'), { ownerId: BOB }),
    );
  });
});

describe('server-owned password reset data', () => {
  for (const collectionName of [
    'passwordResetCodes',
    'passwordResetTokens',
    'passwordResetThrottle',
  ]) {
    it(`denies client reads of ${collectionName}`, async () => {
      await assertFails(
        getDoc(doc(dbFor(ALICE), collectionName, 'entry')),
      );
    });

    it(`denies client writes of ${collectionName}`, async () => {
      await assertFails(
        setDoc(doc(dbFor(ALICE), collectionName, 'entry'), {
          code: '123456',
        }),
      );
    });
  }
});
