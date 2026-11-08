# Docmac App

## Phone authentication setup

Enable the **Phone** provider in Firebase Authentication. For Android phone
sign-in, add the SHA-1 and SHA-256 fingerprints for every debug and release
signing key, then download the updated `android/app/google-services.json`
before building. A completed phone session is restored until the person signs
out.

A starter Flutter project scaffold organized for:

- auth
- chat
- calls
- contacts
- profile
- settings

## Structure

- lib/core
- lib/config
- lib/features
- lib/shared

## Production operations

See [docs/PRODUCTION_RUNBOOK.md](docs/PRODUCTION_RUNBOOK.md) for the deployment
order, Firebase Console setup (API-key restrictions, SHA fingerprints, App
Check, Crashlytics), release channels, rollback, and the end-to-end encryption
gate. The draft E2EE protocol and migration plan is
[docs/E2EE_DESIGN.md](docs/E2EE_DESIGN.md); it is a proposal awaiting review,
not a shipped feature.

Real 1:1 chat, inboxes, and account deletion require the server code in
`functions/` plus `firestore.rules` and `firestore.indexes.json` to be
deployed. Clients cannot create chat documents; the `ensureDirectChat`
callable does it.

Local checks before shipping:

```bash
flutter analyze
flutter test
cd functions && npm test && npm run check
cd rules-test && npm ci && npm test   # needs Java 21+ and Firebase CLI
```

`rules-test/` runs the Firestore emulator against `firestore.rules` and checks
chat membership, message writes, public/private profiles, username claims, and
server-owned password-reset data. The `rules` job in CI installs Java 21,
Node 20, and the Firebase CLI so it runs on every push.

## Next steps

1. Install Flutter SDK and run `flutter pub get`.
2. Configure Firebase with `flutterfire configure`, which replaces the
   placeholder values in `lib/firebase_options.dart` and adds the platform
   configuration files. This is required before phone account creation can
   work.
3. In the Firebase console, go to **Authentication → Sign-in method** and
   enable **Phone**. Add the Android SHA-1 and SHA-256 fingerprints for each
   signing key before testing SMS verification.
4. Deploy functions, rules, and indexes, then complete the two-account device
   test in the runbook.
