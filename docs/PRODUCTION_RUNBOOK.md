# DOCMAC Production Runbook

This is the Phase 0 operating guide for shipping Docmac to real people. It
separates what the app actually does today from work that still needs a
console, a deployment, or a dedicated design phase.

## What ships today

| Surface | State | Notes |
| --- | --- | --- |
| Sign-in | Shipped | Firebase Auth: phone OTP and email/password. |
| 1:1 text chat | Shipped, server-deploy required | Chats are created only by the `ensureDirectChat` callable. |
| Talk inbox | Shipped | Streams Firestore chats where the uid is a participant. |
| Account deletion | Shipped, server-deploy required | `deleteAccount` callable removes profile data, membership, and the Auth user. |
| Crash reporting | Wired | Crashlytics collects in profile/release builds only. |
| Product analytics | Wired | Firebase Analytics collection is enabled in profile/release builds. |
| Direct APK | CI ready | `.github/workflows/release-apk.yml` builds and publishes a signed APK. |
| Play Store bundle | CI ready | The same workflow builds and uploads an AAB artifact for Play Console. |
| End-to-end encryption | **Not shipped** | Do not describe messages or calls as E2EE. See the gate below. |
| Voice/video calls | Simulated UI | No audio leaves the device. |
| Media/uploads | Not shipped | Chat sends text only; UI labels must stay honest. |
| Payments | Not shipped | No premium surface exists in this build. |

## Deploy order

The project must be on the Blaze (pay-as-you-go) plan before functions can be
deployed, and the **Cloud Functions API** must be enabled. A `firebase
functions:list` call currently fails with `SERVICE_DISABLED` until it is. Enable
it from <https://console.developers.google.com/apis/api/cloudfunctions.googleapis.com/overview?project=docmac-88a0d>
and retry after a few minutes. The first deploy also needs Cloud Build, Cloud
Run, Artifact Registry, and Secret Manager; the CLI prompts to enable them.

Run these from the repository root after reviewing the diff:

```bash
firebase use docmac-88a0d
firebase functions:secrets:set RESET_OTP_PEPPER
firebase functions:secrets:set RESEND_API_KEY
firebase deploy --only functions,firestore:rules,firestore:indexes
```

Generate the pepper as at least 32 random bytes, for example
`openssl rand -hex 32` or, in PowerShell, `$bytes = New-Object byte[] 32;
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes);
-join ($bytes | ForEach-Object { $_.ToString('x2') })`.
Store it only in the secret manager; changing it invalidates outstanding reset
codes. `RESEND_API_KEY` comes from Resend. The default sender is
`Docmac <no-reply@docmac.app>`; verify that domain in Resend before relying on
email reset, or change the default in `functions/index.js` to another verified
sender. Without a valid mail key the app reports that a code was sent but no
email is delivered, which is why delivery must be tested before launch.

`ensureDirectChat` and `deleteAccount` must be deployed before two-account chat
or account deletion can work. Rules deny client chat creation, so an APK built
against undeployed functions will report that it cannot start a talk.

Verify what was deployed:

```bash
firebase functions:list
firebase firestore:indexes
```

The chat inbox query needs the composite index in `firestore.indexes.json`
(`participantIds` contains + `updatedAt` descending). Deploy the indexes before
the first signed-in launch, otherwise the inbox stream fails.

## Security rules tests

`rules-test/` runs the Firestore emulator with the real `firestore.rules` and
asserts the security boundaries chat and account deletion depend on:

- members and legacy participants can read their chat; outsiders cannot;
- clients cannot create or delete chats, rewrite membership, or spoof senders;
- messages are append-only and bound to the chat path;
- public profiles are exact-read only for signed-in users, owner-written, and
  cannot be listed in bulk;
- `users/{uid}` is owner-only;
- username claims cannot be transferred, listed in bulk, or deleted; a single
  handle remains publicly checkable so onboarding can show availability;
- password-reset collections are server-only.

Run locally with Java 21+ and the Firebase CLI:

```bash
cd rules-test
npm ci
npm test
```

CI runs the same command in the `rules` job. The emulator is project
`demo-docmac-rules`; it makes no network calls to production.

## Firebase Console tasks

### Authentication

1. Enable **Phone** and **Email/Password** providers.
2. Add every debug and release keystore SHA-1 and SHA-256 under
   **Project settings → Your apps → Android**.
