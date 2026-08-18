import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/hero_screen.dart';
import '../../features/splash/presentation/startup_loading_screen.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/settings/presentation/pages/appearance_settings_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/notifications_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/chat/presentation/pages/chat_preferences_pages.dart';
import '../../features/chat/presentation/pages/forward_message_page.dart';
import '../../features/circles/presentation/pages/circle_pages.dart';
import '../../features/circles/presentation/pages/circle_talk_pages.dart';
import '../../features/contacts/presentation/pages/contact_pages.dart';
import '../../features/forge/presentation/pages/forge_page.dart';
import '../../features/foundry/presentation/pages/foundry_page.dart';
import '../../features/live/presentation/pages/voice_call_page.dart';
import '../../features/live/presentation/pages/schedule_call_page.dart';
import '../../features/moments/presentation/pages/moments_page.dart';
import '../../features/people/presentation/pages/person_space_page.dart';
import '../../features/people/presentation/pages/people_page.dart';
import '../../features/relays/presentation/pages/relay_pages.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/settings/presentation/pages/privacy_page.dart';
import '../../features/settings/presentation/pages/logout_options_page.dart';
import '../../features/settings/presentation/pages/data_storage_page.dart';
import '../../features/settings/presentation/pages/help_feedback_page.dart';
import '../../features/talk/presentation/pages/talk_page.dart';
import '../../shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/loading',
    // Startup restores only completed phone-authenticated profiles. A verified
    // phone without a completed profile remains in the signup journey.
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const StartupLoadingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HeroScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/register/country',
        builder: (context, state) => const CountryPickerPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationPage(),
      ),
      GoRoute(
        path: '/appearance',
        builder: (context, state) => const AppearanceSettingsPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/settings/app-lock',
        builder: (context, state) => const AppLockSettingsPage(),
      ),
      GoRoute(
        path: '/settings/account',
        builder: (context, state) => const AccountSettingsPage(),
      ),
      GoRoute(
        path: '/settings/connections',
        builder: (context, state) => const ConnectionSettingsPage(),
      ),
      GoRoute(
        path: '/settings/accessibility',
        builder: (context, state) => const AccessibilitySettingsPage(),
      ),
      GoRoute(
        path: '/settings/language',
        builder: (context, state) => const AppLanguageSettingsPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPage(),
      ),
      GoRoute(
        path: '/storage',
        builder: (context, state) => const DataStoragePage(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpFeedbackPage(),
      ),
      GoRoute(
        path: '/foundry',
        builder: (context, state) => const FoundryPage(),
      ),
      GoRoute(
        path: '/logout',
        builder: (context, state) => const LogoutOptionsPage(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const GlobalSearchPage(),
      ),
      GoRoute(
        path: '/moments',
        builder: (context, state) => MomentsPage(
          shareWith: state.uri.queryParameters['shareWith'],
        ),
      ),
      GoRoute(
        path: '/forge',
        builder: (context, state) => const ForgePage(),
      ),
      GoRoute(
        path: '/relays',
        builder: (context, state) => const RelaysPage(),
      ),
      GoRoute(
        path: '/relays/new',
        builder: (context, state) => const RelayCreatePage(),
      ),
      GoRoute(
        path: '/relays/home',
        builder: (context, state) => const RelayHomePage(),
      ),
      GoRoute(
        path: '/relays/drop',
        builder: (context, state) => const RelayDropPage(),
      ),
      GoRoute(
        path: '/relays/analytics',
        builder: (context, state) => const RelayAnalyticsPage(),
      ),
      GoRoute(
        path: '/person/:personId',
        builder: (context, state) => PersonSpacePage(
          personId: state.pathParameters['personId']!,
        ),
      ),
      GoRoute(
        path: '/live/call/:personId',
        builder: (context, state) => VoiceCallPage(
          personId: state.pathParameters['personId']!,
        ),
      ),
      GoRoute(
        path: '/live/schedule',
        builder: (context, state) => const ScheduleCallPage(),
      ),
      GoRoute(
        path: '/app',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/orbit',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/talk',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/talk/archive',
        builder: (context, state) => const TalkArchivePage(),
      ),
      GoRoute(
        path: '/live',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/me',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatPage(),
      ),
      GoRoute(
        path: '/spaces',
        builder: (context, state) => const CircleLandingPage(),
      ),
      GoRoute(
        path: '/spaces/new',
        builder: (context, state) => const NewCirclePage(),
      ),
      GoRoute(
        path: '/spaces/info',
        builder: (context, state) => CircleInfoPage(
          initialTab:
              state.uri.queryParameters['tab'] == 'announcements' ? 1 : 0,
        ),
      ),
      GoRoute(
        path: '/spaces/settings',
        builder: (context, state) => const CircleSettingsPage(),
      ),
      GoRoute(
        path: '/spaces/deactivate',
        builder: (context, state) => const CircleDeactivatePage(),
      ),
      // Legacy links from the early community prototype.
      GoRoute(
        path: '/circles',
        builder: (context, state) => const CircleLandingPage(),
      ),
      GoRoute(
        path: '/circles/new',
        builder: (context, state) => const NewCirclePage(),
      ),
      GoRoute(
        path: '/circles/info',
        builder: (context, state) => CircleInfoPage(
          initialTab:
              state.uri.queryParameters['tab'] == 'announcements' ? 1 : 0,
        ),
      ),
      GoRoute(
        path: '/circles/settings',
        builder: (context, state) => const CircleSettingsPage(),
      ),
      GoRoute(
        path: '/circles/deactivate',
        builder: (context, state) => const CircleDeactivatePage(),
      ),
      GoRoute(
        path: '/circle',
        builder: (context, state) => const CircleTalkPage(),
      ),
      GoRoute(
        path: '/circle/new',
        builder: (context, state) => const CircleCreatePage(),
      ),
      GoRoute(
        path: '/circle/info',
        builder: (context, state) => CircleConversationInfoPage(
          initialTab: state.uri.queryParameters['tab'] == 'settings' ? 2 : 0,
        ),
      ),
      GoRoute(
        path: '/circle/members/add',
        builder: (context, state) => const CircleAddMembersPage(),
      ),
      GoRoute(
        path: '/circle/edit',
        builder: (context, state) => const CircleEditPage(),
      ),
      GoRoute(
        path: '/circle/permissions',
        builder: (context, state) => const CirclePermissionsPage(),
      ),
      GoRoute(
        path: '/circle/reactions',
        builder: (context, state) => const CircleReactionsPage(),
      ),
      GoRoute(
        path: '/circle/access',
        builder: (context, state) => const CircleAccessPage(),
      ),
      GoRoute(
        path: '/chat/theme',
        builder: (context, state) => const ChatThemePage(),
      ),
      GoRoute(
        path: '/chat/disappearing',
        builder: (context, state) => const DisappearingMessagesPage(),
      ),
      GoRoute(
        path: '/chat/color',
        builder: (context, state) => const ChatColorPage(),
      ),
      GoRoute(
        path: '/chat/wallpaper',
        builder: (context, state) => const WallpaperPage(),
      ),
      GoRoute(
        path: '/chat/forward',
        builder: (context, state) => const ForwardMessagePage(),
      ),
      GoRoute(
        path: '/contacts/new-talk',
        builder: (context, state) => const NewTalkPage(),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const PeoplePage(),
      ),
      GoRoute(
        path: '/people',
        builder: (context, state) => const PeoplePage(),
      ),
      GoRoute(
        path: '/people/requests',
        builder: (context, state) => const PeopleRequestsPage(),
      ),
      GoRoute(
        path: '/people/all',
        builder: (context, state) => const YourPeoplePage(),
      ),
      GoRoute(
        path: '/people/discover',
        builder: (context, state) => const PeopleDiscoverPage(),
      ),
      GoRoute(
        path: '/people/invite',
        builder: (context, state) => const PeopleInvitePage(),
      ),
      GoRoute(
        path: '/contacts/settings',
        builder: (context, state) => const ContactSettingsPage(),
      ),
      GoRoute(
        path: '/contacts/new',
        builder: (context, state) => const NewContactPage(),
      ),
      GoRoute(
        path: '/contacts/country',
        builder: (context, state) => const CountryPickerPage(),
      ),
    ],
  );
});
