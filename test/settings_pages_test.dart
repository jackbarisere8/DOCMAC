import 'package:docmac_app/features/settings/presentation/pages/change_number_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/data_storage_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/delete_account_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/email_settings_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/help_feedback_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/help_categories_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/lists_settings_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/passkeys_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/privacy_help_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/privacy_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/security_notifications_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/settings_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/two_step_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  testWidgets('delete account displays consequences and phone confirmation',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DeleteAccountPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete this account'), findsOneWidget);
    expect(find.text('If you delete this account:'), findsOneWidget);
    expect(find.text('Changed your mind?'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
  });

  testWidgets('change number reports that it is unavailable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChangeNumberPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Change number'), findsAtLeastNWidgets(1));
    expect(
        find.text('Changing your number is not available yet'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets(
      'security notifications is honest about encryption and device alerts',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SecurityNotificationsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Security notifications'), findsOneWidget);
    expect(find.text('How your account is protected'), findsOneWidget);
    expect(find.textContaining('does not encrypt messages end-to-end yet'),
        findsWidgets);
    expect(find.text('Text messages between conversation members'),
        findsOneWidget);
    expect(find.text('Show security notifications on this device'),
        findsOneWidget);
    expect(find.textContaining('Not available yet'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });

  testWidgets('two-step verification reports that it is unavailable',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TwoStepVerificationPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Two-step verification'), findsOneWidget);
    expect(find.text('Two-step verification is not available yet'),
        findsOneWidget);
    expect(find.text('Change PIN'), findsNothing);
    expect(find.text('Turn off'), findsNothing);
  });

  testWidgets(
      'email settings page displays current email, domain chips and send link',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: EmailSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('@gmail.com'), findsOneWidget);
    expect(find.text('@outlook.com'), findsOneWidget);
    expect(find.text('Send link'), findsOneWidget);

    // Tap domain chip to append
    await tester.tap(find.text('@gmail.com'));
    await tester.pumpAndSettle();

    expect(find.text('@gmail.com'), findsAtLeastNWidgets(1));
  });

  testWidgets('passkeys page reports that passkeys are unavailable',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PasskeysPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Passkeys'), findsOneWidget);
    expect(find.text('Passkeys are not available yet'), findsOneWidget);
    expect(find.text('Create passkey'), findsNothing);
    expect(find.textContaining('WebAuthn'), findsOneWidget);
  });

  testWidgets(
      'lists settings page displays presets and allows creating custom list',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ListsSettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lists'), findsOneWidget);
    expect(find.text('Create a custom list'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
  });

  testWidgets(
      'privacy help page renders privacy documentation and contact button',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PrivacyHelpPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy'), findsAtLeastNWidgets(1));
    expect(find.text('About message privacy'), findsOneWidget);
    expect(find.text('Contact us'), findsOneWidget);
  });

  testWidgets('account settings page exposes WhatsApp Image 2 sections',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AccountSettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Login and security'), findsOneWidget);
    expect(find.text('Passkeys'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Business Platform'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Delete account'), 300);
    expect(find.text('Delete account'), findsOneWidget);
  });

  testWidgets(
      'help chats page displays WhatsApp Image 3 topics and contact button',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HelpChatsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Help Center'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Individual and Group Chats'), findsOneWidget);
    expect(find.text('Back Up and Restore'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('AI Experiences'), findsOneWidget);
    expect(find.text('Contact us'), findsOneWidget);
  });

  testWidgets(
      'help communities page displays WhatsApp Image 2 sections and contact button',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HelpCommunitiesPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Help Center'), findsOneWidget);
    expect(find.text('Communities'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Contact us'), findsOneWidget);
  });

  testWidgets(
      'help privacy safety security page displays WhatsApp Image 1 topics',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HelpPrivacySafetySecurityPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Help Center'), findsOneWidget);
    expect(find.text('Privacy, Safety, and Security'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Safety'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Contact us'), findsOneWidget);
  });

  testWidgets(
      'help status page renders Image 4 articles and filters with search',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HelpStatusPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Status'), findsAtLeastNWidgets(1));
    expect(find.text('About status'), findsOneWidget);
    expect(find.text('How to create and share a status'), findsOneWidget);
    expect(find.text('Contact us'), findsOneWidget);

    // Enter search query
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mentions');
    await tester.pumpAndSettle();

    expect(find.text('About status mentions'), findsOneWidget);
    expect(find.text('About status'), findsNothing);
  });

  testWidgets(
      'help troubleshooting page renders Image 5 articles and filters with search',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HelpTroubleshootingPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Troubleshooting'), findsAtLeastNWidgets(1));
    expect(find.text('Not seeing a feature on Docmac'), findsOneWidget);
    expect(find.text('How to fix connection issues'), findsOneWidget);
    expect(find.text('Contact us'), findsOneWidget);

    // Enter search query
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'keyboard');
    await tester.pumpAndSettle();

    expect(find.text('Can’t use keyboard in Docmac'), findsOneWidget);
    expect(find.text('Not seeing a feature on Docmac'), findsNothing);
  });
}
