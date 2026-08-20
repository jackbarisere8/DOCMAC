import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/docmac_iconly.dart';

class TalkPage extends StatefulWidget {
  const TalkPage({super.key});

  @override
  State<TalkPage> createState() => _TalkPageState();
}

class _TalkPageState extends State<TalkPage> {
  int _selectedFilter = 0;
  String _query = '';
  _Thread? _selectedThread;
  final _searchController = TextEditingController();

  static const _threads = [
    _Thread('Jack Wilson', 'J', 'I found a quieter route by the water.',
        '6:21 PM', 2, true),
    _Thread('Weekend crew', 'W', 'Nora: What time are we meeting?', '5:08 PM',
        0, false,
        isCircle: true),
    _Thread('Emma Clarke', 'E', 'Sent you a new moment', 'Yesterday', 0, true),
    _Thread('Design circle', 'D', 'David: The prototype is ready.', 'Yesterday',
        4, false,
        isCircle: true, isSaved: true),
    _Thread('Tobi Adeyemi', 'T', 'Wave back to begin a conversation', 'Mon', 0,
        false),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleThreads = _threads.where((thread) {
      if (_TalkArchiveStore.contains(thread)) return false;
      if (!thread.name.toLowerCase().contains(_query.toLowerCase()) &&
          !thread.preview.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      return switch (_selectedFilter) {
        1 => thread.unread > 0,
        2 => thread.isCircle,
        3 => thread.isSaved,
        _ => true,
      };
    }).toList()
      ..sort((first, second) {
        final firstIsPinned = _TalkPinStore.contains(first);
        final secondIsPinned = _TalkPinStore.contains(second);
        if (firstIsPinned == secondIsPinned) return 0;
        return firstIsPinned ? -1 : 1;
      });

    return Stack(
      children: [
        ColoredBox(
          color: colors.surfaceContainerLowest,
          child: SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _selectedThread == null
                            ? _TalkHeader(
                                colors: colors,
                                onCamera: () => _showNotice(
                                    'Camera is ready for your next moment.'),
                                onMenuSelected: _handleTalkMenu,
                              )
                            : _TalkSelectionBar(
                                onClose: () =>
                                    setState(() => _selectedThread = null),
                                onArchive: _archiveSelectedThread,
                                onPin: _toggleSelectedThreadPin,
                                isPinned: _selectedThread != null &&
                                    _TalkPinStore.contains(_selectedThread!),
                                onMore: _handleSelectedThreadMenu,
                              ),
                        const SizedBox(height: 18),
                        _TalkSearch(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _FilterChip(
                                label: 'All talks',
                                active: _selectedFilter == 0,
                                onTap: () =>
                                    setState(() => _selectedFilter = 0),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Unread',
                                badge: '6',
                                active: _selectedFilter == 1,
                                onTap: () =>
                                    setState(() => _selectedFilter = 1),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Circles',
                                active: _selectedFilter == 2,
                                onTap: () =>
                                    setState(() => _selectedFilter = 2),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Saved',
                                active: _selectedFilter == 3,
                                onTap: () =>
                                    setState(() => _selectedFilter = 3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ArchiveLink(
                      count: _TalkArchiveStore.threads.length,
                      onTap: () => context.push('/talk/archive'),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('Inbox',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const Spacer(),
                            Text('${visibleThreads.length} conversations',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            children: [
                              for (var index = 0;
                                  index < visibleThreads.length;
                                  index++)
                                _ThreadTile(
                                  thread: visibleThreads[index],
                                  isPinned: _TalkPinStore.contains(
                                      visibleThreads[index]),
                                  isLast: index == visibleThreads.length - 1,
                                  onTap: () =>
                                      _openThread(visibleThreads[index]),
                                  onLongPress: () => setState(() =>
                                      _selectedThread = visibleThreads[index]),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(DocmacIconlyLight.lock,
                                  color: colors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Your conversations stay between the people in them.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            heroTag: 'add-friend',
            tooltip: 'Start a new talk',
            onPressed: () => context.push('/contacts/new-talk'),
            child: const Icon(DocmacIconlyLight.chat),
          ),
        ),
      ],
    );
  }

  void _handleTalkMenu(String selection) {
    if (selection == 'settings') {
      context.push('/settings');
      return;
    }
    final label = switch (selection) {
      'spotlight' => 'Orbit spotlight',
      'circle' => 'Create a circle',
      'broadcast' => 'Start a broadcast',
      'communities' => 'Your Spaces',
      'signals' => 'Signal labels',
      'devices' => 'Connected devices',
      'keepsakes' => 'Keepsakes',
      _ => 'Talk',
    };
    if (selection == 'circle') {
      context.push('/circle/new');
      return;
    }
    if (selection == 'communities') {
      context.push('/spaces');
      return;
    }
    _showNotice('$label is coming next.');
  }

  void _archiveSelectedThread() {
    final thread = _selectedThread;
    if (thread == null) return;
    setState(() {
      _TalkArchiveStore.archive(thread);
      _selectedThread = null;
    });
    _showNotice('${thread.name} moved to archived talks.');
  }

  void _openThread(_Thread thread) {
    context.push(_threadRoute(thread));
  }

  void _toggleSelectedThreadPin() {
    final thread = _selectedThread;
    if (thread == null) return;
    final wasPinned = _TalkPinStore.contains(thread);
    setState(() {
      _TalkPinStore.toggle(thread);
      _selectedThread = null;
    });
    _showNotice(wasPinned
        ? '${thread.name} unpinned from Talk.'
        : '${thread.name} pinned to the top of Talk.');
  }

  void _handleSelectedThreadMenu(String selection) {
    final thread = _selectedThread;
    if (thread == null) return;
    if (selection == 'archive') {
      _archiveSelectedThread();
      return;
    }
    if (selection == 'pin') {
      _toggleSelectedThreadPin();
      return;
    }
    if (selection == 'view') {
      setState(() => _selectedThread = null);
      _openThread(thread);
      return;
    }
    setState(() => _selectedThread = null);
    final message = switch (selection) {
      'folder' => '${thread.name} can be added to a folder next.',
      'unread' => '${thread.name} marked as unread.',
      'lock' => '${thread.name} is ready to lock with your app passcode.',
      'favorite' => '${thread.name} added to favourites.',
      'clear' => 'Messages in ${thread.name} are ready to clear.',
      'block' => '${thread.name} is ready to block.',
      'mute' => '${thread.name} muted for now.',
      _ => 'Talk options closed.',
    };
    _showNotice(message);
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Keeps archived conversations available while the app is open.
class _TalkArchiveStore {
  _TalkArchiveStore._();

  static final _threads = <_Thread>[];

  static List<_Thread> get threads => List.unmodifiable(_threads);

  static bool contains(_Thread thread) =>
      _threads.any((archived) => archived.name == thread.name);

  static void archive(_Thread thread) {
    _threads.removeWhere((archived) => archived.name == thread.name);
    _threads.insert(0, thread);
  }
}

/// Keeps pinned conversations at the top of Talk while the app is open.
class _TalkPinStore {
  _TalkPinStore._();

  static final _threadNames = <String>{};

  static bool contains(_Thread thread) => _threadNames.contains(thread.name);

  static void toggle(_Thread thread) {
    if (!_threadNames.add(thread.name)) {
      _threadNames.remove(thread.name);
    }
  }
}

class TalkArchivePage extends StatelessWidget {
  const TalkArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final threads = _TalkArchiveStore.threads;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Archived talks'),
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
      body: threads.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(DocmacIconlyLight.folder,
                        size: 40, color: colors.onSurfaceVariant),
                    const SizedBox(height: 14),
                    Text('No archived talks',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text('Conversations you archive will appear here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text('${threads.length} archived conversations',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      for (var index = 0; index < threads.length; index++)
                        _ThreadTile(
                          thread: threads[index],
                          isPinned: _TalkPinStore.contains(threads[index]),
                          isLast: index == threads.length - 1,
                          onTap: () =>
                              context.push(_threadRoute(threads[index])),
                          onLongPress: null,
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ArchiveLink extends StatelessWidget {
  const _ArchiveLink({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(DocmacIconlyLight.folder, color: colors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Archived',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (count > 0)
                Text('$count',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onSurface,
                        )),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

String _threadRoute(_Thread thread) => thread.isCircle
    ? '/circle'
    : '/person/${thread.name.split(' ').first.toLowerCase()}';

class _TalkMenuLabel extends StatelessWidget {
  const _TalkMenuLabel(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Text(label),
        ],
      );
}

class _TalkHeader extends StatelessWidget {
  const _TalkHeader({
    required this.colors,
    required this.onCamera,
    required this.onMenuSelected,
  });

  final ColorScheme colors;
  final VoidCallback onCamera;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text('Talk',
                  style: Theme.of(context).textTheme.headlineLarge)),
          IconButton(
            tooltip: 'Open camera',
            onPressed: onCamera,
            icon: Icon(DocmacIconlyLight.camera, color: colors.onSurface),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: 'More Talk options',
            color: colors.surface,
            surfaceTintColor: Colors.transparent,
            onSelected: onMenuSelected,
            icon: Icon(DocmacIconlyLight.moreCircle, color: colors.onSurface),
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: 'spotlight',
                  child: _TalkMenuLabel(
                      DocmacIconlyLight.discovery, 'Orbit spotlight')),
              PopupMenuItem(
                  value: 'circle',
                  child: _TalkMenuLabel(
                      DocmacIconlyLight.addUser, 'Create a circle')),
              PopupMenuItem(
                  value: 'broadcast',
                  child: _TalkMenuLabel(
                      DocmacIconlyLight.discovery, 'Start a broadcast')),
              PopupMenuItem(
                  value: 'communities',
                  child: _TalkMenuLabel(
                      DocmacIconlyLight.category, 'Your Spaces')),
              PopupMenuItem(
                  value: 'signals',
                  child: _TalkMenuLabel(
                      DocmacIconlyLight.ticketStar, 'Signal labels')),
              PopupMenuItem(
                  value: 'devices',
                  child: _TalkMenuLabel(
                      DocmacIconlyLight.discovery, 'Connected devices')),
              PopupMenuItem(
                  value: 'keepsakes',
                  child: _TalkMenuLabel(DocmacIconlyLight.star, 'Keepsakes')),
              PopupMenuDivider(),
              PopupMenuItem(
                  value: 'settings',
                  child: _TalkMenuLabel(
                      DocmacIconlyLight.filter, 'Talk settings')),
            ],
          ),
        ],
      );
}

class _TalkSelectionBar extends StatelessWidget {
  const _TalkSelectionBar({
    required this.onClose,
    required this.onArchive,
    required this.onPin,
    required this.isPinned,
    required this.onMore,
  });

  final VoidCallback onClose;
  final VoidCallback onArchive;
  final VoidCallback onPin;
  final bool isPinned;
  final ValueChanged<String> onMore;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(
            tooltip: 'Cancel selection',
            onPressed: onClose,
            icon: const Icon(DocmacIconlyLight.arrowLeft),
          ),
          const SizedBox(width: 8),
          Text('1 selected', style: Theme.of(context).textTheme.headlineSmall),
          const Spacer(),
          IconButton(
            tooltip: 'Archive talk',
            onPressed: onArchive,
            icon: const Icon(DocmacIconlyLight.folder),
          ),
          IconButton(
            tooltip: isPinned ? 'Unpin talk' : 'Pin talk',
            onPressed: onPin,
            icon: Icon(
              DocmacIconlyLight.bookmark,
              color: isPinned ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: onMore,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'archive',
                child: _TalkMenuLabel(DocmacIconlyLight.folder, 'Archive talk'),
              ),
              const PopupMenuItem(
                value: 'folder',
                child:
                    _TalkMenuLabel(DocmacIconlyLight.category, 'Add to folder'),
              ),
              const PopupMenuItem(
                value: 'view',
                child: _TalkMenuLabel(DocmacIconlyLight.profile, 'View person'),
              ),
              const PopupMenuItem(
                value: 'unread',
                child:
                    _TalkMenuLabel(DocmacIconlyLight.message, 'Mark as unread'),
              ),
              PopupMenuItem(
                value: 'pin',
                child: _TalkMenuLabel(
                  DocmacIconlyLight.bookmark,
                  isPinned ? 'Unpin talk' : 'Pin talk',
                ),
              ),
              const PopupMenuItem(
                value: 'lock',
                child: _TalkMenuLabel(DocmacIconlyLight.lock, 'Lock talk'),
              ),
              const PopupMenuItem(
                value: 'favorite',
                child:
                    _TalkMenuLabel(DocmacIconlyLight.star, 'Add to favourites'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: _TalkMenuLabel(DocmacIconlyLight.delete, 'Clear talk'),
              ),
              const PopupMenuItem(
                value: 'block',
                child: _TalkMenuLabel(DocmacIconlyLight.danger, 'Block person'),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: _TalkMenuLabel(DocmacIconlyLight.volumeOff, 'Mute talk'),
              ),
            ],
          ),
        ],
      );
}

class _TalkSearch extends StatelessWidget {
  const _TalkSearch({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Search messages',
          prefixIcon: Icon(DocmacIconlyLight.search),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: active ? colors.primary : colors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? colors.primary : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: active ? colors.onPrimary : colors.onSurface,
                      )),
              if (badge != null) ...[
                const SizedBox(width: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: active
                        ? colors.onPrimary.withValues(alpha: 0.22)
                        : colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(badge!,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 10,
                            color: active ? colors.onPrimary : colors.primary,
                          )),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.thread,
    required this.isPinned,
    required this.isLast,
    required this.onTap,
    required this.onLongPress,
  });

  final _Thread thread;
  final bool isPinned;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Text(thread.initial),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(thread.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontSize: 15)),
                        ),
                        if (isPinned) ...[
                          const SizedBox(width: 6),
                          Icon(
                            DocmacIconlyLight.bookmark,
                            size: 15,
                            color: Theme.of(context).colorScheme.primary,
                            semanticLabel: 'Pinned talk',
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(thread.time,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 11,
                                )),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (thread.online) ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(thread.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        if (thread.unread > 0) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 10,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            child: Text('${thread.unread}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _Thread {
  const _Thread(this.name, this.initial, this.preview, this.time, this.unread,
      this.online,
      {this.isCircle = false, this.isSaved = false});

  final String name;
  final String initial;
  final String preview;
  final String time;
  final int unread;
  final bool online;
  final bool isCircle;
  final bool isSaved;
}
