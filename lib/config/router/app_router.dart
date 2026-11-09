import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../feature_flags.dart';

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
import '../../features/connections/presentation/pages/connections_page.dart';
import '../../features/contacts/presentation/pages/contact_pages.dart';
import '../../features/talk/presentation/pages/new_direct_chat_page.dart';
import '../../features/forge/presentation/pages/forge_page.dart';
import '../../features/foundry/presentation/pages/foundry_page.dart';
import '../../features/live/presentation/pages/voice_call_page.dart';
import '../../features/live/presentation/pages/schedule_call_page.dart';
import '../../features/moments/presentation/pages/moment_archive_page.dart';
import '../../features/moments/presentation/pages/moments_page.dart';
import '../../features/people/presentation/pages/person_space_page.dart';
import '../../features/people/presentation/pages/people_page.dart';
import '../../features/relays/presentation/pages/relay_pages.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/settings/presentation/pages/privacy_page.dart';
import '../../features/settings/presentation/pages/logout_options_page.dart';
import '../../features/settings/presentation/pages/data_storage_page.dart';
import '../../features/settings/presentation/pages/delete_account_page.dart';
import '../../features/settings/presentation/pages/change_number_page.dart';
import '../../features/settings/presentation/pages/email_settings_page.dart';
import '../../features/settings/presentation/pages/security_notifications_page.dart';
import '../../features/settings/presentation/pages/two_step_verification_page.dart';
import '../../features/settings/presentation/pages/passkeys_page.dart';
import '../../features/settings/presentation/pages/lists_settings_page.dart';
import '../../features/settings/presentation/pages/privacy_help_page.dart';
import '../../features/settings/presentation/pages/help_feedback_page.dart';
import '../../features/settings/presentation/pages/help_categories_page.dart';
import '../../features/live/presentation/pages/live_page.dart';
import '../../features/orbit/presentation/pages/orbit_page.dart';
import '../../features/me/presentation/pages/me_page.dart';
import '../../features/talk/presentation/pages/talk_page.dart';
import '../../shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/loading',
    redirect: (context, state) {
      final loc = state.uri.path;
      final isPublic = loc == '/' ||
          loc == '/loading' ||
          loc.startsWith('/auth') ||
          loc.startsWith('/register') ||
          loc == '/forgot-password' ||
          loc == '/verify-email';

      final user = authState.valueOrNull;
      final isLoggedIn = user != null;

      if (!isLoggedIn && !isPublic) {
        return '/auth';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Page Not Found'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '404',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'The requested page was not found.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.go('/orbit'),
                child: const Text('Return Home'),
              ),
            ],
          ),
        ),
      ),
    ),
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
        builder: (context, state) => SignUpPage(
          resume: state.uri.queryParameters['resume'] == 'true',
        ),
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
        path: '/settings/delete-account',
        builder: (context, state) => const DeleteAccountPage(),
      ),
      GoRoute(
        path: '/settings/change-number',
        builder: (context, state) => const ChangeNumberPage(),
      ),
      GoRoute(
        path: '/settings/security-notifications',
        builder: (context, state) => const SecurityNotificationsPage(),
      ),
      GoRoute(
        path: '/settings/two-step',
        builder: (context, state) => const TwoStepVerificationPage(),
      ),
      GoRoute(
        path: '/settings/email',
        builder: (context, state) => const EmailSettingsPage(),
      ),
      GoRoute(
        path: '/settings/passkeys',
        builder: (context, state) => const PasskeysPage(),
      ),
      GoRoute(
        path: '/settings/lists',
        builder: (context, state) => const ListsSettingsPage(),
      ),
      GoRoute(
        path: '/settings/privacy-help',
        builder: (context, state) => const PrivacyHelpPage(),
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
        path: '/notifications/preferences',
        builder: (context, state) => const ArrivalPreferencesPage(),
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
        path: '/help/center',
        builder: (context, state) => const HelpCenterPage(),
      ),
      GoRoute(
        path: '/help/feedback',
        builder: (context, state) => const SendFeedbackPage(),
      ),
      GoRoute(
        path: '/help/chats',
        builder: (context, state) => const HelpChatsPage(),
      ),
      GoRoute(
        path: '/help/communities',
        builder: (context, state) => const HelpCommunitiesPage(),
      ),
      GoRoute(
        path: '/help/privacy-safety-security',
        builder: (context, state) => const HelpPrivacySafetySecurityPage(),
      ),
      GoRoute(
        path: '/help/status',
        builder: (context, state) => const HelpStatusPage(),
      ),
      GoRoute(
        path: '/help/troubleshooting',
        builder: (context, state) => const HelpTroubleshootingPage(),
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
        builder: (context, state) => GlobalSearchPage(
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
      GoRoute(
        path: '/moments',
        builder: (context, state) => MomentsPage(
          shareWith: state.uri.queryParameters['shareWith'],
        ),
      ),
      GoRoute(
        path: '/moments/archive',
        builder: (context, state) => const MomentArchivePage(),
      ),
      GoRoute(
        path: '/forge',
        builder: (context, state) => const ForgePage(),
      ),
      GoRoute(
        path: '/forge/new',
        builder: (context, state) => const CreatePerspectivePage(),
      ),
      GoRoute(
        path: '/forge/perspective',
        builder: (context, state) => PerspectivePage(
          perspective: state.extra as Perspective,
        ),
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
        path: '/talk/new',
        builder: (context, state) => const NewDirectChatPage(),
      ),
      GoRoute(
        path: '/talk/person/:personId',
        builder: (context, state) {
          final id = state.pathParameters['personId']!;
          final info = _personInfo(id);
          return ChatPage(
            chatId: state.uri.queryParameters['chat'],
            peerUid: state.uri.queryParameters['uid'],
            peerHandle: state.uri.queryParameters['handle'] ?? id,
            personName: state.uri.queryParameters['name'] ?? info.$1,
            personInitial: info.$2,
            status: AppFeatureFlags.localPreviews && info.$3
                ? 'Active now'
                : 'Status unavailable',
          );
        },
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
        redirect: (context, state) => '/orbit',
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orbit',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: OrbitPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/talk',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TalkPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/live',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: LivePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MePage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final personId = state.uri.queryParameters['person'];
          final info = personId != null ? _personInfo(personId) : null;
          return ChatPage(
            chatId: state.uri.queryParameters['chat'],
            peerUid: state.uri.queryParameters['uid'],
            peerHandle: state.uri.queryParameters['handle'] ?? personId,
            personName: state.uri.queryParameters['name'] ?? info?.$1 ?? 'Talk',
            personInitial: info?.$2 ?? 'T',
            status: AppFeatureFlags.localPreviews && (info?.$3 ?? false)
                ? 'Active now'
                : 'Status unavailable',
          );
        },
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
        builder: (context, state) => const NewDirectChatPage(),
      ),
      GoRoute(
        path: '/connections',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final filter = state.uri.queryParameters['filter'];
          return ConnectionsPage(
            initialTab: tab == 'contacts'
                ? ConnectionTab.contacts
                : ConnectionTab.followers,
            initialFollowerFilter: switch (filter) {
              'following' => FollowerFilter.following,
              'requests' => FollowerFilter.requests,
              _ => FollowerFilter.followers,
            },
          );
        },
      ),
      GoRoute(
        path: '/followers',
        builder: (context, state) => const ConnectionsPage(),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ConnectionsPage(
          initialTab: ConnectionTab.contacts,
        ),
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
        builder: (context, state) => NewContactPage(
          initialPhone: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: '/contacts/country',
        builder: (context, state) => const CountryPickerPage(),
      ),
    ],
  );
});

/// Maps a person ID (lowercase slug) to (name, initial, isOnline).
/// Mirrors the static roster in PersonSpacePage for debug previews only.
(String, String, bool) _personInfo(String id) {
  if (AppFeatureFlags.localPreviews) {
    return switch (id) {
      'jack' => ('Jack Wilson', 'J', true),
      'emma' => ('Emma Clarke', 'E', true),
      'david' => ('David Okafor', 'D', false),
      'davidm' => ('David Mensah', 'D', false),
      'amara' => ('Amara Okafor', 'A', true),
      'noraw' => ('Nora Williams', 'N', false),
      'tobi' => ('Tobi Adeyemi', 'T', false),
      _ => _fallbackPersonInfo(id),
    };
  }
  return _fallbackPersonInfo(id);
}

(String, String, bool) _fallbackPersonInfo(String id) {
  if (id.isEmpty) return ('Talk', 'T', false);
  final name = id[0].toUpperCase() + id.substring(1);
  return (name, id[0].toUpperCase(), false);
}
