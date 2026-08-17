import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome back')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Docmac',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Sign in to continue'),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await authService.signInAnonymously();
                  if (context.mounted) {
                    context.go('/');
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Continue with Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
