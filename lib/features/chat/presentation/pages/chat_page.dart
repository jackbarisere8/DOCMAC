import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/ui/docmac_community_icons.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/chat_message.dart';
import '../providers/chat_providers.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({
    super.key,
    this.chatId = 'jack',
    this.personName = 'Jack Wilson',
    this.personInitial = 'J',
    this.status = 'Active now',
  });

  /// Firestore `chats/{chatId}` document id. Threaded from Talk inbox
  /// (`TalkThread.chatId`) and the router (`/talk/person/:personId`,
  /// `/chat?person=`). Curated preview ids (`jack`, `emma`, …) match the
  /// Talk fallback so deep links stay stable before chats are provisioned.
  final String chatId;
  final String personName;
  final String personInitial;
  final String status;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();
  final _focusNode = FocusNode();

  /// Preview-mode outbox (signed out): provider stream is static curated
  /// data, so local sends append here instead of Firestore.
  final _previewOutbox = <ChatMessage>[];

  /// Voice notes are local-only in this preview (no audio field in
  /// `ChatMessage` / rules). They render inline with an on-device caption.
  final _voiceNotes = <_VoiceNote>[];

  /// Client-side hides for More → Clear (server history is immutable;
  /// rules deny deletes, so Clear only hides on this device).
  final _hiddenIds = <String>{};

  /// Read receipts already flipped this session (avoids update loops).
  final _markedRead = <String>{};

  Timer? _recordingTicker;
  DateTime? _recordingStartedAt;
  Duration _recordingDuration = Duration.zero;
  bool _hasMessageText = false;
  bool _showAttachments = false;
  bool _isRecording = false;
  bool _pressingRecord = false;
  bool _isRecordingPaused = false;
  bool _recordOnce = false;
  bool _sending = false;
  String? _selectedMessageId;
  String? _pinnedMessageId;
  String? _replyToText;

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
    _scrollController.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _updateComposer() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasMessageText && mounted) {
      setState(() => _hasMessageText = hasText);
    }
  }

  String? get _uid => ref.read(currentUserProvider)?.id;

  bool _isMine(ChatMessage message) {
    final uid = _uid;
    if (uid != null) return message.senderId == uid;
    return message.senderId == 'preview-me';
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    final uid = _uid;

    if (uid == null) {
      // Preview mode: no auth, so append locally and stay honest with the
      // banner above the composer ("Preview — sign in to sync").
      HapticFeedback.selectionClick();
      setState(() {
        _previewOutbox.add(ChatMessage(
          id: 'preview-local-${DateTime.now().millisecondsSinceEpoch}',
          chatId: widget.chatId,
          senderId: 'preview-me',
          text: text,
          createdAt: DateTime.now(),
        ));
        _messageController.clear();
        _showAttachments = false;
        _replyToText = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
      return;
    }

    setState(() => _sending = true);
    try {
      final repository = ref.read(chatRepositoryProvider);
      await repository.ensureChatExists(
        chatId: widget.chatId,
        currentUid: uid,
        peerName: widget.personName,
      );

      final message = ChatMessage(
        id: '${uid}_${DateTime.now().millisecondsSinceEpoch}',
        chatId: widget.chatId,
        senderId: uid,
        text: text,
        createdAt: DateTime.now(),
      );
      await repository.sendMessage(chatId: widget.chatId, message: message);
      if (!mounted) return;
      setState(() {
        _messageController.clear();
        _showAttachments = false;
        _replyToText = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Could not send. Check your connection and try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _sendMessage,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _markVisibleRead(List<ChatMessage> messages) {
    final uid = _uid;
    if (uid == null) return;
    for (final message in messages) {
      if (message.senderId != uid &&
          !message.isRead &&
          !_markedRead.contains(message.id)) {
        _markedRead.add(message.id);
        ref.read(chatRepositoryProvider).markAsRead(
              chatId: widget.chatId,
              messageId: message.id,
            ).catchError((_) => null);
      }
    }
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
        _voiceNotes.add(_VoiceNote(
          path: path,
          duration: duration,
          viewOnce: viewOnce,
          createdAt: DateTime.now(),
        ));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
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

  void _showAttachmentOptions() {
    setState(() => _showAttachments = false);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Attachments'),
        content: const Text(
          'Photos, GIFs and files arrive in a later update — text and '
          'voice notes work today. Voice notes stay on this device in '
          'this preview.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _beginRecording();
            },
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Record voice'),
          ),
        ],
      ),
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

  void _handleChatMenu(String selection, List<ChatMessage> messages) {
    switch (selection) {
      case 'theme':
        context.push('/chat/theme');
        return;
      case 'disappearing':
        context.push('/chat/disappearing');
        return;
      case 'more':
        _showMoreActions(messages);
        return;
      case 'media':
        _showMediaSheet(messages);
        return;
      case 'search':
        showSearch<void>(
          context: context,
          delegate: _ChatMessageSearchDelegate(messages, _uid),
        );
        return;
      case 'label':
        context.push('/orbit');
        return;
    }
  }

  void _showMediaSheet(List<ChatMessage> messages) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shared media',
                  style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                messages.isEmpty
                    ? 'Nothing shared here yet. Media, links and docs will live together once attachments land.'
                    : '${messages.length} text messages. Media, links and docs will live here once attachments land.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreActions(List<ChatMessage> messages) {
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
        _confirmClear(messages);
      } else if (value == 'export') {
        final transcript = messages
            .map((m) =>
                '[${_formatTime(m.createdAt)}] ${_isMine(m) ? 'You' : widget.personName}: ${m.text}')
            .join('\n');
        Clipboard.setData(ClipboardData(
          text: transcript.isEmpty ? '(empty talk)' : transcript,
        ));
        HapticFeedback.selectionClick();
      } else {
        Clipboard.setData(ClipboardData(text: widget.personName));
        HapticFeedback.selectionClick();
      }
    });
  }

  Future<void> _confirmClear(List<ChatMessage> messages) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear this talk?'),
        content: const Text(
          'Messages hide on this device only. Conversation history stays '
          'in Firestore (deletes are denied by security rules).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      setState(() {
        _hiddenIds.addAll(messages.map((m) => m.id));
        _selectedMessageId = null;
        _pinnedMessageId = null;
      });
    }
  }

  void _showMessageActions(ChatMessage message) {
    final isPinned = _pinnedMessageId == message.id;
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(112, 126, 18, 0),
      items: [
        const PopupMenuItem(value: 'copy', child: Text('Copy')),
        PopupMenuItem(value: 'pin', child: Text(isPinned ? 'Unpin' : 'Pin')),
        const PopupMenuItem(value: 'details', child: Text('Details')),
        const PopupMenuItem(value: 'forward', child: Text('Forward')),
      ],
    ).then((value) {
      if (!mounted || value == null) return;
      switch (value) {
        case 'pin':
          HapticFeedback.selectionClick();
          setState(() {
            _pinnedMessageId = isPinned ? null : message.id;
            _selectedMessageId = null;
          });
          return;
        case 'copy':
          Clipboard.setData(ClipboardData(text: message.text));
          HapticFeedback.selectionClick();
          setState(() => _selectedMessageId = null);
          return;
        case 'details':
          setState(() => _selectedMessageId = null);
          _showMessageDetails(message);
          return;
        case 'forward':
          setState(() => _selectedMessageId = null);
          context.push('/chat/forward');
          return;
      }
    });
  }

  void _showMessageDetails(ChatMessage message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Message details'),
        content: Text(
          'From: ${_isMine(message) ? 'You' : widget.personName}\n'
          'Sent: ${_formatTime(message.createdAt)}\n'
          'Status: ${message.isRead ? 'Read' : 'Sent'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _selectMessage(ChatMessage message) {
    HapticFeedback.selectionClick();
    setState(() => _selectedMessageId = message.id);
  }

  ChatMessage? _byId(List<ChatMessage> messages, String? id) {
    if (id == null) return null;
    for (final message in messages) {
      if (message.id == id) return message;
    }
    for (final local in _previewOutbox) {
      if (local.id == id) return local;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final preview = _uid == null;

    final fallback = curatedChatMessages(widget.chatId);
    final serverMessages = messagesAsync.valueOrNull ?? fallback;
    final visible = [
      ...serverMessages,
      ..._previewOutbox,
    ].where((m) => !_hiddenIds.contains(m.id)).toList();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _markVisibleRead(visible),
    );
    final selected = _byId(visible, _selectedMessageId);
    final pinned = _byId(visible, _pinnedMessageId);

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: SafeArea(
        child: _ChatBody(
          state: this,
          colors: colors,
          messages: visible,
          selected: selected,
          pinned: pinned,
          preview: preview,
          isLoading: messagesAsync.isLoading && !messagesAsync.hasValue,
          hasError: messagesAsync.hasError,
          onRetry: () => ref.invalidate(chatMessagesProvider(widget.chatId)),
        ),
      ),
    );
  }

  void _archiveSelectedTalk() {
    HapticFeedback.mediumImpact();
    setState(() => _selectedMessageId = null);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/talk');
    }
  }

  // Public selection/composer helpers for [_ChatBody] (calling `setState`
  // on another State object is illegal, so the body goes through these).
  void closeSelection() => setState(() => _selectedMessageId = null);

  void replyTo(ChatMessage message) {
    setState(() {
      _selectedMessageId = null;
      _replyToText = message.text;
    });
    _focusNode.requestFocus();
  }

  void showDetails(ChatMessage message) {
    setState(() => _selectedMessageId = null);
    _showMessageDetails(message);
  }

  void forwardSelected() {
    setState(() => _selectedMessageId = null);
    context.push('/chat/forward');
  }

  void openMessageActions(ChatMessage message) => _showMessageActions(message);

  void unpinMessage() => setState(() => _pinnedMessageId = null);

  void clearReply() => setState(() => _replyToText = null);

  void toggleAttachments() {
    if (!_isRecording) {
      setState(() => _showAttachments = !_showAttachments);
    }
  }

  void toggleRecordOnce() => setState(() => _recordOnce = !_recordOnce);

  void selectMessage(ChatMessage message) => _selectMessage(message);
}

