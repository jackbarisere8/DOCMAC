import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Describes whether this build contains usable Firebase credentials.
///
/// The generated `firebase_options.dart` file in a new project contains
/// placeholders until `flutterfire configure` has been run.
class FirebaseConfiguration {
  FirebaseConfiguration._();

  static bool get isConfigured {
    final options = DefaultFirebaseOptions.currentPlatform;
    return !_isPlaceholder(options.apiKey) &&
        !_isPlaceholder(options.appId) &&
        !_isPlaceholder(options.projectId);
  }

  static bool get isInitialized => Firebase.apps.isNotEmpty;

  static bool get isAvailable => isConfigured && isInitialized;

  static bool _isPlaceholder(String value) =>
      value.isEmpty || value.startsWith('YOUR_');
}
