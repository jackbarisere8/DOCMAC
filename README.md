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

## Next steps

1. Install Flutter SDK and run `flutter pub get`.
2. Configure Firebase with `flutterfire configure`, which replaces the
   placeholder values in `lib/firebase_options.dart` and adds the platform
   configuration files. This is required before phone account creation can
   work.
3. In the Firebase console, go to **Authentication → Sign-in method** and
   enable **Phone**. Add the Android SHA-1 and SHA-256 fingerprints for each
   signing key before testing SMS verification.