class _ChatBody extends StatelessWidget {
  const _ChatBody({
    required this.state,
    required this.colors,
    required this.messages,
    required this.selected,
    required this.pinned,
    required this.preview,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
  });

  final _ChatPageState state;
  final ColorScheme colors;
  final List<ChatMessage> messages;
  final ChatMessage? selected;
  final ChatMessage? pinned;
  final bool preview;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final widget = state.widget;
    final sel = selected;
    final pin = pinned;
    return Column(
      children: [
        sel == null
            ? _ChatHeader(
                name: widget.personName,
                initial: widget.personInitial,
                status: widget.status,
                onMenuSelected: (value) =>
                    state._handleChatMenu(value, messages),
              )
            : _MessageSelectionBar(
                onClose: state.closeSelection,
                onReply: () => state.replyTo(sel),
                onDetails: () => state.showDetails(sel),
                onDelete: () {
                  state.closeSelection();
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete message?'),
                      content: const Text(
                        'Messages cannot be deleted — Firestore rules keep '
                        'conversation history immutable. Clear the talk from '
                        'More → Clear to hide it on this device.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                },
                onForward: state.forwardSelected,
                onArchive: state._archiveSelectedTalk,
                onMore: () => state.openMessageActions(sel),
              ),
        Divider(height: 1, color: Theme.of(context).dividerColor),
        if (hasError)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: 18, color: colors.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Could not load messages. Showing preview.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          fontSize: 12.5,
                          color: colors.onErrorContainer,
                        ),
                  ),
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        if (preview && !hasError)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: colors.primaryContainer.withValues(alpha: .5),
            child: Text(
              'Preview — sign in to sync talks.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
          ),
        if (pin != null)
          _PinnedMessageRail(
            message: pin,
            isMine: state._isMine(pin),
            time: state._formatTime(pin.createdAt),
            onUnpin: state.unpinMessage,
          ),
        Expanded(
          child: isLoading && messages.isEmpty
              ? const _ChatLoadingList()
              : (messages.isEmpty && state._voiceNotes.isEmpty
                  ? _ChatEmptyState(name: widget.personName)
                  : ListView(
                      controller: state._scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? colors.surfaceContainerHighest
                                  : colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('TODAY',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      fontSize: 11,
                                      letterSpacing: 1.1,
                                    )),
                          ),
                        ),
                        const SizedBox(height: 24),
                        for (final message in messages)
                          _ChatBubble(
                            message: message,
                            isMine: state._isMine(message),
                            time: state._formatTime(message.createdAt),
                            isSelected:
                                message.id == state._selectedMessageId,
                            onLongPress: () =>
                                state._selectMessage(message),
                          ),
                        for (final voice in state._voiceNotes)
                          _VoiceBubble(note: voice),
                      ],
                    )),
        ),
        if (state._replyToText != null)
          _ReplyStrip(
            text: state._replyToText!,
            onClose: state.clearReply,
          ),
        _ChatComposer(
          controller: state._messageController,
          focusNode: state._focusNode,
          hasMessageText: state._hasMessageText,
          showAttachments: state._showAttachments,
          isRecording: state._isRecording,
          isRecordingPaused: state._isRecordingPaused,
          recordOnce: state._recordOnce,
          recordingDuration: state._recordingDuration,
          sending: state._sending,
          onToggleAttachments: state.toggleAttachments,
          onAttachmentSelected: (_) => state._showAttachmentOptions(),
          onSend: state._sendMessage,
          onRecordStart: state._beginRecording,
          onRecordEnd: state._finishRecording,
          onRecordCancel: state._cancelRecording,
          onToggleRecordingPause: state._toggleRecordingPause,
          onToggleRecordOnce: state.toggleRecordOnce,
        ),
      ],
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.forum_outlined,
                  size: 34, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 18),
            Text('No messages yet',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 7),
            Text(
              'Say hello to $name — messages sync in real time.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatLoadingList extends StatefulWidget {
  const _ChatLoadingList();

  @override
  State<_ChatLoadingList> createState() => _ChatLoadingListState();
}

