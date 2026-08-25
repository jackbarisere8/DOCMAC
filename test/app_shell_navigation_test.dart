import 'package:docmac_app/shared/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
      'swiping changes the active tab while the navigation bar stays fixed',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/talk',
      routes: [
        GoRoute(path: '/talk', builder: (_, __) => _testShell()),
        GoRoute(path: '/live', builder: (_, __) => _testShell()),
        GoRoute(path: '/me', builder: (_, __) => _testShell()),
        GoRoute(path: '/orbit', builder: (_, __) => _testShell()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final navigationBar = find.byKey(const ValueKey('app-nav-talk'));
    final initialPosition = tester.getTopLeft(navigationBar);

    await tester.drag(find.byType(PageView), const Offset(-800, 0));
    await tester.pumpAndSettle();

    final liveNavigation = tester.widget<Semantics>(
      find.byKey(const ValueKey('app-nav-live')),
    );
    expect(liveNavigation.properties.selected, isTrue);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('app-nav-talk'))),
      initialPosition,
    );
  });
}

AppShell _testShell() => AppShell(
      pages: const [
        ColoredBox(color: Colors.red),
        ColoredBox(color: Colors.green),
        ColoredBox(color: Colors.blue),
        ColoredBox(color: Colors.orange),
      ],
    );
