import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:docmac_app/features/chat/presentation/pages/chat_page.dart';

import '../../data/talk_thread.dart';
import '../providers/talk_providers.dart';

/// Talk inbox. Threads stream from [talkThreadsProvider] (Firestore `chats`
/// where the uid is a participant, otherwise [curatedTalkThreads] preview).
/// Pin/archive/mute/lock/favorite persist in SharedPreferences keyed by
/// stable thread id (same pattern as `privacy_page.dart`).
class TalkPage extends ConsumerStatefulWidget {
  const TalkPage({super.key});

  @override
  ConsumerState<TalkPage> createState() => _TalkPageState();
}

class _TalkPageState extends ConsumerState<TalkPage> {
  static const _pinnedKey = 'docmac_talk_pinned';
  static const _archivedKey = 'docmac_talk_archived';
  static const _mutedKey = 'docmac_talk_muted';
  static const _unreadKey = 'docmac_talk_marked_unread';
  static const _favoritesKey = 'docmac_talk_favorites';
  static const _removedFavoritesKey = 'docmac_talk_removed_favorites';
  static const _lockedKey = 'docmac_talk_locked';
  static const _clearedKey = 'docmac_talk_cleared';

  var _filterIndex = 0;
  var _query = '';
  TalkThread? _selectedThread;
  final _archivedTalks = <String>{};
  final _pinnedTalks = <String>{};
  final _mutedTalks = <String>{};
  final _markedUnreadTalks = <String>{};
  final _favoriteTalks = <String>{};
  final _removedFavoriteTalks = <String>{};
  final _lockedTalks = <String>{};
  final _clearedTalks = <String>{};

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pinnedTalks
        ..clear()
        ..addAll(preferences.getStringList(_pinnedKey) ?? const <String>[]);
      _archivedTalks
        ..clear()
        ..addAll(preferences.getStringList(_archivedKey) ?? const <String>[]);
      _mutedTalks
        ..clear()
        ..addAll(preferences.getStringList(_mutedKey) ?? const <String>[]);
      _markedUnreadTalks
        ..clear()
        ..addAll(preferences.getStringList(_unreadKey) ?? const <String>[]);
      _favoriteTalks
        ..clear()
        ..addAll(preferences.getStringList(_favoritesKey) ?? const <String>[]);
      _removedFavoriteTalks
        ..clear()
        ..addAll(
            preferences.getStringList(_removedFavoritesKey) ?? const <String>[]);
      _lockedTalks
        ..clear()
        ..addAll(preferences.getStringList(_lockedKey) ?? const <String>[]);
      _clearedTalks
        ..clear()
        ..addAll(preferences.getStringList(_clearedKey) ?? const <String>[]);
    });
  }

  Future<void> _persist(String key, Set<String> values) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(key, values.toList(growable: false));
  }

  List<TalkThread> _visibleThreads(List<TalkThread> all) {
    Iterable<TalkThread> threads =
        all.where((thread) => !_archivedTalks.contains(thread.id));
    switch (_filterIndex) {
      case 1:
        threads = threads.where(_hasUnreadActivity);
        break;
      case 2:
        threads = threads.where((thread) => thread.isGroup);
        break;
      case 3:
        threads = threads.where(_isFavorite);
        break;
    }

    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      threads = threads.where(
        (thread) =>
            thread.name.toLowerCase().contains(query) ||
            thread.preview.toLowerCase().contains(query),
      );
    }
    final visibleThreads = threads.toList(growable: false);
    visibleThreads.sort((first, second) {
      final firstPinned = _pinnedTalks.contains(first.id);
      final secondPinned = _pinnedTalks.contains(second.id);
      if (firstPinned == secondPinned) return 0;
      return firstPinned ? -1 : 1;
    });
    return visibleThreads;
  }

  int _effectiveUnread(TalkThread thread) {
    if (_clearedTalks.contains(thread.id)) return 0;
    return thread.unread;
  }

  bool _hasUnreadActivity(TalkThread thread) {
    if (_markedUnreadTalks.contains(thread.id)) return true;
    if (_clearedTalks.contains(thread.id)) return false;
    return _effectiveUnread(thread) > 0 || thread.hasNewActivity;
  }

  bool _isFavorite(TalkThread thread) =>
      (thread.isSaved && !_removedFavoriteTalks.contains(thread.id)) ||
      _favoriteTalks.contains(thread.id);

  int _totalUnread(List<TalkThread> threads) {
    var total = 0;
    for (final thread in threads) {
      total += _effectiveUnread(thread);
      if (_effectiveUnread(thread) == 0 &&
          _markedUnreadTalks.contains(thread.id)) {
        total += 1;
      }
    }
    return total;
  }

  Future<void> _openConversation(TalkThread thread) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: thread.chatId,
          personName: thread.name,
          personInitial: thread.initial,
          status: thread.isOnline ? 'Active now' : 'Last active recently',
        ),
      ),
    );
  }

  void _showNewTalkPicker(List<TalkThread> recent) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Start a talk',
                  style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Choose someone from your recent conversations.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final thread in recent.take(3))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _Avatar(thread: thread, size: 42),
                  title: Text(thread.name),
                  onTap: () {
                    Navigator.of(sheetContext, rootNavigator: true).pop();
                    _openConversation(thread);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openArchivedTalks(List<TalkThread> all) async {
    final archived = all
        .where((thread) => _archivedTalks.contains(thread.id))
        .toList(growable: false);
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => _ArchivedTalksPage(
          threads: archived,
          onOpen: (thread) => _openConversation(thread),
          onUnarchive: (thread) {
            setState(() => _archivedTalks.remove(thread.id));
            _persist(_archivedKey, _archivedTalks);
            HapticFeedback.selectionClick();
          },
        ),
      ),
    );
  }

  void _showCameraOptions(List<TalkThread> recent) {
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
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                subtitle: const Text('Pick a talk first, then share'),
                onTap: () {
                  Navigator.of(sheetContext, rootNavigator: true).pop();
                  _showNewTalkPicker(recent);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Start a video talk'),
                subtitle: const Text('Schedule a signal with your people'),
                onTap: () {
                  Navigator.of(sheetContext, rootNavigator: true).pop();
                  context.push('/live/schedule');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTalkMenu(String action, List<TalkThread> visible) {
    switch (action) {
      case 'new':
        _showNewTalkPicker(visible);
        break;
      case 'archive':
        final all = ref.read(talkThreadsProvider).valueOrNull ?? curatedTalkThreads;
        _openArchivedTalks(all);
        break;
      case 'circle':
        context.push('/spaces/new');
        break;
      case 'select':
        if (visible.isNotEmpty) {
          HapticFeedback.selectionClick();
          setState(() => _selectedThread = visible.first);
        }
        break;
      case 'settings':
        context.push('/settings');
        break;
    }
  }

  void _selectThread(TalkThread thread) {
    HapticFeedback.selectionClick();
    setState(() => _selectedThread = thread);
  }

  void _togglePinnedSelectedThread() {
    final thread = _selectedThread;
    if (thread == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!_pinnedTalks.add(thread.id)) _pinnedTalks.remove(thread.id);
    });
    _persist(_pinnedKey, _pinnedTalks);
  }

  void _toggleMutedSelectedThread() {
    final thread = _selectedThread;
    if (thread == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!_mutedTalks.add(thread.id)) _mutedTalks.remove(thread.id);
    });
    _persist(_mutedKey, _mutedTalks);
  }

  Future<void> _confirmDestructive({
    required String title,
    required String body,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  void _openContact(TalkThread thread) {
    // Groups resolve to their Space; 1:1 talks resolve to the person space.
    // Firestore chat ids that are not person slugs fall back to the
    // capitalised-id route handled by `_personInfo` in the router.
    if (thread.isGroup) {
      context.push('/spaces/info');
    } else {
      context.push('/person/${thread.id}');
    }
  }

  void _completeThreadAction(
    TalkThread thread,
    String action,
    List<TalkThread> visible,
  ) {
    switch (action) {
      case 'pin':
        HapticFeedback.selectionClick();
        setState(() {
          if (!_pinnedTalks.add(thread.id)) _pinnedTalks.remove(thread.id);
        });
        _persist(_pinnedKey, _pinnedTalks);
        break;
      case 'archive':
        HapticFeedback.mediumImpact();
        setState(() {
          _archivedTalks.add(thread.id);
          if (_selectedThread?.id == thread.id) _selectedThread = null;
        });
        _persist(_archivedKey, _archivedTalks);
        break;
      case 'shortcut':
        HapticFeedback.selectionClick();
        Clipboard.setData(ClipboardData(text: thread.name));
        break;
      case 'mute':
        HapticFeedback.selectionClick();
        setState(() {
          if (!_mutedTalks.add(thread.id)) _mutedTalks.remove(thread.id);
        });
        _persist(_mutedKey, _mutedTalks);
        break;
      case 'unread':
        HapticFeedback.selectionClick();
        setState(() {
          _markedUnreadTalks.add(thread.id);
          _clearedTalks.remove(thread.id);
        });
        _persist(_unreadKey, _markedUnreadTalks);
        _persist(_clearedKey, _clearedTalks);
        break;
      case 'contact':
        _openContact(thread);
        break;
      case 'all':
        HapticFeedback.selectionClick();
        setState(() {
          for (final item in visible) {
            _markedUnreadTalks.add(item.id);
          }
        });
        _persist(_unreadKey, _markedUnreadTalks);
        break;
      case 'lock':
        HapticFeedback.selectionClick();
        setState(() {
          if (!_lockedTalks.add(thread.id)) _lockedTalks.remove(thread.id);
        });
        _persist(_lockedKey, _lockedTalks);
        break;
      case 'favorite':
        HapticFeedback.selectionClick();
        setState(() {
          if (_isFavorite(thread)) {
            _favoriteTalks.remove(thread.id);
            _removedFavoriteTalks.add(thread.id);
          } else {
            _removedFavoriteTalks.remove(thread.id);
            _favoriteTalks.add(thread.id);
          }
        });
        _persist(_favoritesKey, _favoriteTalks);
        _persist(_removedFavoritesKey, _removedFavoriteTalks);
        break;
      case 'clear':
        _confirmDestructive(
          title: 'Clear this talk?',
          body:
              'Unread badges for ${thread.name} will be cleared on this device. Messages stay in Firestore.',
          confirmLabel: 'Clear',
          onConfirm: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _clearedTalks.add(thread.id);
              _markedUnreadTalks.remove(thread.id);
              if (_selectedThread?.id == thread.id) _selectedThread = null;
            });
            _persist(_clearedKey, _clearedTalks);
            _persist(_unreadKey, _markedUnreadTalks);
          },
        );
        break;
      case 'block':
        _confirmDestructive(
          title: 'Block ${thread.name}?',
          body:
              'The talk moves to archived and its notifications are muted. You can unarchive it later.',
          confirmLabel: 'Block',
          onConfirm: () {
            HapticFeedback.heavyImpact();
            setState(() {
              _archivedTalks.add(thread.id);
              _mutedTalks.add(thread.id);
              if (_selectedThread?.id == thread.id) _selectedThread = null;
            });
            _persist(_archivedKey, _archivedTalks);
            _persist(_mutedKey, _mutedTalks);
          },
        );
        break;
    }
  }

  void _showSearchFilters() {
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
              Text('Refine talks',
                  style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('Choose the conversations you want to see.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium),
              const SizedBox(height: 14),
              for (final filter in const [
                (0, 'All talks', Icons.forum_outlined),
                (1, 'Unread', Icons.mark_chat_unread_outlined),
                (2, 'Circles', Icons.groups_outlined),
                (3, 'Saved', Icons.bookmark_border_rounded),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(filter.$3),
                  title: Text(filter.$2),
                  trailing: _filterIndex == filter.$1
                      ? Icon(Icons.check_rounded,
                          color: Theme.of(sheetContext).colorScheme.primary)
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _filterIndex = filter.$1);
                    Navigator.of(sheetContext, rootNavigator: true).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final threadsAsync = ref.watch(talkThreadsProvider);
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
            if (_selectedThread == null)
              _InboxHeader(
                onCamera: () {
                  final all = threadsAsync.valueOrNull ?? curatedTalkThreads;
                  _showCameraOptions(_visibleThreads(all));
                },
                onMenu: (action) {
                  final all = threadsAsync.valueOrNull ?? curatedTalkThreads;
                  _handleTalkMenu(action, _visibleThreads(all));
                },
              )
            else
              _TalkSelectionHeader(
                isPinned: _pinnedTalks.contains(_selectedThread!.id),
                isMuted: _mutedTalks.contains(_selectedThread!.id),
                isLocked: _lockedTalks.contains(_selectedThread!.id),
                isFavorite: _isFavorite(_selectedThread!),
                onClose: () => setState(() => _selectedThread = null),
                onPin: _togglePinnedSelectedThread,
                onMute: _toggleMutedSelectedThread,
                onViewContact: () => _openContact(_selectedThread!),
                onClear: () {
                  final all =
                      threadsAsync.valueOrNull ?? curatedTalkThreads;
                  _completeThreadAction(
                    _selectedThread!,
                    'clear',
                    _visibleThreads(all),
                  );
                },
                onAction: (action) {
                  final all =
                      threadsAsync.valueOrNull ?? curatedTalkThreads;
                  _completeThreadAction(
                    _selectedThread!,
                    action,
                    _visibleThreads(all),
                  );
                },
              ),
            const SizedBox(height: 18),
            _TalkSearch(
              onChanged: (value) => setState(() => _query = value),
              onFilterTap: _showSearchFilters,
            ),
            const SizedBox(height: 16),
            _FilterRow(
              filterIndex: _filterIndex,
              unreadCount: _totalUnread(
                _visibleThreads(threadsAsync.valueOrNull ?? curatedTalkThreads),
              ),
              onSelect: (index) {
                HapticFeedback.selectionClick();
                setState(() => _filterIndex = index);
              },
            ),
            const SizedBox(height: 18),
            threadsAsync.when(
              data: (all) =>
                  _InboxBody(threads: _visibleThreads(all), state: this),
              loading: () => const _TalkLoadingList(),
              error: (error, _) => _TalkErrorBody(
                onRetry: () => ref.invalidate(talkThreadsProvider),
                fallback: _visibleThreads(curatedTalkThreads),
                state: this,
              ),
            ),
            const SizedBox(height: 18),
            _PrivacyNote(colorScheme: scheme),
          ],
        ),
      ),
    );
  }

  String _conversationCount(int count) =>
      '$count ${count == 1 ? 'conversation' : 'conversations'}';
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader({required this.onCamera, required this.onMenu});

  final VoidCallback onCamera;
  final ValueChanged<String> onMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text('Talk', style: textTheme.headlineLarge)),
        IconButton(
          tooltip: 'Camera',
          onPressed: onCamera,
          icon: Icon(Icons.camera_alt_outlined, color: scheme.onSurface),
        ),
        PopupMenuButton<String>(
          tooltip: 'Talk options',
          onSelected: onMenu,
          offset: const Offset(0, 48),
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: const Icon(Icons.more_vert_rounded),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'new',
              height: 52,
              child: _TalkMenuRow(
                icon: Icons.edit_square,
                label: 'New talk',
              ),
            ),
            PopupMenuItem(
              value: 'circle',
              height: 52,
              child: _TalkMenuRow(
                icon: Icons.groups_outlined,
                label: 'New circle',
              ),
            ),
            PopupMenuItem(
              value: 'archive',
              height: 52,
              child: _TalkMenuRow(
                icon: Icons.archive_outlined,
                label: 'Archived talks',
              ),
            ),
            PopupMenuItem(
              value: 'select',
              height: 52,
              child: _TalkMenuRow(
                icon: Icons.checklist_rounded,
                label: 'Select talks',
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              height: 52,
              child: _TalkMenuRow(
                icon: Icons.tune_rounded,
                label: 'Talk settings',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filterIndex,
    required this.unreadCount,
    required this.onSelect,
  });

  final int filterIndex;
  final int unreadCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterPill(
              label: 'All talks',
              active: filterIndex == 0,
              onTap: () => onSelect(0)),
          const SizedBox(width: 8),
          _FilterPill(
              label: 'Unread',
              count: unreadCount > 0 ? '$unreadCount' : null,
              active: filterIndex == 1,
              onTap: () => onSelect(1)),
          const SizedBox(width: 8),
          _FilterPill(
              label: 'Circles',
              active: filterIndex == 2,
              onTap: () => onSelect(2)),
          const SizedBox(width: 8),
          _FilterPill(
              label: 'Saved',
              active: filterIndex == 3,
              onTap: () => onSelect(3)),
        ],
      ),
    );
  }
}

