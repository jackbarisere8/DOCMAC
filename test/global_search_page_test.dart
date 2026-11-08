import 'package:docmac_app/features/search/presentation/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'GlobalSearchPage shows recent searches and category cards on launch',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GlobalSearchPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search Docmac'), findsOneWidget);
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Browse categories'), findsOneWidget);
    expect(find.text('People & Contacts'), findsOneWidget);
    expect(find.text('Talk Threads'), findsOneWidget);
    expect(find.text('Circles & Spaces'), findsOneWidget);
  });

  testWidgets(
      'GlobalSearchPage filters results when typing query and clears properly',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GlobalSearchPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Enter a search query
    await tester.enterText(
        find.byKey(const ValueKey('global-search-input')), 'Emma');
    await tester.pumpAndSettle();

    // Verify search matches
    expect(find.text('Emma Clarke'), findsOneWidget);
    expect(find.text('@emma · London, UK'), findsOneWidget);

    // Clear search using clear button
    await tester.tap(find.byKey(const ValueKey('clear-global-search')));
    await tester.pumpAndSettle();

    // Should return to explore view
    expect(find.text('Browse categories'), findsOneWidget);
  });

  testWidgets('GlobalSearchPage initializes with initialQuery', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GlobalSearchPage(initialQuery: 'Forge'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.text('Should AI replace traditional homework?'), findsOneWidget);
  });

  testWidgets('GlobalSearchPage shows friendly empty state for unknown query',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GlobalSearchPage(initialQuery: 'xyzunknownterm'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No results for “xyzunknownterm”'), findsOneWidget);
    expect(find.text('Show all categories'), findsOneWidget);
  });
}