3. Re-download `android/app/google-services.json` after changing fingerprints.
4. Add the production domain to **Authentication → Settings → Authorized
   domains** if web sign-in is enabled.
5. Configure the password-reset email template if email accounts are enabled.

### API key restrictions

The Android API key must stay usable by Firebase SDKs. In **Google Cloud
Console → APIs & Services → Credentials**, edit the Android key and:

- Restrict it to Android apps with package `com.jack.docmac` and the registered
  SHA-1/SHA-256 fingerprints.
- Restrict API access to the APIs the SDKs call: Identity Toolkit,
  Cloud Firestore, Firebase Installations, Firebase App Check, and Token
  Service. Do not add APIs that are not used.
- Keep a separate unrestricted browser key only if the web build needs it.

Test sign-in, chat, and account deletion after restricting the key; API key
mistakes usually surface as `auth/api-key-not-valid` or Firestore
`PERMISSION_DENIED` responses.

### App Check

**App Check is not wired into this build. Do not enable enforcement yet.**
Enforcing it while the app has no App Check provider would block every
Firestore and Functions request.

Before enforcement:

1. Add `firebase_app_check` and activate Play Integrity for release builds and
   the debug provider for debug builds.
2. Register the debug token in the console and keep it out of source control.
3. Monitor App Check metrics for at least a week before enforcing.
4. Enforce App Check for Cloud Functions and Firestore only after the release
   APK and Play build both pass on physical devices.
5. Test the sideloaded APK separately. Play Integrity behavior for apps
   installed outside Play must be verified on a physical device before
   enforcing; do not assume emulator results apply.

### Crashlytics and Analytics

1. Open a release build on a physical device and confirm the app appears under
   **Crashlytics**.
2. Force a test crash and confirm it is grouped correctly, then disable the
   test crash code.
3. Enable Crashlytics alerts (new fatal issue, regression, velocity).
4. Confirm Analytics debug view receives events. The app enables collection in
   profile/release builds only; debug builds intentionally stay silent.
5. Set data retention and sharing settings to match the privacy policy.

### Budgets and quotas

Create a Google Cloud budget alert for the production project. For 10,000
users, watch Firestore reads, Cloud Functions invocations, Auth SMS volume, and
Crashlytics event volume. Set a daily budget alert at a low threshold so a
viral loop or retry bug does not silently run up cost.

## Environment separation

Production and staging must not share a Firebase project. Before the first
public release:

1. Create `docmac-staging` (or reuse a dedicated dev project) and keep
   `docmac-88a0d` as production.
2. Run `flutterfire configure` per environment and commit neither
   `google-services.json` secrets nor service-account keys.
3. Use `firebase use` or `.firebaserc` aliases per shell before deploying.
4. Point the staging build at staging functions with
   `--dart-define=DOCMAC_ENV=staging` only after the app reads that flag.
5. Keep staging and production signing keys separate; register both
   fingerprints in their respective projects.

## Release signing setup

The release workflow refuses to build without a keystore. Create the upload
key once and store it outside the repository; losing it prevents future
updates, although Google Play App Signing keeps the app signing key if the
upload key is reset.

```powershell
keytool -genkeypair -v -keystore docmac-upload.jks -alias docmac-upload `
  -keyalg RSA -keysize 4096 -validity 10000
