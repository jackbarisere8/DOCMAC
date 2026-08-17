import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final _messages = <_Message>[
    const _Message(
        'Hey Jack, are we still on for the walk later?', false, '6:18 PM'),
    const _Message(
        'Definitely. I found a quieter route by the water.', true, '6:20 PM'),
    const _Message('Perfect. I will bring the coffee.', false, '6:21 PM'),
  ];

  Timer? _recordingTicker;
  DateTime? _recordingStartedAt;
  Duration _recordingDuration = Duration.zero;
  bool _hasMessageText = false;
  bool _showAttachments = false;
  bool _isRecording = false;
  bool _pressingRecord = false;
  bool _isRecordingPaused = false;
  bool _recordOnce = false;
  _Message? _selectedMessage;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_updateComposer);
  }

  @override
  void dispose() {
    _recordingTicker?.cancel();
    _messageController
      ..removeListener(_updateComposer)
      ..dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _updateComposer() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasMessageText && mounted) {
      setState(() => _hasMessageText = hasText);
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _messages.add(_Message(message, true, 'Now'));
      _messageController.clear();
      _showAttachments = false;
    });
  }

  Future<void> _beginRecording() async {
    if (_hasMessageText || _isRecording) return;

    _pressingRecord = true;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Microphone permission is needed to record.')),
        );
      }
      return;
    }
    if (!_pressingRecord || !mounted) return;

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}${Platform.pathSeparator}'
        'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    if (!_pressingRecord || !mounted) {
      await _audioRecorder.cancel();
      return;
    }

    setState(() {
      _isRecording = true;
      _isRecordingPaused = false;
      _recordOnce = false;
      _recordingDuration = Duration.zero;
      _recordingStartedAt = DateTime.now();
      _showAttachments = false;
    });
    _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRecording && !_isRecordingPaused) {
        setState(() => _recordingDuration += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _finishRecording() async {
    _pressingRecord = false;
    if (!_isRecording) return;

    final viewOnce = _recordOnce;
    _recordingTicker?.cancel();
    final duration = DateTime.now().difference(
      _recordingStartedAt ?? DateTime.now(),
    );
    final path = await _audioRecorder.stop();
    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _isRecordingPaused = false;
      _recordOnce = false;
      _recordingDuration = Duration.zero;
      _recordingStartedAt = null;
      if (path != null) {
        _messages
            .add(_Message.voice(path, duration, 'Now', viewOnce: viewOnce));
      }
    });
  }

  Future<void> _cancelRecording() async {
    _pressingRecord = false;
    _recordingTicker?.cancel();
    if (_isRecording) await _audioRecorder.cancel();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isRecordingPaused = false;
        _recordOnce = false;
        _recordingDuration = Duration.zero;
        _recordingStartedAt = null;
      });
    }
  }

  void _showAttachmentMessage(String name) {
    setState(() => _showAttachments = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name picker will open here.')),
    );
  }

  Future<void> _toggleRecordingPause() async {
    if (!_isRecording) return;
    if (_isRecordingPaused) {
      await _audioRecorder.resume();
    } else {
      await _audioRecorder.pause();
    }
    if (mounted) setState(() => _isRecordingPaused = !_isRecordingPaused);
  }

  void _handleChatMenu(String selection) {
    switch (selection) {
      case 'theme':
        context.push('/chat/theme');
        return;
      case 'disappearing':
        context.push('/chat/disappearing');
        return;
      case 'more':
        _showMoreActions();
        return;
      case 'media':
        _showNotice(
            'Your shared media, links, and documents will appear here.');
        return;
      case 'search':
        showSearch<void>(
          context: context,
          delegate: _ChatMessageSearchDelegate(_messages),
        );
        return;
      case 'label':
        _showNotice('This talk can be organised with an Orbit label.');
        return;
    }
  }

  void _showMoreActions() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(170, 140, 18, 0),
      items: const [
        PopupMenuItem(value: 'clear', child: Text('Clear talk')),
        PopupMenuItem(value: 'export', child: Text('Export conversation')),
        PopupMenuItem(value: 'shortcut', child: Text('Add Talk shortcut')),
      ],
    ).then((value) {
      if (!mounted || value == null) return;
      if (value == 'clear') {
        setState(() => _messages.clear());
        _showNotice('Talk cleared from this device.');
      } else if (value == 'export') {
        _showNotice('Your conversation export is being prepared.');
      } else {
        _showNotice('Talk shortcut added.');
      }
    });
  }

  void _showMessageActions(_Message message) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(112, 126, 18, 0),
      items: const [
        PopupMenuItem(value: 'replies', child: Text('View thread')),
        PopupMenuItem(value: 'security', child: Text('Verify privacy code')),
        PopupMenuItem(value: 'keep', child: Text('Save to Keepsakes')),
        PopupMenuItem(value: 'copy', child: Text('Copy')),
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'pin', child: Text('Pin')),
        PopupMenuItem(value: 'note', child: Text('Add to note')),
        PopupMenuItem(value: 'reply', child: Text('Create quick reply')),
      ],
    ).then((value) {
      if (!mounted || value == null) return;
      setState(() => _selectedMessage = null);
      final label = switch (value) {
        'replies' => 'Thread opened',
        'security' => 'Privacy code is ready to verify',
        'keep' => 'Saved to Keepsakes',
        'copy' => 'Message copied',
        'edit' => 'Edit mode is ready',
        'pin' => 'Message pinned',
        'note' => 'Added to your note',
        _ => 'Quick reply created',
      };
      _showNotice(label);
    });
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectMessage(_Message message) {
    setState(() => _selectedMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            _selectedMessage == null
                ? _ChatHeader(onMenuSelected: _handleChatMenu)
                : _MessageSelectionBar(
                    onClose: () => setState(() => _selectedMessage = null),
                    onArchive: _archiveSelectedTalk,
                    onMore: () => _showMessageActions(_selectedMessage!),
                    onForward: () {
                      setState(() => _selectedMessage = null);
                      context.push('/chat/forward');
                    },
                  ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 16),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colors.surfaceContainerHighest
                            : colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('TODAY',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 11,
                                    letterSpacing: 1.1,
                                  )),
                    ),
                  ),
                  const SizedBox(height: 28),
                  for (final message in _messages)
                    _ChatBubble(
                      message: message,
                      isSelected: message == _selectedMessage,
                      onLongPress: message.isMine
                          ? () {}
                          : () => _selectMessage(message),
                    ),
                ],
              ),
            ),
            _ChatComposer(
              controller: _messageController,
              hasMessageText: _hasMessageText,
              showAttachments: _showAttachments,
              isRecording: _isRecording,
              isRecordingPaused: _isRecordingPaused,
              recordOnce: _recordOnce,
              recordingDuration: _recordingDuration,
              onToggleAttachments: () {
                if (!_isRecording) {
                  setState(() => _showAttachments = !_showAttachments);
                }
              },
              onAttachmentSelected: _showAttachmentMessage,
              onSend: _sendMessage,
              onRecordStart: _beginRecording,
              onRecordEnd: _finishRecording,
              onRecordCancel: _cancelRecording,
              onToggleRecordingPause: _toggleRecordingPause,
              onToggleRecordOnce: () =>
                  setState(() => _recordOnce = !_recordOnce),
            ),
          ],
        ),
      ),
    );
  }

  void _archiveSelectedTalk() {
    setState(() => _selectedMessage = null);
    _showNotice('This talk has been moved to your archived chats.');
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onMenuSelected});

  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to Talk',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 25,
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            child: const Text('J',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jack Wilson',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 19)),
                const SizedBox(height: 2),
                Text('Active now',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        )),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Call Jack',
            onPressed: () {},
            icon: Icon(Icons.call_outlined, color: colors.primary),
          ),
          IconButton(
            tooltip: 'Start video call',
            onPressed: () {},
            icon: Icon(Icons.videocam_outlined, color: colors.primary),
          ),
          PopupMenuButton<String>(
            tooltip: 'Talk options',
            color: colors.surface,
            surfaceTintColor: Colors.transparent,
            onSelected: onMenuSelected,
            icon: Icon(Icons.more_vert_rounded, color: colors.primary),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'label', child: Text('Label talk')),
              PopupMenuItem(value: 'media', child: Text('Media, links & docs')),
              PopupMenuItem(value: 'search', child: Text('Search in talk')),
              PopupMenuItem(
                  value: 'disappearing', child: Text('Disappearing messages')),
              PopupMenuItem(value: 'theme', child: Text('Talk theme')),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'more',
                child: Row(
                  children: [
                    Text('More'),
                    Spacer(),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageSelectionBar extends StatelessWidget {
  const _MessageSelectionBar({
    required this.onClose,
    required this.onArchive,
    required this.onMore,
    required this.onForward,
  });

  final VoidCallback onClose;
  final VoidCallback onArchive;
  final VoidCallback onMore;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 16),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Cancel selection',
            onPressed: onClose,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 14),
          Text('1', style: Theme.of(context).textTheme.headlineSmall),
          const Spacer(),
          IconButton(
              tooltip: 'Reply',
              onPressed: onClose,
              icon: const Icon(Icons.reply_rounded)),
          IconButton(
              tooltip: 'Message details',
              onPressed: onClose,
              icon: const Icon(Icons.info_outline_rounded)),
          IconButton(
              tooltip: 'Delete',
              onPressed: onClose,
              icon: const Icon(Icons.delete_outline_rounded)),
          IconButton(
              tooltip: 'Forward',
              onPressed: onForward,
              icon: const Icon(Icons.forward_rounded)),
          IconButton(
            tooltip: 'Archive talk',
            onPressed: onArchive,
            icon: const Icon(Icons.archive_outlined),
          ),
          IconButton(
            tooltip: 'Selected message actions',
            onPressed: onMore,
            icon: Icon(Icons.more_vert_rounded, color: color),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageSearchDelegate extends SearchDelegate<void> {
  _ChatMessageSearchDelegate(this.messages)
      : super(searchFieldLabel: 'Search in this talk');

  final List<_Message> messages;

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            tooltip: 'Clear search',
            onPressed: () => query = '',
            icon: const Icon(Icons.clear_rounded),
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        tooltip: 'Close search',
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back_rounded),
      );

  @override
  Widget buildResults(BuildContext context) => _matches(context);

  @override
  Widget buildSuggestions(BuildContext context) => _matches(context);

  Widget _matches(BuildContext context) {
    final matches = messages
        .where((message) =>
            message.text.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (matches.isEmpty) {
      return const Center(child: Text('No messages found.'));
    }
    return ListView.separated(
      itemCount: matches.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final message = matches[index];
        return ListTile(
          leading: Icon(
            message.isMine ? Icons.reply_rounded : Icons.person_outline_rounded,
          ),
          title: Text(message.text),
          subtitle: Text(message.time),
          onTap: () => close(context, null),
        );
      },
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.hasMessageText,
    required this.showAttachments,
    required this.isRecording,
    required this.isRecordingPaused,
    required this.recordOnce,
    required this.recordingDuration,
    required this.onToggleAttachments,
    required this.onAttachmentSelected,
    required this.onSend,
    required this.onRecordStart,
    required this.onRecordEnd,
    required this.onRecordCancel,
    required this.onToggleRecordingPause,
    required this.onToggleRecordOnce,
  });

  final TextEditingController controller;
  final bool hasMessageText;
  final bool showAttachments;
  final bool isRecording;
  final bool isRecordingPaused;
  final bool recordOnce;
  final Duration recordingDuration;
  final VoidCallback onToggleAttachments;
  final ValueChanged<String> onAttachmentSelected;
  final VoidCallback onSend;
  final Future<void> Function() onRecordStart;
  final Future<void> Function() onRecordEnd;
  final Future<void> Function() onRecordCancel;
  final Future<void> Function() onToggleRecordingPause;
  final VoidCallback onToggleRecordOnce;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAttachments)
              _AttachmentTray(onSelected: onAttachmentSelected),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  IconButton(
                    tooltip: showAttachments
                        ? 'Close attachments'
                        : 'Add attachment',
                    onPressed: onToggleAttachments,
                    style: IconButton.styleFrom(
                      backgroundColor: showAttachments
                          ? colors.primary
                          : colors.surfaceContainerHighest,
                    ),
                    icon: Icon(
                      showAttachments ? Icons.close_rounded : Icons.add_rounded,
                      color:
                          showAttachments ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: isRecording
                        ? _RecordingStatus(
                            duration: recordingDuration,
                            isPaused: isRecordingPaused,
                            viewOnce: recordOnce,
                            onDelete: onRecordCancel,
                            onTogglePause: onToggleRecordingPause,
                            onToggleViewOnce: onToggleRecordOnce,
                          )
                        : TextField(
                            controller: controller,
                            onSubmitted: (_) => onSend(),
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Write a message',
                              border: InputBorder.none,
                              filled: false,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: hasMessageText
                        ? IconButton.filled(
                            key: const ValueKey('send'),
                            tooltip: 'Send message',
                            onPressed: onSend,
                            icon: const Icon(Icons.send_rounded),
                          )
                        : GestureDetector(
                            key: const ValueKey('record'),
                            onTap: isRecording
                                ? onRecordEnd
                                : () => onRecordStart(),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isRecording
                                    ? colors.error.withValues(alpha: 0.16)
                                    : colors.secondary.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isRecording
                                    ? Icons.send_rounded
                                    : Icons.mic_rounded,
                                color: isRecording
                                    ? colors.error
                                    : colors.secondary,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingStatus extends StatelessWidget {
  const _RecordingStatus({
    required this.duration,
    required this.isPaused,
    required this.viewOnce,
    required this.onDelete,
    required this.onTogglePause,
    required this.onToggleViewOnce,
  });

  final Duration duration;
  final bool isPaused;
  final bool viewOnce;
  final VoidCallback onDelete;
  final Future<void> Function() onTogglePause;
  final VoidCallback onToggleViewOnce;

  @override
  Widget build(BuildContext context) {
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.fiber_manual_record_rounded,
                color: colors.error, size: 14),
            const SizedBox(width: 6),
            Text('$minutes:$seconds',
                style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            IconButton(
              tooltip:
                  viewOnce ? 'Voice note plays once' : 'Voice note can replay',
              onPressed: onToggleViewOnce,
              icon: Icon(
                  viewOnce
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: viewOnce ? colors.secondary : colors.onSurfaceVariant),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Delete voice note',
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, color: colors.error),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: onTogglePause,
                icon: Icon(
                    isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                label: Text(isPaused ? 'Resume' : 'Pause'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AttachmentTray extends StatelessWidget {
  const _AttachmentTray({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(
          children: [
            _AttachmentOption(
              icon: Icons.photo_camera_rounded,
              label: 'Camera',
              onTap: () => onSelected('Camera'),
            ),
            _AttachmentOption(
              icon: Icons.image_outlined,
              label: 'Media',
              onTap: () => onSelected('Media'),
            ),
            _AttachmentOption(
              icon: Icons.gif_box_outlined,
              label: 'GIF',
              onTap: () => onSelected('GIF'),
            ),
            _AttachmentOption(
              icon: Icons.description_outlined,
              label: 'Files',
              onTap: () => onSelected('Files'),
            ),
          ],
        ),
      );
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(height: 5),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isSelected,
    required this.onLongPress,
  });

  final _Message message;
  final bool isSelected;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = message.isMine
        ? colors.primary
        : (isDark ? colors.surfaceContainerHighest : colors.surface);
    final textColor = message.isMine ? colors.onPrimary : colors.onSurface;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        color: isSelected
            ? colors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        child: Align(
          alignment:
              message.isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                crossAxisAlignment: message.isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(message.isMine ? 20 : 5),
                        bottomRight: Radius.circular(message.isMine ? 5 : 20),
                      ),
                      border: message.isMine
                          ? null
                          : Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: message.isVoice
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic_rounded,
                                  color: textColor, size: 19),
                              const SizedBox(width: 8),
                              Text(message.formattedDuration,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: textColor)),
                              if (message.viewOnce) ...[
                                const SizedBox(width: 7),
                                Icon(Icons.visibility_rounded,
                                    color: textColor, size: 17),
                              ],
                            ],
                          )
                        : Text(message.text,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: textColor,
                                      height: 1.35,
                                    )),
                  ),
                  const SizedBox(height: 5),
                  Text(message.time,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                          )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message {
  const _Message(this.text, this.isMine, this.time,
      {this.audioPath, this.duration, this.viewOnce = false});

  _Message.voice(String path, Duration duration, String time,
      {bool viewOnce = false})
      : this('', true, time,
            audioPath: path, duration: duration, viewOnce: viewOnce);

  final String text;
  final bool isMine;
  final String time;
  final String? audioPath;
  final Duration? duration;
  final bool viewOnce;

  bool get isVoice => audioPath != null;

  String get formattedDuration {
    final value = duration ?? Duration.zero;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${value.inMinutes}:$seconds';
  }
}
