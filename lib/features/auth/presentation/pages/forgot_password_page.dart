import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth_service.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
            () => _error = error.message ?? 'Unable to send the reset email.');
      }
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to send the reset email.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.go('/auth'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _sent
                  ? _ResetSent(
                      email: _emailController.text.trim(),
                      onBack: () => context.go('/auth'),
                      onResend: _sendReset,
                      loading: _loading,
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _PageIcon(icon: Icons.lock_reset_rounded),
                          const SizedBox(height: 22),
                          Text(
                            'Forgot password?',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your email and we’ll send you a secure link to reset your password.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              hintText: 'you@example.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (value) =>
                                value != null && value.contains('@')
                                    ? null
                                    : 'Enter a valid email address',
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: TextStyle(color: scheme.error)),
                          ],
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: _loading ? null : _sendReset,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Send reset link'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetSent extends StatelessWidget {
  const _ResetSent({
    required this.email,
    required this.onBack,
    required this.onResend,
    required this.loading,
  });

  final String email;
  final VoidCallback onBack;
  final VoidCallback onResend;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PageIcon(icon: Icons.mark_email_read_rounded),
        const SizedBox(height: 22),
        Text('Check your email',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('We sent a password reset link to $email.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(Icons.inbox_rounded, color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Open Gmail or your mail app and follow the link.',
                    style: TextStyle(color: scheme.onPrimaryContainer)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        FilledButton(
          onPressed: onBack,
          child: const Text('Back to sign in'),
        ),
        TextButton(
          onPressed: loading ? null : onResend,
          child: Text(loading ? 'Sending…' : 'Resend email'),
        ),
      ],
    );
  }
}

class _PageIcon extends StatelessWidget {
  const _PageIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: scheme.onPrimaryContainer, size: 28),
      ),
    );
  }
}