class _InboxBody extends StatelessWidget {
  const _InboxBody({required this.threads, required this.state});

  final List<TalkThread> threads;
  final _TalkPageState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state._archivedTalks.isNotEmpty) ...[
          _ArchiveEntry(
            archivedCount: state._archivedTalks.length,
            onTap: () => state._openArchivedTalks(
              state.ref.read(talkThreadsProvider).valueOrNull ??
                  curatedTalkThreads,
            ),
          ),
          const SizedBox(height: 22),
        ] else
          const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Inbox', style: textTheme.headlineSmall),
            Text(state._conversationCount(threads.length),
                style: textTheme.bodyMedium?.copyWith(fontSize: 12.5)),
          ],
        ),
        const SizedBox(height: 14),
        _ThreadCard(
          threads: threads,
          onOpen: state._openConversation,
          onLongPress: state._selectThread,
          isPinned: (thread) => state._pinnedTalks.contains(thread.id),
          isMuted: (thread) => state._mutedTalks.contains(thread.id),
          hasUnreadActivity: state._hasUnreadActivity,
          effectiveUnread: state._effectiveUnread,
        ),
      ],
    );
  }
}

class _TalkLoadingList extends StatelessWidget {
  const _TalkLoadingList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Inbox', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 13,
                            width: 120,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer
                                  .withValues(alpha: .6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            height: 11,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: .7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TalkErrorBody extends StatelessWidget {
  const _TalkErrorBody({
    required this.onRetry,
    required this.fallback,
    required this.state,
  });

  final VoidCallback onRetry;
  final List<TalkThread> fallback;
  final _TalkPageState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Could not load talks. Showing your saved preview.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onErrorContainer),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _InboxBody(threads: fallback, state: state),
      ],
    );
  }
}

