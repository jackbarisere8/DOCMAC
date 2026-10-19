import 'package:docmac_app/features/settings/presentation/pages/change_number_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/data_storage_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/delete_account_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/email_settings_page.dart';
import 'package:docmac_app/features/settings/presentation/pages/help_feedback_page.dart';
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

  testWidgets('delete account displays consequences and phone confirmation', (tester) async {
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
    expect(find.text('Change number instead?'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
  });

  testWidgets('change number displays overview instructions and navigates to inputs', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChangeNumberPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Change number'), findsAtLeastNWidgets(1));
    expect(find.text('Events and scheduled calls will not be migrated to your new number and will be deleted.'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next to advance to input step
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your old phone number with country code:'), findsOneWidget);
    expect(find.text('Enter your new phone number with country code:'), findsOneWidget);
  });

  testWidgets('security notifications shows E2EE protections and device alert toggle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SecurityNotificationsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Security notifications'), findsOneWidget);
    expect(find.text('Your chats and calls are private'), findsOneWidget);
    expect(find.text('Text and voice messages'), findsOneWidget);
    expect(find.text('Audio and video calls'), findsOneWidget);
    expect(find.text('Show security notifications on this device'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('two-step verification shows active state and management options', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TwoStepVerificationPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Two-step verification'), findsOneWidget);
    expect(find.text('Turn off'), findsOneWidget);
    expect(find.text('Change PIN'), findsOneWidget);
  });

  testWidgets('email settings page displays current email, domain chips and next button', (tester) async {
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
    expect(find.text('Next'), findsOneWidget);

    // Tap domain chip to append
    await tester.tap(find.text('@gmail.com'));
    await tester.pumpAndSettle();

    expect(find.text('@gmail.com'), findsAtLeastNWidgets(1));
  });

  testWidgets('passkeys page displays security benefits and create action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PasskeysPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Passkeys'), findsOneWidget);
    expect(find.text('Log in securely and protect your account'), findsOneWidget);
    expect(find.text('Create passkey'), findsOneWidget);
  });

  testWidgets('lists settings page displays presets and allows creating custom list', (tester) async {
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

  testWidgets('privacy help page renders privacy documentation and contact button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PrivacyHelpPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy'), findsAtLeastNWidgets(1));
    expect(find.text('About end-to-end encryption'), findsOneWidget);
    expect(find.text('Contact us'), findsOneWidget);
  });

  testWidgets('account settings page exposes WhatsApp Image 2 sections', (tester) async {
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
}
