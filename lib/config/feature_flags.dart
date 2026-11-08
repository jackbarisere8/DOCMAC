import 'package:flutter/foundation.dart';

/// Build-time switches for demo-only or unfinished surfaces.
///
/// Use `--dart-define=DOCMAC_SIGNED_OUT_PREVIEWS=true` to force sample
/// conversations into a signed-out build (for screenshots or design review).
/// Release builds default to off so store builds never present fabricated
/// people as real accounts.
class AppFeatureFlags {
  AppFeatureFlags._();

  static bool get signedOutPreviews =>
      !kReleaseMode &&
      const bool.fromEnvironment(
        'DOCMAC_SIGNED_OUT_PREVIEWS',
        defaultValue: true,
      );

  /// Sample people, moments, and activity used to exercise unfinished
  /// surfaces in debug builds. Release builds show honest empty states so
  /// store builds never present fabricated accounts as real people.
  ///
  /// Use `--dart-define=DOCMAC_LOCAL_PREVIEWS=true` to force sample content
  /// into a debug build for screenshots or design review.
  static bool get localPreviews =>
      !kReleaseMode &&
      const bool.fromEnvironment(
        'DOCMAC_LOCAL_PREVIEWS',
        defaultValue: true,
      );
}
