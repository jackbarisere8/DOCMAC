import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/ui/docmac_iconly.dart';
import '../../../../shared/widgets/docmac_menu_item.dart';

/// WhatsApp-style Email Address screen (Image 5).
/// Allows viewing, editing, domain autocomplete, and removal of account email.
class EmailSettingsPage extends ConsumerStatefulWidget {
  const EmailSettingsPage({super.key});

  @override
  ConsumerState<EmailSettingsPage> createState() => _EmailSettingsPageState();
}

class _EmailSettingsPageState extends ConsumerState<EmailSettingsPage> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  bool _loading = false;
  String? _error;

  static const _domains = [
    '@gmail.com',
    '@outlook.com',
    '@hotmail.com',
    '@live.com',
    '@icloud.com',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    _controller = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyDomain(String domain) {
    HapticFeedback.selectionClick();
    final current = _controller.text.trim();
    if (current.isEmpty) {
      _controller.text = domain;
      _controller.selection = const TextSelection.collapsed(offset: 0);
      return;
    }

    final atIndex = current.indexOf('@');
    final prefix = atIndex != -1 ? current.substring(0, atIndex) : current;
    final newEmail = '$prefix$domain';

    _controller.text = newEmail;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newEmail.length),
    );
    setState(() => _error = null);
  }

  Future<void> _saveEmail() async {
    final email = _controller.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(
          () => _error = 'Enter a valid email format (e.g. name@example.com)');
      return;
    }

    final firebaseUser = ref.read(authStateProvider).value;
    if (firebaseUser == null) {
      setState(() => _error = 'Sign in before changing your email.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Firebase sends a confirmation link; the sign-in email does not change
      // until the link is opened. Never claim success before that happens.
      await firebaseUser.verifyBeforeUpdateEmail(email);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification link sent to $email. Your sign-in email changes '
            'after you open it.',
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(error.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not send the verification link. Try again.';
      });
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'requires-recent-login':
        return 'Sign in again, then retry the email change.';
      case 'email-already-in-use':
        return 'That email is already attached to another account.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a while and try again.';
      case 'network-request-failed':
        return 'Docmac is offline. Check your connection and try again.';
      default:
        return 'Could not send the verification link. Try again.';
    }
  }

  Future<void> _removeEmail() async {
    final firebaseUser = ref.read(authStateProvider).value;
    if (firebaseUser?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sign-in email is attached.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove email'),
        content: const Text(
          'The sign-in email is managed by Firebase Authentication and cannot '
          'be removed from this screen. You can replace it with a verification '
          'link, or delete the account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLearnMore() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Email Verification & Recovery'),
        content: const Text(
          'Adding an email address helps safeguard your Docmac identity. '
          'We use it strictly for recovery alerts, account notifications, '
          'and customer security notifications. It is never displayed publicly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final brandGreen =
        isDark ? const Color(0xFF2E9C92) : const Color(0xFF1B6B48);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email address'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Options',
            icon: const Icon(Icons.more_vert_rounded, size: 21),
            onSelected: (val) {
              if (val == 'remove') _removeEmail();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'remove',
                child: DocmacMenuItem(
                  icon: DocmacIconlyLight.delete,
                  label: 'Remove email',
                  destructive: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                children: [
                  Text(
                    'Email helps us verify your account or recover access if you have sign-in or support issues. '
                    'Your email address won’t be visible to others. ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: _showLearnMore,
                      child: Text(
                        'Learn more',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email Input Box with Rounded Border
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _error != null
                            ? scheme.error
                            : (_focusNode.hasFocus
                                ? scheme.primary
                                : theme.dividerColor),
                        width: _focusNode.hasFocus ? 1.5 : 1.0,
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _saveEmail(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter your email address',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _error!,
                        style: TextStyle(color: scheme.error, fontSize: 13),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Domain suggestion chips
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _domains.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final domain = _domains[index];
                        return ActionChip(
                          label: Text(domain),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          backgroundColor: scheme.surface,
                          side: BorderSide(color: theme.dividerColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          onPressed: () => _applyDomain(domain),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Pinned Bottom Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: brandGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _loading ? null : _saveEmail,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Send link',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
