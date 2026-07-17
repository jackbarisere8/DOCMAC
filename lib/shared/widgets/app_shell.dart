import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Docmac Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome ${currentUser?.displayName ?? 'Guest'}'),
            const SizedBox(height: 12),
            Text(currentUser?.email ?? 'No account yet'),
            const SizedBox(height: 20),
            const Text('Your app shell is ready. Add chat, calls, contacts, profile, and settings here.'),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/chat');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.call), label: 'Calls'),
          NavigationDestination(icon: Icon(Icons.contacts), label: 'Contacts'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
