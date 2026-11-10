# DOCMAC Phase 2 Plan (Draft)

Status: **Draft for owner review.** Phase 0 is the launch-readiness work in
`PRODUCTION_RUNBOOK.md`. Phase 2 begins after the launch gates are closed and
covers the product and UI/UX work that turns a working 1:1 chat into a product
people can rely on.

Nothing in this plan authorises fake behaviour. Any surface without a real
backend keeps an honest unavailable/empty state and is labelled as preview-only
in non-release builds.

## 1. Objective

Ship a trustworthy, distinctive Docmac for the first 10,000 users:

- chat that is fast, honest, and reliable on bad networks;
- a UI/UX that can be built and reviewed without waiting for Firebase;
- real attachments and notifications;
- end-to-end encryption implemented behind a flag before it is claimed;
- a cost and operations model that survives 10k users on a solo-developer
  budget.

## 2. Principles

1. **Backend-free UI development.** Every screen must be buildable and
   reviewable in Design Lab with deterministic sample data.
2. **One source of truth per surface.** Preview fixtures and real repositories
   expose the same models; screens do not know which one is active.
3. **No fake success.** Send, delete, upload, and reset actions report what
   actually happened.
4. **Encryption is a property, not a label.** No E2EE copy until the gate in
   `E2EE_DESIGN.md` is met.
5. **Sequence over dates.** A solo developer ships one vertical slice at a
   time; each slice has an exit test.

## 3. Workstreams

### A. Launch unblock (must finish first)

| Item | Exit criteria |
| --- | --- |
| Blaze billing | Project on Blaze; Cloud Functions API enabled |
| Functions deploy | `ensureDirectChat`, `deleteAccount`, reset functions visible in `firebase functions:list` |
| Reset secrets | `RESET_OTP_PEPPER` and a valid `RESEND_API_KEY` set |
| Two-account chat | Two real accounts can start a chat, exchange messages, and see read state |
| Account deletion | Deleting one account removes membership/profile and leaves delivered messages for the peer |
| Play Store | Signed AAB uploaded; privacy/deletion URL, Data safety, content rating, target audience complete |

Owner action: add the payment method and provide the Resend key. Everything
else in this workstream is already automated or documented.

### B. Design Lab and UI/UX system

Goal: build the real UI/UX at full speed without a live backend.

- Backend-free boot (`DOCMAC_DESIGN_LAB=true`) that skips Firebase, bypasses
  the auth gate, and starts in the app shell.
- One fixture catalogue for people, threads, messages, moments, calls, and
  notifications. Reuse the existing `AppFeatureFlags` preview data; move
  duplicated sample lists into shared fixtures over time.
- State matrix for every major screen: loaded, empty, loading, offline, error,
  permission denied, and long-content.
- Golden/screenshot tests for the primary surfaces at phone and tablet widths.
- Accessibility pass: text scaling, contrast, semantics labels, tap targets,
  reduced motion.
- Motion pass: one consistent page/route transition and one message-entry
  animation; respect `MediaQuery.disableAnimations`.

Exit criteria: a new screen can be added, populated, and reviewed on an
emulator or Windows desktop with no Firebase project, no network, and no real
account.

### C. Chat quality

- Optimistic send with explicit `sending / sent / failed / retry` states.
- Offline queue with bounded retries and a visible pending state.
- Message pagination and a stable jump-to-latest.
- Read receipts and unread counts that match Firestore rules.
- Push notifications with no plaintext preview until E2EE decisions are made.
- Block/report and rate limits before public growth.
- Chat search remains local until encrypted search is designed.

Exit criteria: airplane-mode send, retry, and duplicate suppression pass on two
devices; no message is shown as sent before the server confirms it.

### D. Media and attachments

Requires Blaze (Cloud Storage is not on Spark).

- Photo, file, and voice-note upload with progress and cancel.
- Size/type limits and client-side compression.
- Attachment encryption design before E2EE ships.
- Storage lifecycle rules and per-user quotas.

Exit criteria: upload, download, retry, and delete-on-device behave correctly
on a slow network; storage cost per 1,000 messages is measured.

### E. End-to-end encryption

Follow `E2EE_DESIGN.md`; do not shortcut it.

1. Owner resolves the six open decisions (platform scope, history, backup,
   crypto implementation, metadata, review).
2. Implement device identity keys and prekey publication.
3. Implement X3DH + Double Ratchet with test vectors.
4. Add safety-number verification, key-change warnings, and tamper states.
5. Migrate or wipe plaintext history according to the decision.
6. Run an independent review; only then change UI copy.

Exit criteria: every new 1:1 message is an encrypted envelope, legacy/unknown
messages are labelled, and the security review gate is signed off.

### F. Groups, calls, and presence

- Group membership and permissions through Cloud Functions.
- Group encryption via sender keys or MLS; never reuse pairwise ratchets.
- Real WebRTC calls only when a media encryption design exists.
- Presence and typing indicators with explicit privacy controls.

### G. Scale and operations

- Budget alerts and a documented cost model at 1k / 10k / 100k users.
- Read amplification review: pagination, cached inbox, listener limits.
- Crashlytics triage and a release rollback runbook.
- Firestore backup/export and a tested restore.
- Support and abuse workflow that does not require reading plaintext.

## 4. Sequence

1. **M2.0 — Design Lab** (this change): backend-free boot, banner, fixtures,
   documentation. No production behaviour changes.
2. **M2.1 — Launch unblock:** Blaze, functions, secrets, two-device tests,
   Play upload.
3. **M2.2 — UI/UX beta:** state matrix, golden tests, accessibility, motion.
4. **M2.3 — Chat reliability:** offline queue, send states, pagination,
   notifications.
5. **M2.4 — Media:** encrypted attachment design, uploads, quotas.
6. **M2.5 — E2EE v1:** keys, ratchet, safety numbers, migration, review.
7. **M2.6 — Groups and calls:** membership, group encryption, WebRTC design.

Each milestone ends with a demo on a physical device and an updated runbook.

## 5. Success measures for 10k users

- Crash-free sessions ≥ 99.5%.
- p95 inbox open < 1 second on a mid-range Android phone.
- Successful send rate ≥ 99% excluding deliberate offline use.
- No message shown as sent before server acknowledgement.
- Monthly Firebase cost tracked per 1,000 MAU; SMS cost tracked separately.
- D1/D7 retention and chat-start completion measured from real events only.

## 6. Explicit non-goals

- Rewriting Firestore to SQL for Phase 2.
- Server-side message search while messages are plaintext-free.
- Claiming E2EE, calls, or media before their gates pass.
- Group encryption by reusing the 1:1 ratchet.
- Adding social feeds or fabricated activity to fill empty screens.

## 7. Open decisions for the owner

1. Is Android the only Phase 2 platform, or must iOS ship at the same time?
2. Wipe pre-launch plaintext chat history, or retain it with a clear legacy
   label?
3. Is there a passphrase-protected key backup, or does a new device lose
   history?
4. Which crypto implementation passes review: `cryptography` + custom ratchet,
   a ported Signal library, or Olm FFI?
5. Are media attachments in Phase 2 before E2EE, or after it?
6. What is the monthly Firebase/SMS budget ceiling that should trigger a
   feature freeze?
