# Docmac App

## Phone authentication setup

Enable both **Phone** and **Email/Password** in Firebase Authentication. For
Android phone sign-in, add the SHA-1 and SHA-256 fingerprints for every debug
and release signing key, then download the updated
`android/app/google-services.json` before building.

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

## Next steps

1. Install Flutter SDK and run `flutter pub get`.
2. Configure Firebase with `flutterfire configure`, which replaces the
   placeholder values in `lib/firebase_options.dart` and adds the platform
   configuration files. This is required before account creation or password
   reset can work.
3. In the Firebase console, go to **Authentication → Sign-in method** and
   enable **Email/Password**. Also add an authorized domain when running on
   the web.
