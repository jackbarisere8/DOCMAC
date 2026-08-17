import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Gives people useful account-safety alternatives before ending their session.
class LogoutOptionsPage extends ConsumerWidget {
  const LogoutOptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Leave Docmac'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(DocmacIconlyLight.arrowLeft),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Text('Before you go', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('Most account concerns can be handled without ending your session.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(children: [
              _Option(
                icon: DocmacIconlyLight.addUser,
                title: 'Add another account',
                subtitle: 'Keep more than one Docmac identity ready to switch.',
                onTap: () => _notice(
                    context, 'Multiple account switching is coming to Docmac.'),
              ),
              _Option(
                icon: DocmacIconlyLight.lock,
                title: 'Set a passcode',
                subtitle: 'Lock Docmac when someone else uses your phone.',
                onTap: () => context.push('/settings/app-lock'),
              ),
              _Option(
                icon: DocmacIconlyLight.delete,
                title: 'Clear cache',
                subtitle: 'Free device space. Your cloud content stays safe.',
                onTap: () => _notice(context, 'Cache controls are preparing a safe cleanup.'),
              ),
              _Option(
                icon: DocmacIconlyLight.swap,
                title: 'Change phone number',
                subtitle: 'Move your Docmac identity to a new number.',
                onTap: () => context.push('/settings/account'),
              ),
              _Option(
                icon: DocmacIconlyLight.infoCircle,
                title: 'Contact support',
                subtitle: 'Tell us what is not working before you leave.',
                onTap: () => _notice(context, 'Support will be available from Help and feedback.'),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error.withValues(alpha: .35)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(DocmacIconlyLight.logout),
            label: const Text('Sign out of Docmac'),
          ),
          const SizedBox(height: 14),
          Text('Signing out removes this account from this device. Your data remains in your Docmac account.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  static void _notice(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out of Docmac?'),
        content: const Text('You can sign back in whenever you are ready.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Stay signed in')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) context.go('/auth');
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(title),
        subtitle: Text(subtitle),
      );
}
