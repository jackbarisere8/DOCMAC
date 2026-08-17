import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth_service.dart';
import '../providers/auth_provider.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  bool _loading = false;
  bool _checking = false;
  String? _message;

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (mounted) setState(() => _message = 'Verification email sent again.');
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
      _message = null;
    });
    try {
      final verified =
          await ref.read(authServiceProvider).refreshEmailVerification();
      if (!mounted) return;
      if (verified) {
        context.go('/orbit');
      } else {
        setState(() {
          _message = 'Not verified yet. Open the email link, then try again.';
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var email = 'your email address';
    try {
      email = ref.read(authServiceProvider).currentUser?.email ?? email;
    } catch (_) {
      // The page can still render when Firebase is not configured locally.
    }

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.go('/auth'),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.mark_email_read_rounded,
                          size: 44, color: scheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text('One last step',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                    'Verify your email address to finish setting up Docmac.\n\n$email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.open_in_new_rounded,
                            color: scheme.primary, size: 25),
                        const SizedBox(height: 10),
                        Text(
                          'Open the Docmac email, select Verify email, then return here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Text(_message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurface)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _checking ? null : _checkVerification,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_rounded),
                    label:
                        Text(_checking ? 'Checking...' : 'I verified my email'),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _resend,
                    child: Text(
                        _loading ? 'Sending…' : 'Resend verification email'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/auth'),
                    child: const Text('Use a different email'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