class _TalkSelectionHeader extends StatelessWidget {
  const _TalkSelectionHeader({
    required this.isPinned,
    required this.isMuted,
    required this.isLocked,
    required this.isFavorite,
    required this.onClose,
    required this.onPin,
    required this.onMute,
    required this.onViewContact,
    required this.onClear,
    required this.onAction,
  });

  final bool isPinned;
  final bool isMuted;
  final bool isLocked;
  final bool isFavorite;
  final VoidCallback onClose;
  final VoidCallback onPin;
  final VoidCallback onMute;
  final VoidCallback onViewContact;
  final VoidCallback onClear;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          tooltip: 'Cancel selection',
          onPressed: onClose,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 6),
        Text('1', style: Theme.of(context).textTheme.headlineSmall),
        const Spacer(),
        IconButton(
          tooltip: 'View contact',
          onPressed: onViewContact,
          icon: Icon(Icons.contact_page_outlined, color: scheme.onSurface),
        ),
        IconButton(
          tooltip: isPinned ? 'Unpin talk' : 'Pin talk',
          onPressed: onPin,
          icon: Icon(
            isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
            color: scheme.onSurface,
          ),
        ),
        IconButton(
          tooltip: 'Clear chat',
          onPressed: onClear,
          icon: Icon(Icons.delete_outline_rounded, color: scheme.onSurface),
        ),
        IconButton(
          tooltip: isMuted ? 'Unmute notifications' : 'Mute notifications',
          onPressed: onMute,
          icon: Icon(
            isMuted
                ? Icons.notifications_outlined
                : Icons.notifications_off_outlined,
            color: scheme.onSurface,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Selected talk actions',
          onSelected: onAction,
          icon: Icon(Icons.more_vert_rounded, color: scheme.onSurface),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'archive', child: Text('Archive chat')),
            const PopupMenuItem(
                value: 'shortcut', child: Text('Add chat shortcut')),
            const PopupMenuItem(value: 'contact', child: Text('View contact')),
            const PopupMenuItem(value: 'unread', child: Text('Mark as unread')),
            const PopupMenuItem(value: 'all', child: Text('Select all')),
            PopupMenuItem(
              value: 'lock',
              child: Text(isLocked ? 'Unlock chat' : 'Lock chat'),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'favorite',
              child: Text(
                  isFavorite ? 'Remove from favorites' : 'Add to favorites'),
            ),
            const PopupMenuItem(value: 'clear', child: Text('Clear chat')),
            const PopupMenuItem(value: 'block', child: Text('Block')),
          ],
        ),
      ],
    );
  }
}

