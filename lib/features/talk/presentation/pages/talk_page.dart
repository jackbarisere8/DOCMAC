import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:docmac_app/features/chat/presentation/pages/chat_page.dart';

import '../../../../core/ui/docmac_community_icons.dart';
import '../../../../core/ui/docmac_iconly.dart';
import '../../../../shared/widgets/docmac_search_bar.dart';
import '../../data/talk_thread.dart';
import '../providers/talk_providers.dart';

/// Talk inbox. Threads stream from [talkThreadsProvider] (Firestore `chats`
/// where the uid is a participant). Demo preview rows are used only when
/// signed out or when Firebase is not configured.
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

  late final TextEditingController _searchController;
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _loadPrefs();
  }

  @override
  void dispose() {
    _searchFocusNode
      ..removeListener(_handleSearchFocusChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _cancelSearch() {
    HapticFeedback.selectionClick();
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() {
      _query = '';
      _filterIndex = 0;
    });
  }

  void _resetFilter() {
    setState(() => _filterIndex = 0);
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
        ..addAll(preferences.getStringList(_removedFavoritesKey) ??
            const <String>[]);
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
          peerUid: thread.peerUid,
          peerHandle: thread.peerHandle,
          personName: thread.name,
          personInitial: thread.initial,
          status: thread.isOnline ? 'Active now' : 'On Docmac',
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
                'Pick a recent conversation or find someone by @username.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 21,
                  backgroundColor:
                      Theme.of(sheetContext).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.alternate_email_rounded,
                    color:
                        Theme.of(sheetContext).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text('Find someone by @username'),
                subtitle: const Text('Start a new private talk'),
                onTap: () {
                  Navigator.of(sheetContext, rootNavigator: true).pop();
                  context.push('/talk/new');
                },
              ),
              if (recent.isNotEmpty)
                const Divider(height: 24)
              else
                const SizedBox(height: 8),
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
        final all =
            ref.read(talkThreadsProvider).valueOrNull ?? const <TalkThread>[];
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

  @override
  Widget build(BuildContext context) {
    final threadsAsync = ref.watch(talkThreadsProvider);
    final scheme = Theme.of(context).colorScheme;
    final isSearching = _searchFocusNode.hasFocus || _query.trim().isNotEmpty;
    final showFilters = isSearching || _filterIndex != 0;

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
                  final all = threadsAsync.valueOrNull ?? const <TalkThread>[];
                  _showCameraOptions(_visibleThreads(all));
                },
                onMenu: (action) {
                  final all = threadsAsync.valueOrNull ?? const <TalkThread>[];
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
                  final all = threadsAsync.valueOrNull ?? const <TalkThread>[];
                  _completeThreadAction(
                    _selectedThread!,
                    'clear',
                    _visibleThreads(all),
                  );
                },
                onAction: (action) {
                  final all = threadsAsync.valueOrNull ?? const <TalkThread>[];
                  _completeThreadAction(
                    _selectedThread!,
                    action,
                    _visibleThreads(all),
                  );
                },
              ),
            const SizedBox(height: 18),
            _TalkSearch(
              controller: _searchController,
              focusNode: _searchFocusNode,
              isSearching: isSearching,
              onChanged: (value) => setState(() => _query = value),
              onCancel: _cancelSearch,
              onCleared: _searchFocusNode.requestFocus,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: showFilters
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _FilterRow(
                        key: const ValueKey('talk-search-filters'),
                        filterIndex: _filterIndex,
                        unreadCount: _totalUnread(
                          _visibleThreads(
                            threadsAsync.valueOrNull ?? const <TalkThread>[],
                          ),
                        ),
                        onSelect: (index) {
                          HapticFeedback.selectionClick();
                          setState(() => _filterIndex = index);
                        },
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 18),
            threadsAsync.when(
              data: (all) =>
                  _InboxBody(threads: _visibleThreads(all), state: this),
              loading: () => threadsAsync.hasValue
                  ? _InboxBody(
                      threads: _visibleThreads(threadsAsync.requireValue),
                      state: this,
                    )
                  : const _TalkLoadingList(),
              error: (error, _) => _TalkErrorBody(
                onRetry: () => ref.invalidate(talkThreadsProvider),
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
          icon:
              Icon(DocmacIconlyLight.camera, size: 21, color: scheme.onSurface),
        ),
        PopupMenuButton<String>(
          tooltip: 'Talk options',
          onSelected: onMenu,
          offset: const Offset(0, 48),
          icon: Icon(
            Icons.more_vert_rounded,
            size: 21,
            color: scheme.onSurfaceVariant,
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'new',
              height: 52,
              child: _TalkMenuRow(
                icon: Icon(DocmacIconlyLight.edit, size: 19),
                label: 'New talk',
              ),
            ),
            PopupMenuItem(
              value: 'circle',
              height: 52,
              child: _TalkMenuRow(
                icon: Icon(DocmacIconlyLight.addUser, size: 19),
                label: 'New circle',
              ),
            ),
            PopupMenuItem(
              value: 'archive',
              height: 52,
              child: _TalkMenuRow(
                icon: DocmacCommunityIcon(
                  asset: DocmacCommunityIcons.archive,
                  size: 19,
                ),
                label: 'Archived talks',
              ),
            ),
            PopupMenuItem(
              value: 'select',
              height: 52,
              child: _TalkMenuRow(
                icon: Icon(DocmacIconlyLight.tickSquare, size: 19),
                label: 'Select talks',
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              height: 52,
              child: _TalkMenuRow(
                icon: Icon(DocmacIconlyLight.setting, size: 19),
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
    super.key,
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
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _FilterPill(
            label: 'All talks',
            icon: Icons.forum_outlined,
            active: filterIndex == 0,
            onTap: () => onSelect(0),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Unread',
            icon: Icons.mark_chat_unread_outlined,
            count: unreadCount > 0 ? '$unreadCount' : null,
            active: filterIndex == 1,
            onTap: () => onSelect(1),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Circles',
            icon: Icons.groups_2_outlined,
            active: filterIndex == 2,
            onTap: () => onSelect(2),
          ),
          const SizedBox(width: 8),
          _FilterPill(
            label: 'Saved',
            icon: Icons.bookmark_border_rounded,
            active: filterIndex == 3,
            onTap: () => onSelect(3),
          ),
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
                  const <TalkThread>[],
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
          hasQuery: state._query.trim().isNotEmpty,
          query: state._query.trim(),
          filterIndex: state._filterIndex,
          onClearSearch: state._clearSearch,
          onResetFilter: state._resetFilter,
          onStartTalk: () => state._showNewTalkPicker(
            state.ref.read(talkThreadsProvider).valueOrNull ??
                const <TalkThread>[],
          ),
        ),
      ],
    );
  }
}

class _TalkLoadingList extends StatefulWidget {
  const _TalkLoadingList();

  @override
  State<_TalkLoadingList> createState() => _TalkLoadingListState();
}

class _TalkLoadingListState extends State<_TalkLoadingList>
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Inbox', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final opacity = 0.35 + (_shimmerController.value * 0.45);
            return Container(
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
                        Opacity(
                          opacity: opacity,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  scheme.primaryContainer.withValues(alpha: .7),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: opacity,
                                child: Container(
                                  height: 13,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: scheme.primaryContainer
                                        .withValues(alpha: .7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Opacity(
                                opacity: opacity,
                                child: Container(
                                  height: 11,
                                  width: index == 0 ? 190 : 150,
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerHighest
                                        .withValues(alpha: .8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
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
            );
          },
        ),
      ],
    );
  }
}

class _TalkErrorBody extends StatelessWidget {
  const _TalkErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.error.withValues(alpha: .25)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_outlined,
              color: scheme.onErrorContainer,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Could not load talks',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again. Your conversations have not '
            'been deleted.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
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
          icon: const Icon(DocmacIconlyLight.arrowLeft, size: 21),
        ),
        const SizedBox(width: 6),
        Text('1', style: Theme.of(context).textTheme.headlineSmall),
        const Spacer(),
        IconButton(
          tooltip: 'View contact',
          onPressed: onViewContact,
          icon: Icon(DocmacIconlyLight.user, size: 21, color: scheme.onSurface),
        ),
        IconButton(
          tooltip: isPinned ? 'Unpin talk' : 'Pin talk',
          onPressed: onPin,
          icon: Icon(
            Icons.push_pin_rounded,
            size: 20,
            color: isPinned ? scheme.primary : scheme.onSurface,
          ),
        ),
        IconButton(
          tooltip: 'Clear chat',
          onPressed: onClear,
          icon:
              Icon(DocmacIconlyLight.delete, size: 21, color: scheme.onSurface),
        ),
        IconButton(
          tooltip: isMuted ? 'Unmute notifications' : 'Mute notifications',
          onPressed: onMute,
          icon: Icon(
            isMuted ? DocmacIconlyLight.volumeUp : DocmacIconlyLight.volumeOff,
            size: 21,
            color: scheme.onSurface,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Selected talk actions',
          onSelected: onAction,
          icon: Icon(
            Icons.more_vert_rounded,
            size: 21,
            color: scheme.onSurfaceVariant,
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'archive',
              child: _TalkMenuRow(
                icon: DocmacCommunityIcon(
                  asset: DocmacCommunityIcons.archive,
                  size: 19,
                ),
                label: 'Archive chat',
              ),
            ),
            const PopupMenuItem(
              value: 'shortcut',
              child: _TalkMenuRow(
                icon: Icon(DocmacIconlyLight.plus, size: 19),
                label: 'Add chat shortcut',
              ),
            ),
            const PopupMenuItem(
              value: 'contact',
              child: _TalkMenuRow(
                icon: Icon(DocmacIconlyLight.user, size: 19),
                label: 'View contact',
              ),
            ),
            const PopupMenuItem(
              value: 'unread',
              child: _TalkMenuRow(
                icon: Icon(DocmacIconlyLight.message, size: 19),
                label: 'Mark as unread',
              ),
            ),
            const PopupMenuItem(
              value: 'all',
              child: _TalkMenuRow(
                icon: Icon(DocmacIconlyLight.tickSquare, size: 19),
                label: 'Select all',
              ),
            ),
            PopupMenuItem(
              value: 'lock',
              child: _TalkMenuRow(
                icon: Icon(
                  isLocked ? DocmacIconlyLight.unlock : DocmacIconlyLight.lock,
                  size: 19,
                ),
                label: isLocked ? 'Unlock chat' : 'Lock chat',
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'favorite',
              child: _TalkMenuRow(
                icon: const Icon(DocmacIconlyLight.star, size: 19),
                label:
                    isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: _TalkMenuRow(
                icon: Icon(DocmacIconlyLight.delete, size: 19),
                label: 'Clear chat',
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: _TalkMenuRow(
                icon: Icon(DocmacIconlyLight.closeSquare, size: 19),
                label: 'Block',
              ),
            ),
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

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 22, child: Center(child: icon)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
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
                  child: Icon(Icons.archive_outlined, color: scheme.onSurface),
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

class _TalkSearch extends StatelessWidget {
  const _TalkSearch({
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.onChanged,
    required this.onCancel,
    required this.onCleared,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerRight,
          child: isSearching
              ? Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: IconButton(
                    key: const ValueKey('talk-search-cancel'),
                    tooltip: 'Cancel search',
                    onPressed: onCancel,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.arrow_back_rounded, color: ink),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: DocmacSearchBar(
            controller: controller,
            focusNode: focusNode,
            fieldKey: const ValueKey('talk-search-input'),
            hintText: 'Search...',
            semanticsLabel: 'Search talks, people and moments',
            clearTooltip: 'Clear search',
            onChanged: onChanged,
            onCleared: onCleared,
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.count,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String? count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = active ? scheme.onPrimary : scheme.onSurface;
    final background = active ? scheme.primary : scheme.surface;
    final borderColor = active ? scheme.primary : scheme.outlineVariant;

    return Semantics(
      button: true,
      selected: active,
      label: count == null ? '$label filter' : '$label $count filter',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: active
                          ? foreground.withValues(alpha: .18)
                          : scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count!,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTalksView extends StatelessWidget {
  const _EmptyTalksView({
    required this.hasQuery,
    required this.filterIndex,
    required this.query,
    required this.onClearSearch,
    required this.onResetFilter,
    required this.onStartTalk,
  });

  final bool hasQuery;
  final int filterIndex;
  final String query;
  final VoidCallback onClearSearch;
  final VoidCallback onResetFilter;
  final VoidCallback onStartTalk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final IconData icon;
    final String title;
    final String subtitle;
    final String actionLabel;
    final VoidCallback action;

    if (hasQuery) {
      icon = Icons.search_off_rounded;
      title = 'No talks found';
      subtitle =
          'Nothing matches "$query". Check for typos or try another search.';
      actionLabel = 'Clear search';
      action = onClearSearch;
    } else {
      switch (filterIndex) {
        case 1:
          icon = Icons.done_all_rounded;
          title = 'All caught up';
          subtitle = 'You have no unread conversations right now.';
          actionLabel = 'Show all talks';
          action = onResetFilter;
          break;
        case 2:
          icon = Icons.groups_outlined;
          title = 'No circles yet';
          subtitle = 'Group conversations and shared spaces will show up here.';
          actionLabel = 'Show all talks';
          action = onResetFilter;
          break;
        case 3:
          icon = Icons.bookmark_border_rounded;
          title = 'No saved talks';
          subtitle =
              'Long press any conversation to bookmark it for quick access.';
          actionLabel = 'Show all talks';
          action = onResetFilter;
          break;
        default:
          icon = Icons.chat_bubble_outline_rounded;
          title = 'No conversations yet';
          subtitle =
              'Start a conversation with friends, team members, or clients.';
          actionLabel = 'Start a talk';
          action = onStartTalk;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 26,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: action,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.dividerColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: Icon(
                hasQuery
                    ? Icons.close_rounded
                    : (filterIndex != 0
                        ? Icons.arrow_back_rounded
                        : Icons.add_rounded),
                size: 16,
              ),
              label: Text(
                actionLabel,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
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
    this.hasQuery = false,
    this.query = '',
    this.filterIndex = 0,
    this.onClearSearch,
    this.onResetFilter,
    this.onStartTalk,
  });

  final List<TalkThread> threads;
  final ValueChanged<TalkThread> onOpen;
  final ValueChanged<TalkThread> onLongPress;
  final bool Function(TalkThread thread) isPinned;
  final bool Function(TalkThread thread) isMuted;
  final bool Function(TalkThread thread) hasUnreadActivity;
  final int Function(TalkThread thread) effectiveUnread;
  final bool hasQuery;
  final String query;
  final int filterIndex;
  final VoidCallback? onClearSearch;
  final VoidCallback? onResetFilter;
  final VoidCallback? onStartTalk;

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
          ? _EmptyTalksView(
              hasQuery: hasQuery,
              query: query,
              filterIndex: filterIndex,
              onClearSearch: onClearSearch ?? () {},
              onResetFilter: onResetFilter ?? () {},
              onStartTalk: onStartTalk ?? () {},
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
    final isUnread = hasUnreadActivity && unreadCount > 0;
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
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                          ),
                        ),
                        if (isPinned) ...[
                          const SizedBox(width: 5),
                          Icon(Icons.push_pin_rounded,
                              size: 14, color: scheme.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      thread.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12.5,
                            color: isUnread
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                            fontWeight:
                                isUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    thread.time,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11.5,
                          color: isUnread
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          fontWeight:
                              isUnread ? FontWeight.w700 : FontWeight.w400,
                        ),
                  ),
                  const SizedBox(height: 7),
                  if (isUnread)
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(size * .34),
          ),
          child: thread.isGroup
              ? Icon(Icons.groups_rounded,
                  size: size * .48, color: scheme.onPrimaryContainer)
              : Text(
                  thread.initial,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: size * .38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        if (thread.isOnline)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count,
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
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