class _ChatLoadingListState extends State<_ChatLoadingList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final opacity = 0.35 + (_shimmerController.value * 0.45);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 16),
          children: List.generate(
            3,
            (index) => Align(
              alignment:
                  index.isEven ? Alignment.centerLeft : Alignment.centerRight,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: index == 1 ? 260 : 200,
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.name,
    required this.initial,
    required this.status,
    required this.onMenuSelected,
  });

  final String name;
  final String initial;
  final String status;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to talks',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/talk');
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 25,
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            child: Text(initial,
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 19)),
                const SizedBox(height: 2),
                Text(status,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        )),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Call $name',
            onPressed: () => context
                .push('/live/call/${name.toLowerCase().split(' ').first}'),
            icon: Icon(Icons.call_outlined, color: colors.primary),
          ),
          IconButton(
            tooltip: 'Start video call',
            onPressed: () => context
                .push('/live/call/${name.toLowerCase().split(' ').first}'),
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
    required this.onReply,
    required this.onDetails,
    required this.onDelete,
    required this.onForward,
    required this.onArchive,
    required this.onMore,
  });

  final VoidCallback onClose;
  final VoidCallback onReply;
  final VoidCallback onDetails;
  final VoidCallback onDelete;
  final VoidCallback onForward;
  final VoidCallback onArchive;
  final VoidCallback onMore;

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
              onPressed: onReply,
              icon: const Icon(Icons.reply_rounded)),
          IconButton(
              tooltip: 'Message details',
              onPressed: onDetails,
              icon: const Icon(Icons.info_outline_rounded)),
          IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
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

