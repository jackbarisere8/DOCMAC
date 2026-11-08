import 'package:docmac_app/features/connections/data/connections_controller.dart';
import 'package:docmac_app/features/connections/presentation/pages/connections_page.dart';
import 'package:docmac_app/features/me/presentation/pages/me_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void _useMobileCanvas(WidgetTester tester, {double height = 1000}) {
  tester.view.physicalSize = Size(430, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

ThemeData _theme() => ThemeData(useMaterial3: true);

Future<void> _pumpConnections(WidgetTester tester) async {
  _useMobileCanvas(tester);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: _theme(),
        home: const ConnectionsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpProfile(WidgetTester tester) async {
  _useMobileCanvas(tester, height: 1300);
  final router = GoRouter(
    initialLocation: '/me',
    routes: [
      GoRoute(
        path: '/me',
        builder: (_, __) => const Scaffold(body: MePage()),
      ),
      GoRoute(
        path: '/connections',
        builder: (context, state) => ConnectionsPage(
          initialTab: state.uri.queryParameters['tab'] == 'contacts'
              ? ConnectionTab.contacts
              : ConnectionTab.followers,
          initialFollowerFilter: switch (state.uri.queryParameters['filter']) {
            'following' => FollowerFilter.following,
            'requests' => FollowerFilter.requests,
            _ => FollowerFilter.followers,
          },
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: _theme(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ConnectionsController', () {
    test('seeds separate social and address-book circles', () {
      final controller = ConnectionsController.seeded();
      addTearDown(controller.dispose);

      final state = controller.value;
      expect(state.followerCount, 12);
      expect(state.followingCount, 8);
      expect(state.requestCount, 2);
      expect(state.contactCount, 11);
      expect(state.onDocmacContactCount, 8);
      expect(state.inviteContacts.length, 3);

      expect(state.followerById('amara')?.isContact, isTrue);
      expect(state.followerById('noahk')?.isContact, isFalse);
      expect(state.contactById('ngozi')?.isOnDocmac, isFalse);
    });

    test('accepting a request makes the relationship mutual', () {
      final controller = ConnectionsController.seeded();
      addTearDown(controller.dispose);
      final before = controller.value;

      controller.acceptRequest('ifeomao');

      final state = controller.value;
      expect(state.requestCount, before.requestCount - 1);
      expect(state.followerCount, before.followerCount + 1);
      expect(state.followingCount, before.followingCount + 1);
      expect(
        state.requests.where((person) => person.id == 'ifeomao'),
        isEmpty,
      );

      final accepted = state.followerById('ifeomao');
      expect(accepted, isNotNull);
      expect(accepted!.followsYou, isTrue);
      expect(accepted.youFollow, isTrue);
      expect(state.followingById('ifeomao'), isNotNull);
    });

    test('ignoring a request never changes followers or following', () {
      final controller = ConnectionsController.seeded();
      addTearDown(controller.dispose);
      final before = controller.value;

      controller.ignoreRequest('bashirl');

      final state = controller.value;
      expect(state.requestCount, before.requestCount - 1);
      expect(state.followerCount, before.followerCount);
      expect(state.followingCount, before.followingCount);
      expect(
        state.requests.where((person) => person.id == 'bashirl'),
        isEmpty,
      );
    });

    test('follow toggling keeps follower cards and following list in sync', () {
      final controller = ConnectionsController.seeded();
      addTearDown(controller.dispose);

      expect(controller.value.followingById('noraw'), isNull);
      final nora = controller.value.followerById('noraw')!;
      expect(nora.youFollow, isFalse);

      controller.toggleFollow(nora);

      expect(controller.value.followingById('noraw'), isNotNull);
      expect(controller.value.followerById('noraw')?.youFollow, isTrue);

      controller.toggleFollow(controller.value.followerById('noraw')!);

      expect(controller.value.followingById('noraw'), isNull);
      expect(controller.value.followerById('noraw')?.youFollow, isFalse);
    });

    test('inviting a contact records the invite without making them chatty',
        () {
      final controller = ConnectionsController.seeded();
      addTearDown(controller.dispose);

      expect(controller.value.contactById('ngozi')?.invited, isFalse);

      controller.inviteContact('ngozi');

      final invited = controller.value.contactById('ngozi');
      expect(invited?.invited, isTrue);
      expect(invited?.isOnDocmac, isFalse);
      expect(
        controller.value.onDocmacContacts.where(
          (contact) => contact.id == 'ngozi',
        ),
        isEmpty,
      );
    });
  });

  group('ConnectionsPage', () {
    testWidgets('keeps connections social and contacts talk-ready',
        (tester) async {
      await _pumpConnections(tester);

      expect(find.text('Linked to you'), findsOneWidget);
      expect(
        find.text('Social only. Talk needs a saved contact.'),
        findsOneWidget,
      );
      expect(find.text('Your address book'), findsNothing);

      // Amara is saved in the address book, so she has the In contacts badge
      // and a private Talk shortcut from her connection row.
      await tester.enterText(
        find.byKey(const ValueKey('connections-search')),
        'Amara',
      );
      await tester.pumpAndSettle();
      expect(find.text('Amara Okafor'), findsOneWidget);
      expect(find.text('In contacts'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('follower-chat-amara')),
        findsOneWidget,
      );

      // Noah is only a connection. Search keeps him visible without a Talk
      // shortcut or a contact badge.
      await tester.enterText(
        find.byKey(const ValueKey('connections-search')),
        'Noah',
      );
      await tester.pumpAndSettle();
      expect(find.text('Noah Kim'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('follower-chat-noahk')),
        findsNothing,
      );
      expect(find.text('In contacts'), findsNothing);

      // Switching circles clears the previous search and shows the address
      // book, where Talk belongs to on-Docmac contacts only.
      await tester.tap(find.byKey(const ValueKey('connections-tab-contacts')));
      await tester.pumpAndSettle();

      expect(find.text('Your address book'), findsOneWidget);
      expect(find.text('On Docmac'), findsOneWidget);
      expect(find.text('Jack Wilson'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('contact-talk-jack')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('contact-talk-ngozi')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('contact-invite-ngozi')),
        findsOneWidget,
      );
    });

    testWidgets('accepts and ignores link requests in place', (tester) async {
      await _pumpConnections(tester);

      await tester.ensureVisible(
        find.byKey(const ValueKey('connections-filter-requests')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('connections-filter-requests')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Waiting on you'), findsOneWidget);
      expect(find.text('Ifeoma Obi'), findsOneWidget);
      expect(find.text('Bashir Lawal'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('accept-request-ifeomao')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('You and Ifeoma are now linked.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('accept-request-ifeomao')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('accept-request-bashirl')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('ignore-request-bashirl')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request from Bashir ignored.'), findsOneWidget);
      expect(find.text('All caught up'), findsOneWidget);
      expect(find.text('Ifeoma Obi'), findsNothing);
      expect(find.text('Bashir Lawal'), findsNothing);
    });

    testWidgets('links a social-only connection from the connections list',
        (tester) async {
      await _pumpConnections(tester);

      await tester.enterText(
        find.byKey(const ValueKey('connections-search')),
        'Nora',
      );
      await tester.pumpAndSettle();

      expect(find.text('Nora Williams'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('follower-follow-noraw')),
      );
      await tester.pumpAndSettle();

      // The action flips to the mutual "linked" state without navigating
      // away from the social list.
      expect(find.byTooltip('Linked. Tap to unlink.'), findsOneWidget);
      expect(find.text('Nora Williams'), findsOneWidget);
    });
  });

  group('Premium profile', () {
    testWidgets('settings separates people from linked services',
        (tester) async {
      _useMobileCanvas(tester, height: 1400);
      await tester.pumpWidget(
        MaterialApp(theme: _theme(), home: const SettingsPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('People & connections'), findsOneWidget);
      expect(
        find.text('Connections, links, and phone contacts'),
        findsOneWidget,
      );
      expect(find.text('Linked services'), findsOneWidget);
    });

    testWidgets('shows social connections and chat contacts as separate cards',
        (tester) async {
      await _pumpProfile(tester);

      expect(
          find.byKey(const ValueKey('profile-stat-followers')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-connections-followers')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('profile-connections-contacts')),
        findsOneWidget,
      );
      expect(find.text('Connections'), findsOneWidget);
      expect(find.text('Manage'), findsOneWidget);
      expect(find.text('2 requests waiting'), findsOneWidget);
      expect(find.text('8 on Docmac'), findsOneWidget);
    });

    testWidgets('opens the Contacts tab from the contact preview card',
        (tester) async {
      await _pumpProfile(tester);

      await tester.tap(
        find.byKey(const ValueKey('profile-connections-contacts')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your address book'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('connections-tab-contacts')),
        findsOneWidget,
      );
      expect(find.text('On Docmac'), findsOneWidget);
    });

    testWidgets('keeps real profile tabs on the premium layout',
        (tester) async {
      await _pumpProfile(tester);

      await tester.ensureVisible(
        find.byKey(const ValueKey('profile-tab-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile-tab-1')));
      await tester.pumpAndSettle();

      expect(find.text('Design club'), findsOneWidget);
      expect(find.text('Music room'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('profile-tab-2')));
      await tester.pumpAndSettle();

      expect(find.text('Saved moment · Open in Moments'), findsNWidgets(2));
    });
  });
}