```

Create `android/key.properties` locally for device builds (it is gitignored;
`android/key.properties.example` shows the shape):

```properties
storePassword=<store password>
keyPassword=<key password>
keyAlias=docmac-upload
storeFile=C:\path\to\docmac-upload.jks
```

Create the GitHub `production` environment before the first release: open the
repository's **Settings → Environments → New environment**, name it
`production`, and add required reviewers if releases should wait for manual
approval. The release job reads environment secrets, not repository secrets;
without this environment and the four signing secrets below, the workflow
stops at “Restore signing keystore”.

Add the following secrets to the GitHub `production` environment:

| Secret | Value |
| --- | --- |
| `KEYSTORE_BASE64` | `[Convert]::ToBase64String([IO.File]::ReadAllBytes("docmac-upload.jks"))` |
| `KEYSTORE_PASSWORD` | The `storePassword` above. |
| `KEY_ALIAS` | `docmac-upload` |
| `KEY_PASSWORD` | The `keyPassword` above. |

On macOS/Linux, encode the keystore with `base64 -w0 docmac-upload.jks` (or
`base64 docmac-upload.jks | tr -d '\n'`). `WEBSITE_SYNC_TOKEN` is optional; without
it the website picks the release up on its next scheduled sync.

Register the upload key fingerprints with Firebase and Google Cloud:

```bash
keytool -list -v -keystore docmac-upload.jks -alias docmac-upload
```

## Release channels

### Direct APK

Trigger **Release APK** with `versionName`, `versionCode`, channel, and notes.
The workflow fails if release signing secrets are missing, builds the APK,
builds the AAB, verifies both artifacts, and publishes the APK to GitHub
Releases.

### Play Store

1. Download the `docmac-<version>-aab` workflow artifact.
2. Upload it in Play Console to the appropriate track (internal → closed →
   production).
3. Use Play App Signing. The CI keystore is the upload key; Google holds the
   app signing key.
4. Publish a privacy policy URL and complete Data safety, content rating, and
   target-audience declarations. Account for Firebase Auth (email/phone),
   Firestore messages and profiles, Crashlytics diagnostics, and Analytics
   events. Messages are transported over TLS but are **not** end-to-end
   encrypted; the Data safety form must not claim otherwise.
5. Provide the public account-deletion URL required by Google Play in addition
   to the in-app path (**Me → Settings → Account → Delete account**). The page
   must explain what deletion removes, what is retained for other participants,
   and how to request deletion by email.
6. Complete the account-deletion declaration in Play Console with the same URL.
7. The AAB is not published to GitHub Releases; only the APK is.

## End-to-end encryption gate

E2EE is a product requirement but not an implemented feature. Do not enable
copy that says messages, calls, media, or backups are encrypted end-to-end.
The draft protocol, data-model, migration, and review plan is in
[docs/E2EE_DESIGN.md](E2EE_DESIGN.md). It is a proposal awaiting review, not a
shipped design.

Before E2EE can ship, complete a design review covering:

- Per-device identity keys and authenticated prekey bundles.
- X3DH-style session setup and a Double Ratchet message layer.
- Multi-device enrolment, device revocation, and key backup/recovery.
- Safety-number verification and key-change warnings.
- Migration of existing plaintext Firestore history.
- Attachment encryption and key management.
- Call media encryption (insertable streams/WebRTC) once calling is real.
- Metadata limits: Firestore still sees participants, timestamps, and routing.
- Server-side abuse reporting that does not silently break the E2EE promise.

Until that ships, `SecurityNotificationsPage`, privacy help, and marketing copy
must describe the controls that actually exist: Firebase Authentication and
Firestore rules restrict conversation documents to members, and the service
operator can access stored content for maintenance.

## Demo content

Debug and profile builds use sample conversations, people, moments, and
activity to exercise unfinished surfaces. Release builds show honest empty
states instead. The two preview switches can be set explicitly in a non-release
build for screenshots or design review:

```bash
flutter run \
  --dart-define=DOCMAC_SIGNED_OUT_PREVIEWS=true \
  --dart-define=DOCMAC_LOCAL_PREVIEWS=true
```

Release builds always compile this sample content out, so no store build can
present fabricated people as real accounts.

## Verification checklist

Before publishing:

```bash
flutter analyze
flutter test
cd functions && npm test && npm run check
cd rules-test && npm test
```

The `rules` CI job runs the Firestore rules suite automatically, so a red
`Firestore rules test` check blocks a merge.

Two-account device test:

1. Create account A and account B on two devices.
2. Start a talk from A using B's `@username`.
3. Send messages both ways; confirm the same chat appears in both inboxes.
4. Mark messages read; confirm the badge clears.
5. Delete account B; confirm A keeps delivered history and B can no longer
   sign in.
6. Sign in as A and confirm the deleted account is no longer listed as a chat
   participant.

## Rollback

- Re-deploy the previous functions revision with
  `firebase deploy --only functions` from the last known-good tag.
- Rules and indexes are versioned in git; redeploy from the previous tag.
- Halt the Play rollout in Play Console rather than shipping a second bad
  build.
- If Crashlytics shows a fatal regression tied to a new release, publish a
  hotfix APK and use Play staged rollout controls.
