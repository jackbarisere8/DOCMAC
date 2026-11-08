# DOCMAC End-to-End Encryption Design (Draft for review)

Status: **Proposal. Not implemented. Not reviewed.**
Nothing in this document is a shipped security property. The current app stores
chat text as plaintext in Firestore, and the service operator can read it. All
UI copy must keep saying so until this design is built, tested, and reviewed.

## 1. Scope and threat model

### Must protect

- Message text and attachments from:
  - a network attacker;
  - a compromised or curious Firestore/Cloud Functions operator;
  - another account that guesses or obtains a chat document path.
- Message integrity: a tampered ciphertext or replayed message must be rejected
  or visibly flagged.
- Post-compromise recovery for new messages after a device is compromised and
  revoked (via ratchet advancement and device revocation).

### Explicitly not protected

- Metadata visible to Firestore: participant UIDs, message timestamps, sender
  UID, message sizes, read state, chat existence, and activity patterns.
- A compromised unlocked device, a malicious keyboard, screenshots, or a user
  who verifies the wrong safety number.
- Availability: a server can always refuse to deliver messages.
- Historical plaintext written before E2EE ships.

The privacy policy and in-app copy must describe this metadata boundary.

## 2. Protocol choice

Use the Signal protocol shape for 1:1 chats:

1. **X3DH** to establish a shared secret from public prekey bundles.
2. **Double Ratchet** with DH ratchet, symmetric ratchet, skipped-message keys,
   and per-message AES-256-GCM (or ChaCha20-Poly1305) encryption.
3. **Safety numbers** derived from both identity keys, shown for out-of-band
   verification.

Do not invent a protocol. Do not call a static ECDH + AES scheme "end-to-end
encrypted" without forward secrecy and post-compromise recovery.

### Implementation options (to be decided before coding)

| Option | Pros | Risks |
| --- | --- | --- |
| `cryptography` + `cryptography_flutter` primitives, custom ratchet | Maintained Dart packages, platform acceleration, full control | We own the ratchet implementation and its audit |
| Port of `libsignal_protocol_dart` | Complete protocol code | Unofficial port; maintenance and audit status uncertain |
| Olm/vodozemac FFI | Audited protocol | FFI build complexity, binary size, platform coverage |
| Server-assisted MLS | Future group support | Overkill for 1:1, more moving parts |

Recommendation: X25519 + Ed25519 + HKDF + AES-256-GCM from `cryptography`, with
a small, heavily tested ratchet implementation, unless a maintained audited
Dart/FFI library passes review first. Whichever option is chosen, treat the
ratchet as security-critical code with published test vectors.

## 3. Device and key model

- Each installation gets a random 32-byte **device id**.
- Each device generates:
  - an Ed25519 **identity signing key**;
  - an X25519 **identity DH key**;
  - a signed X25519 **prekey** (rotated periodically);
  - a batch of one-time X25519 **prekeys**.
- Private keys never leave the device unencrypted. Store them with
  `flutter_secure_storage` backed by Android Keystore /
  EncryptedSharedPreferences. Document that rooted or debugged devices weaken
  this guarantee.
- Public bundles live in `deviceKeys/{uid}/devices/{deviceId}`:
  - `identitySigningKey`, `identityDhKey`, `signedPrekey`,
    `signedPrekeySignature`, `oneTimePrekeyIds`, `updatedAt`.
- One-time prekeys are claimed **atomically by a Cloud Function** so two
  senders cannot receive the same key. The function deletes or marks the
  claimed key in the same transaction.
- Rules:
  - owner may create/update/delete their own device documents;
  - any signed-in user may read a single device document for session setup;
  - no collection listing;
  - one-time prekey consumption happens only through the callable.

Multi-device: a user's own other devices are separate sessions. Sending a
message encrypts a copy per recipient device. Device revocation removes the
bundle and the sender stops encrypting to it on the next send.

## 4. Message format and Firestore changes

Current `chats/{chatId}/messages/{messageId}` is plaintext. Add a versioned
envelope and stop writing `text` for encrypted messages:

```text
{
  id, chatId, senderId, createdAt, isRead,
  encryption: "e2ee-v1",
  senderDeviceId: "...",
  ciphertext: "<base64>",
  header: {
    ratchetKey, previousChainLength, messageNumber,
    iv, ephemeralKey?, signedPrekeyId?, oneTimePrekeyId?
  }
}
```

Rules must require exactly one representation:

- legacy plaintext: current `text` field, only for messages created before the
  cutover (or removed entirely at cutover);
- encrypted: `encryption == "e2ee-v1"` plus validated ciphertext/header shapes;
- reject documents that mix plaintext and ciphertext fields.

Chat preview: do not write plaintext `lastMessage`. Use `"New message"` (or a
generic sender label) for encrypted chats until the client decrypts on open.
Unread counts remain server-visible.

Attachments (later): encrypt file bytes with a random content key, upload
ciphertext to Storage, and send the content key only inside the E2EE envelope.
Do not put media keys in Firestore plaintext.

## 5. Session lifecycle

1. Sender fetches the recipient device bundle and claims a one-time prekey.
2. Sender runs X3DH, sends an initial message with the prekey reference.
3. Both sides derive the root key and run the Double Ratchet.
4. Out-of-order messages use skipped message keys with a bounded window.
5. Ratchet state is persisted atomically after every send/receive so a crash
   cannot reuse a message key.
6. On identity-key change, block sending until the user reviews and re-verifies
   the safety number.
7. On device revocation, delete the bundle, rotate the sender's sessions, and
   tell contacts that the device was removed.

## 6. Migration and launch gates

The current Firestore history is plaintext. Choose one before rollout:

- **Pre-launch wipe (recommended while there are no real users):** delete
  existing chat history and start encrypted-only. No misleading "encrypted"
  label on old plaintext.
- **Keep history:** label legacy messages as "Stored before encryption", never
  claim they are E2EE, and give users a way to clear them.

E2EE may be described as shipped only when all of these are true:

- every new 1:1 message is written as an encrypted envelope; no plaintext text
  field is written by any client path;
- the client refuses to display "Encrypted" for legacy or undecryptable
  messages;
- safety-number verification is available;
- key-change and tamper warnings are tested;
- ratchet tests include published vectors, out-of-order delivery, replay,
  skipped-key exhaustion, and crash recovery;
- an independent security review has been completed, or the copy explicitly
  avoids claiming more than an internal review supports.

## 7. Calls, groups, and future surfaces

- Calls are currently simulated on-device. When real calling ships, media E2EE
  is a separate WebRTC design (insertable streams or a DTLS-SRTP review) and is
  not covered by message E2EE.
- Group chats need sender keys or MLS; do not reuse 1:1 pairwise encryption for
  groups without a design review.
- Server-side search, server-side notifications with message previews, and
  server-side abuse reporting all conflict with plaintext-free storage. Each
  needs an explicit product decision.
- Account deletion must destroy local key material on the deleted device and
  remove published bundles. Recipients keep already-delivered plaintext and
  session state; that is unavoidable.

## 8. Open decisions for the owner

1. Android-only E2EE first, or Android + iOS before any claim?
2. Accept no key backup (new device cannot read history), or build a
   passphrase-protected encrypted backup?
3. Wipe pre-launch plaintext history, or label and retain it?
4. Which crypto implementation passes review: custom ratchet on `cryptography`,
   a ported Signal library, or Olm FFI?
5. Is metadata minimization (padding, reduced read receipts) in scope for v1?
6. Who performs the independent review, and what is the budget/timeline?

Until these are answered and the gates in section 6 pass, Docmac messages are
**not end-to-end encrypted**.
