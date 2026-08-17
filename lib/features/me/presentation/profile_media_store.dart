
import 'package:flutter/foundation.dart';

/// Keeps locally selected profile media available while the app is running.
class ProfileMediaStore {
  ProfileMediaStore._();

  static final avatarBytes = ValueNotifier<Uint8List?>(null);
  static final coverBytes = ValueNotifier<Uint8List?>(null);
}
