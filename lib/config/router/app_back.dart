import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Returns to the actual previous route when it exists.
///
/// A feature can also be opened from a notification, deep link, or a rebuilt
/// tab shell, where there is no route to pop. In that case, go to that
/// feature's parent instead of letting navigation fall back to the app home.
class AppBack {
  const AppBack._();

  static void to(BuildContext context, {required String fallback}) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go(fallback);
  }
}
