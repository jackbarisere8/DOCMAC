import 'package:docmac_app/features/settings/presentation/pages/data_storage_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/help_feedback_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('privacy and security exposes detailed controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPage()));
    await tester.pumpAndSettle();

    expect(find.text('Privacy and security'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Archive and mute'), 300);
    expect(find.text('Archive and mute'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sync contacts'), 300);
    expect(find.text('Sync contacts'), findsOneWidget);
  });

  testWidgets('data and storage exposes download controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DataStoragePage()));
    await tester.pumpAndSettle();

    expect(find.text('Storage usage'), findsOneWidget);
    expect(find.text('Automatic media download'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.text('Stream videos and audio files'), 300);
    expect(find.text('Stream videos and audio files'), findsOneWidget);
  });

  testWidgets('help and feedback exposes support actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpFeedbackPage()));

    expect(find.text('Help center'), findsOneWidget);
    expect(find.text('Send feedback'), findsOneWidget);
    expect(find.text('App info'), findsOneWidget);
  });
}
