import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/docmac_iconly.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../people/data/repositories/user_directory_repository.dart';
import '../../../people/presentation/providers/people_providers.dart';

/// Starts a real 1:1 conversation from a public @username.
class NewDirectChatPage extends ConsumerStatefulWidget {
  const NewDirectChatPage({super.key});

  @override
  ConsumerState<NewDirectChatPage> createState() => _NewDirectChatPageState();
}

class _NewDirectChatPageState extends ConsumerState<NewDirectChatPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startTalk() async {
    final raw = _controller.text.trim();
    final handle = UserDirectoryRepository.normalizeHandle(raw);
    if (handle == null) {
      setState(() => _error = 'Enter a valid @username (3–20 characters).');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile =
          await ref.read(userDirectoryRepositoryProvider).findByHandle(handle);
      if (profile == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'No Docmac account is using @$handle yet.';
          });
        }
        return;
      }

      final chat = await ref.read(chatRepositoryProvider).ensureDirectChat(
            peerUid: profile.uid,
            peerHandle: profile.username,
            peerName: profile.displayName,
          );
      if (!mounted) return;

      HapticFeedback.selectionClick();
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: chat.chatId,
            peerUid: chat.peerUid,
            peerHandle: chat.peerHandle,
            personName: chat.peerName,
            personInitial:
                chat.peerName.isNotEmpty ? chat.peerName[0].toUpperCase() : '?',
            status: 'On Docmac',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(error);
      });
    }
  }

  String _messageFor(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('not-found')) {
      return 'That account is not on Docmac yet.';
    }
    if (text.contains('network') || text.contains('unavailable')) {
      return 'Docmac is offline. Check your connection and try again.';
    }
    return 'Could not start that talk. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New talk')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(DocmacIconlyLight.lock, color: scheme.onPrimaryContainer),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Talks are addressed by UID, not by a display name. '
                    'Use the @username the other person shared with you.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Their username', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_loading,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _startTalk(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              LengthLimitingTextInputFormatter(20),
            ],
            decoration: InputDecoration(
              prefixText: '@',
              hintText: 'username',
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loading ? null : _startTalk,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
            ),
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(_loading ? 'Opening…' : 'Start talk'),
          ),
          const SizedBox(height: 18),
          Text(
            'Only people who know your username can start a talk with you. '
            'Uploaded media and calling are not part of this build yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