class _ReplyStrip extends StatelessWidget {
  const _ReplyStrip({required this.text, required this.onClose});

  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .5),
        border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageSearchDelegate extends SearchDelegate<void> {
  _ChatMessageSearchDelegate(this.messages, this.uid)
      : super(searchFieldLabel: 'Search in this talk');

  final List<ChatMessage> messages;
  final String? uid;

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
        final mine = uid != null
            ? message.senderId == uid
            : message.senderId == 'preview-me';
        return ListTile(
          leading: Icon(
            mine ? Icons.reply_rounded : Icons.person_outline_rounded,
          ),
          title: Text(message.text),
          subtitle: Text(
            '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
          ),
          onTap: () => close(context, null),
        );
      },
    );
  }
}

/// Keeps the conversation's pinned message in view without interrupting the
/// natural chronology of the chat itself.
class _PinnedMessageRail extends StatelessWidget {
  const _PinnedMessageRail({
    required this.message,
    required this.isMine,
    required this.time,
    required this.onUnpin,
  });

  final ChatMessage message;
  final bool isMine;
  final String time;
  final VoidCallback onUnpin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DocmacCommunityIcon(
                asset: DocmacCommunityIcons.talkPin,
                size: 20,
                color: colors.onPrimaryContainer,
                semanticLabel: 'Pinned message',
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pinned message',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Unpin message',
              onPressed: onUnpin,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.hasMessageText,
    required this.showAttachments,
    required this.isRecording,
    required this.isRecordingPaused,
    required this.recordOnce,
    required this.recordingDuration,
    required this.sending,
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
  final FocusNode focusNode;
  final bool hasMessageText;
  final bool showAttachments;
  final bool isRecording;
  final bool isRecordingPaused;
  final bool recordOnce;
  final Duration recordingDuration;
  final bool sending;
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
                      backgroundColor:
                          showAttachments ? colors.primary : Colors.transparent,
                    ),
                    icon: Icon(
                      showAttachments ? Icons.close_rounded : Icons.add_rounded,
                      color:
                          showAttachments ? colors.onPrimary : colors.onSurface,
                      size: 26,
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
                            focusNode: focusNode,
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
                            key: const ValueKey('talk-send-message'),
                            tooltip: 'Send message',
                            onPressed: sending ? null : onSend,
                            icon: sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
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
                                    : colors.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isRecording
                                    ? Icons.send_rounded
                                    : Icons.mic_rounded,
                                color:
                                    isRecording ? colors.error : colors.primary,
                                size: 22,
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
    required this.isMine,
    required this.time,
    required this.isSelected,
    required this.onLongPress,
  });

  final ChatMessage message;
  final bool isMine;
  final String time;
  final bool isSelected;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isMine
        ? colors.primary
        : (isDark ? colors.surfaceContainerHighest : colors.surface);
    final textColor = isMine ? colors.onPrimary : colors.onSurface;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        color: isSelected
            ? colors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                crossAxisAlignment: isMine
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
                        bottomLeft: Radius.circular(isMine ? 20 : 5),
                        bottomRight: Radius.circular(isMine ? 5 : 20),
                      ),
                      border: isMine
                          ? null
                          : Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(message.text,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: textColor,
                                  height: 1.35,
                                )),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontSize: 11,
                              )),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          color: message.isRead
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ],
                    ],
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

class _VoiceNote {
  _VoiceNote({
    required this.path,
    required this.duration,
    required this.viewOnce,
    required this.createdAt,
  });

  final String path;
  final Duration duration;
  final bool viewOnce;
  final DateTime createdAt;
}

class _VoiceBubble extends StatelessWidget {
  const _VoiceBubble({required this.note});

  final _VoiceNote note;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final seconds =
        note.duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic_rounded,
                        color: colors.onPrimary, size: 19),
                    const SizedBox(width: 8),
                    Text('${note.duration.inMinutes}:$seconds',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: colors.onPrimary)),
                    if (note.viewOnce) ...[
                      const SizedBox(width: 7),
                      Icon(Icons.visibility_rounded,
                          color: colors.onPrimary, size: 17),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text('On this device',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
