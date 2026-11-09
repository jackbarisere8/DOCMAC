import 'package:docmac_app/core/theme/app_colors.dart';
import 'package:docmac_app/core/theme/dark_theme.dart';
import 'package:docmac_app/core/theme/light_theme.dart';
import 'package:docmac_app/features/orbit/presentation/pages/orbit_page.dart';
import 'package:docmac_app/shared/widgets/app_shell.dart';
import 'package:docmac_app/shared/widgets/docmac_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('Home page scrolling, static search box, and rollable hubs', () {
    testWidgets(
        'search box is in a static header above CustomScrollView with reduced 7 hubs badge',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: OrbitPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search box exists in the static header area
      expect(find.byType(DocmacSearchBar), findsOneWidget);

      // "7 hubs" badge exists and has reduced typography/size
      expect(find.text('7 hubs'), findsOneWidget);
      final badgeText = tester.widget<Text>(find.text('7 hubs'));
      expect(badgeText.style?.fontSize, 11);

      // Verify horizontal scroll view is used for chips (rollable to the left)
      final horizontalScroll = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      );
      expect(horizontalScroll, findsOneWidget);

      // Chips are inside the horizontal scrollable
      expect(
        find.descendant(
          of: horizontalScroll,
          matching: find.text('All'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: horizontalScroll,
          matching: find.text('Pulse'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: horizontalScroll,
          matching: find.text('Orbit'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: horizontalScroll,
          matching: find.text('Moments'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: horizontalScroll,
          matching: find.text('Forge'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: horizontalScroll,
          matching: find.text('Relays'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: horizontalScroll,
          matching: find.text('Spaces'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'scrolling down collapses the area up from search box while search box stays static',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: OrbitPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchBarFinder = find.byType(DocmacSearchBar);
      expect(searchBarFinder, findsOneWidget);
      final initialWordmark = find.text('DocMac');
      expect(initialWordmark, findsOneWidget);

      // Drag the scrollable feed downwards (swiping up)
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The search bar is still visible and pinned/static at the top
      expect(searchBarFinder, findsOneWidget);

      // Wait for pause/stop debounce (360ms)
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Once user pauses or stops scrolling, the top bar appears back
      expect(find.text('DocMac'), findsOneWidget);
    });
  });

  group('Icon theme and color scheme monochrome compliance', () {
    testWidgets('light theme sets iconTheme to dark text color',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final iconTheme = IconTheme.of(capturedContext);
      expect(iconTheme.color, AppColors.lightTextPrimary);
    });

    testWidgets('dark theme sets iconTheme to white text color',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final iconTheme = IconTheme.of(capturedContext);
      expect(iconTheme.color, AppColors.darkTextPrimary);
    });
  });

  group('Bottom navigation static shell navigation', () {
    testWidgets(
        'switching tabs with StatefulShellRoute keeps navigation bar stationary',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/orbit',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                AppShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/orbit',
                    pageBuilder: (_, __) => const NoTransitionPage(
                      child: Text('Orbit Content'),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/talk',
                    pageBuilder: (_, __) => const NoTransitionPage(
                      child: Text('Talk Content'),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/live',
                    pageBuilder: (_, __) => const NoTransitionPage(
                      child: Text('Live Content'),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/me',
                    pageBuilder: (_, __) => const NoTransitionPage(
                      child: Text('Me Content'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final talkNav = find.byKey(const ValueKey('app-nav-talk'));
      final initialPosition = tester.getTopLeft(talkNav);

      // Verify we are on Orbit
      expect(find.text('Orbit Content'), findsOneWidget);

      // Tap Talk tab
      await tester.tap(talkNav);
      await tester.pumpAndSettle();

      // Only the page content changed to Talk
      expect(find.text('Talk Content'), findsOneWidget);
      expect(find.text('Orbit Content'), findsNothing);

      // The navigation bar remained exactly at the static position without turning or translating
      expect(tester.getTopLeft(talkNav), initialPosition);
    });
  });
}
