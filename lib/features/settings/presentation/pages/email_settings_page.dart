import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

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
    final user = ref.read(currentUserProvider);
    _controller = TextEditingController(text: user?.email ?? '');
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_account_email');
    if (saved != null && saved.isNotEmpty && mounted) {
      _controller.text = saved;
    }
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
      setState(() => _error = 'Enter a valid email format (e.g. name@example.com)');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_account_email', email);

      // Attempt Firebase update if user logged in
      final firebaseUser = ref.read(authStateProvider).value;
      if (firebaseUser != null) {
        try {
          await firebaseUser.verifyBeforeUpdateEmail(email);
        } catch (_) {
          // May require recent login in Firebase, preferences updated nonetheless
        }
      }

      await Future<void>.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email updated to $email')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to update email: $e';
        });
      }
    }
  }

  Future<void> _removeEmail() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove email?'),
        content: const Text(
          'Email helps us verify your account or recover access if you have sign-in issues. '
          'Are you sure you want to remove it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_account_email');
      _controller.clear();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email address removed.')),
        );
        context.pop();
      }
    }
  }

  void _showLearnMore() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Email Verification & Recovery'),
        content: const Text(
          'Adding an email address helps safeguard your Docmac identity. '
          'We use it strictly for recovery alerts, passkey synchronization, '
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
    final brandGreen = isDark ? const Color(0xFF2E9C92) : const Color(0xFF1B6B48);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email address'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (val) {
              if (val == 'remove') _removeEmail();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'remove',
                child: Text('Remove email'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          'Next',
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