class _TalkMenuRow extends StatelessWidget {
  const _TalkMenuRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 13),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _ArchiveEntry extends StatelessWidget {
  const _ArchiveEntry({required this.archivedCount, required this.onTap});

  final int archivedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = archivedCount == 0
        ? 'No archived talks'
        : '$archivedCount ${archivedCount == 1 ? 'archived talk' : 'archived talks'}';
    return Semantics(
      button: true,
      label: 'Open archived talks, $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: .58),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.primary.withValues(alpha: .16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.archive_outlined, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Archived',
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 2),
                      Text(label,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: scheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchivedTalksPage extends StatefulWidget {
  const _ArchivedTalksPage({
    required this.threads,
    required this.onOpen,
    required this.onUnarchive,
  });

  final List<TalkThread> threads;
  final ValueChanged<TalkThread> onOpen;
  final ValueChanged<TalkThread> onUnarchive;

  @override
  State<_ArchivedTalksPage> createState() => _ArchivedTalksPageState();
}

class _ArchivedTalksPageState extends State<_ArchivedTalksPage> {
  late final List<TalkThread> _threads;

  @override
  void initState() {
    super.initState();
    _threads = List.of(widget.threads);
  }

  void _unarchive(TalkThread thread) {
    widget.onUnarchive(thread);
    setState(() => _threads.remove(thread));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Archived'),
        leading: IconButton(
          tooltip: 'Back to Talk',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: _threads.isEmpty
          ? _ArchivedEmptyState(onBack: () => Navigator.of(context).pop())
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: _threads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final thread = _threads[index];
                return Material(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    leading: _Avatar(thread: thread),
                    title: Text(thread.name),
                    subtitle: Text(thread.preview, maxLines: 1),
                    onTap: () => widget.onOpen(thread),
                    trailing: IconButton(
                      tooltip: 'Unarchive ${thread.name}',
                      onPressed: () => _unarchive(thread),
                      icon: const Icon(Icons.unarchive_outlined),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ArchivedEmptyState extends StatelessWidget {
  const _ArchivedEmptyState({required this.onBack});

  final VoidCallback onBack;

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
              child: Icon(Icons.archive_outlined,
                  size: 34, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 18),
            Text('Your archive is clear',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 7),
            Text(
              'Archived talks stay here until you bring them back to your inbox.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Talk'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TalkSearch extends StatefulWidget {
  const _TalkSearch({required this.onChanged, required this.onFilterTap});

  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  State<_TalkSearch> createState() => _TalkSearchState();
}

class _TalkSearchState extends State<_TalkSearch> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
    _focusNode.addListener(_refresh);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _focusNode
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focused = _focusNode.hasFocus;
    final hasQuery = _controller.text.isNotEmpty;
    return Semantics(
      textField: true,
      label: 'Search talks',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: focused ? scheme.primary : Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search talks, people and moments',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: hasQuery
                  ? IconButton(
                      key: const ValueKey('clear-talk-search'),
                      tooltip: 'Clear search',
                      onPressed: _clear,
                      icon: const Icon(Icons.close_rounded, size: 19),
                    )
                  : IconButton(
                      key: const ValueKey('refine-talk-search'),
                      tooltip: 'Refine talks',
                      onPressed: widget.onFilterTap,
                      icon: Icon(Icons.tune_rounded,
                          size: 19, color: scheme.onSurfaceVariant),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill(
      {required this.label,
      required this.active,
      required this.onTap,
      this.count});

  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: active,
      label: '$label filter',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color:
                    active ? scheme.primary : Theme.of(context).dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? scheme.onPrimary : scheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: active
                        ? scheme.onPrimary.withValues(alpha: .22)
                        : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count!,
                    style: TextStyle(
                      color:
                          active ? scheme.onPrimary : scheme.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({
    required this.threads,
    required this.onOpen,
    required this.onLongPress,
    required this.isPinned,
    required this.isMuted,
    required this.hasUnreadActivity,
    required this.effectiveUnread,
  });

  final List<TalkThread> threads;
  final ValueChanged<TalkThread> onOpen;
  final ValueChanged<TalkThread> onLongPress;
  final bool Function(TalkThread thread) isPinned;
  final bool Function(TalkThread thread) isMuted;
  final bool Function(TalkThread thread) hasUnreadActivity;
  final int Function(TalkThread thread) effectiveUnread;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: threads.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No conversations match this view.')),
            )
          : Column(
              children: [
                for (var index = 0; index < threads.length; index++) ...[
                  _ThreadRow(
                    thread: threads[index],
                    unreadCount: effectiveUnread(threads[index]),
                    onTap: () => onOpen(threads[index]),
                    onLongPress: () => onLongPress(threads[index]),
                    isPinned: isPinned(threads[index]),
                    isMuted: isMuted(threads[index]),
                    hasUnreadActivity: hasUnreadActivity(threads[index]),
                  ),
                  if (index < threads.length - 1)
                    Divider(
                        height: 1,
                        indent: 71,
                        color: Theme.of(context).dividerColor),
                ],
              ],
            ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    required this.thread,
    required this.unreadCount,
    required this.onTap,
    required this.onLongPress,
    required this.isPinned,
    required this.isMuted,
    required this.hasUnreadActivity,
  });

  final TalkThread thread;
  final int unreadCount;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isPinned;
  final bool isMuted;
  final bool hasUnreadActivity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Open talk with ${thread.name}',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _Avatar(thread: thread),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            thread.name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        if (isPinned) ...[
                          const SizedBox(width: 5),
                          Icon(Icons.push_pin_rounded,
                              size: 14, color: scheme.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thread.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(thread.time,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 11.5)),
                  const SizedBox(height: 7),
                  if (hasUnreadActivity && unreadCount > 0)
                    _CountBadge(count: '$unreadCount')
                  else if (hasUnreadActivity)
                    _NewActivityDot(color: scheme.primary),
                  if (isMuted) ...[
                    const SizedBox(height: 5),
                    Icon(Icons.notifications_off_outlined,
                        size: 14, color: scheme.onSurfaceVariant),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.thread, this.size = 42});

  final TalkThread thread;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: thread.isGroup
          ? Icon(Icons.groups_rounded,
              size: size * .46, color: scheme.onPrimaryContainer)
          : Text(
              thread.initial,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontSize: size * .38,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: scheme.primary, borderRadius: BorderRadius.circular(999)),
      child: Text(
        count,
        style: TextStyle(
            color: scheme.onPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _NewActivityDot extends StatelessWidget {
  const _NewActivityDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 17, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your talks are personal spaces. Take your time.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
