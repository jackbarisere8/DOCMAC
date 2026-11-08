import 'package:docmac_app/core/ui/docmac_iconly.dart';
import 'package:docmac_app/features/orbit/presentation/pages/orbit_page.dart';
import 'package:docmac_app/features/people/presentation/pages/people_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home header leads with the wordmark and ends with profile',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: OrbitPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final wordmark = find.text('DocMac');
    final arrivals = find.byKey(const ValueKey('orbit-arrivals'));
    final profile = find.byKey(const ValueKey('orbit-profile'));

    expect(wordmark, findsOneWidget);
    expect(arrivals, findsOneWidget);
    expect(profile, findsOneWidget);
    expect(find.byTooltip('Search'), findsNothing);

    expect(
      tester.getTopLeft(wordmark).dx,
      lessThan(tester.getTopLeft(arrivals).dx),
    );
    expect(
      tester.getTopLeft(arrivals).dx,
      lessThan(tester.getTopLeft(profile).dx),
    );
  });

  testWidgets('Discover leaves Link request decisions to the People hub',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PeopleDiscoverPage()),
    );
    await tester.pumpAndSettle();

    // Accepting requests lives on People, not Discover.
    expect(find.byKey(const ValueKey('discover-link-requests')), findsNothing);
    expect(find.text('Link requests'), findsNothing);
    expect(find.textContaining('pending'), findsNothing);

    // Suggestions no longer ask people with pending incoming requests to Link.
    expect(find.text('Nora Williams'), findsNothing);
    expect(find.text('David Mensah'), findsNothing);
    expect(find.text('Emma Clarke'), findsOneWidget);
    expect(find.text('Amara Okafor'), findsOneWidget);
  });

  testWidgets('Link requests page uses premium Accept actions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PeopleRequestsPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Link requests'), findsOneWidget);
    expect(find.text('Pending requests'), findsOneWidget);
    expect(find.text('Accept'), findsNWidgets(2));
    expect(find.byIcon(DocmacIconlyLight.tickSquare), findsNWidgets(2));
  });

  testWidgets('Arrivals header offers notification settings', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationsPage()),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Notification settings'), findsOneWidget);
    expect(find.byIcon(DocmacIconlyLight.setting), findsOneWidget);
  });
}
