import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';

/// Flagship global search experience across Docmac domains: People, Talks,
/// Spaces, Relays, Drops, and Forge perspectives.
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  String _query = '';
  int _tab = 0;

  final List<String> _recentSearches = [
    'Emma Clarke',
    'Weekend plans',
    'Docmac drops',
    'Design circle',
  ];

  static const _tabs = ['All', 'Person', 'Talk', 'Space', 'Relay', 'Drop', 'Forge'];

  static const _catalog = [
    _SearchResult(
      title: 'Emma Clarke',
      subtitle: '@emma · London, UK',
      kind: 'Person',
      icon: DocmacIconlyLight.user,
      accentColor: Color(0xFF596FD1),
      targetId: 'emma',
    ),
    _SearchResult(
      title: 'Jack Wilson',
      subtitle: '@jack · Product architect',
      kind: 'Person',
      icon: DocmacIconlyLight.user,
      accentColor: Color(0xFF596FD1),
      targetId: 'jack',
    ),
    _SearchResult(
      title: 'Weekend crew',
      subtitle: 'Sunday morning trail run and breakfast',
      kind: 'Space',
      icon: DocmacIconlyLight.category,
      accentColor: Color(0xFFE39B32),
      targetId: '',
    ),
    _SearchResult(
      title: 'Design circle',
      subtitle: 'Private circle for product prototyping',
      kind: 'Space',
      icon: DocmacIconlyLight.category,
      accentColor: Color(0xFFE39B32),
      targetId: '',
    ),
    _SearchResult(
      title: 'Docmac Official',
      subtitle: '@docmac · Publishing identity',
      kind: 'Relay',
      icon: DocmacIconlyLight.discovery,
      accentColor: Color(0xFF7B65D9),
      targetId: 'docmac',
    ),
    _SearchResult(
      title: 'A calmer way to share and stay close',
      subtitle: 'Docmac · Drop #14 · 3 min read',
      kind: 'Drop',
      icon: DocmacIconlyLight.document,
      accentColor: Color(0xFF2E9C92),
      targetId: 'docmac',
    ),
    _SearchResult(
      title: 'Should AI replace traditional homework?',
      subtitle: 'Jack · Forge Perspective · 8 contributors',
      kind: 'Forge',
      icon: DocmacIconlyLight.work,
      accentColor: Color(0xFFD4685A),
      targetId: 'jack',
    ),
    _SearchResult(
      title: 'A good read',
      subtitle: 'Emma · Moment · Yesterday',
      kind: 'Moment',
      icon: DocmacIconlyLight.star,
      accentColor: Color(0xFF64AE77),
      targetId: 'emma',
    ),
    _SearchResult(
      title: 'I found a quieter route by the water.',
      subtitle: 'Jack · Talk thread',
      kind: 'Talk',
      icon: DocmacIconlyLight.chat,
      accentColor: Color(0xFF596FD1),
      targetId: 'jack',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _controller = TextEditingController(text: _query);
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_controller.text != _query) {
      setState(() => _query = _controller.text);
    }
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void _applyQuery(String text) {
    HapticFeedback.selectionClick();
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    setState(() => _query = text);
  }

  void _clearQuery() {
    HapticFeedback.selectionClick();
    _controller.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  void _removeRecent(String item) {
    HapticFeedback.selectionClick();
    setState(() => _recentSearches.remove(item));
  }

  void _clearAllRecents() {
    HapticFeedback.selectionClick();
    setState(() => _recentSearches.clear());
  }

  void _open(BuildContext context, _SearchResult result) {
    HapticFeedback.selectionClick();
    switch (result.kind) {
      case 'Person':
        context.push('/person/${result.targetId}');
        return;
      case 'Moment':
        context.push('/moments?person=${result.targetId}');
        return;
      case 'Talk':
        context.push('/chat?person=${result.targetId}');
        return;
      case 'Relay':
      case 'Drop':
        context.push('/relays/home');
        return;
      case 'Forge':
        context.push('/forge');
        return;
      case 'Space':
      case 'Circle':
        context.push('/spaces');
        return;
      default:
        context.push('/orbit');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final normalized = _query.trim().toLowerCase();
    final hasQuery = normalized.isNotEmpty;

    final filtered = _catalog.where((item) {
      final matchesQuery = !hasQuery ||
          item.title.toLowerCase().contains(normalized) ||
          item.subtitle.toLowerCase().contains(normalized);
      final matchesTab = _tab == 0 || item.kind == _tabs[_tab];
      return matchesQuery && matchesTab;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Docmac'),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 48,
              padding: const EdgeInsets.only(left: 14, right: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _focusNode.hasFocus ? scheme.primary : theme.dividerColor,
                  width: _focusNode.hasFocus ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: _focusNode.hasFocus
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('global-search-input'),
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        letterSpacing: -0.1,
                      ),
                      cursorColor: scheme.primary,
                      cursorWidth: 1.5,
                      decoration: InputDecoration(
                        hintText: 'People, Talks, Spaces, Drops or Forge',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                          fontSize: 14,
                          letterSpacing: -0.1,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: hasQuery
                        ? IconButton(
                            key: const ValueKey('clear-global-search'),
                            tooltip: 'Clear search',
                            onPressed: _clearQuery,
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  scheme.onSurface.withValues(alpha: 0.08),
                              padding: const EdgeInsets.all(6),
                              minimumSize: const Size(28, 28),
                            ),
                            icon: const Icon(Icons.close_rounded),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Horizontal Category Filter Pills
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = _tab == index;
                return ChoiceChip(
                  key: ValueKey('filter-tab-${_tabs[index].toLowerCase()}'),
                  label: Text(_tabs[index]),
                  selected: selected,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? (isDark ? scheme.onPrimary : Colors.white)
                        : scheme.onSurfaceVariant,
                  ),
                  selectedColor: scheme.primary,
                  backgroundColor: scheme.surface,
                  side: BorderSide(
                    color: selected ? scheme.primary : theme.dividerColor,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _tab = val ? index : 0);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Content Body
          Expanded(
            child: hasQuery
                ? _buildSearchResults(theme, scheme, isDark, filtered)
                : _buildExploreView(theme, scheme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    ThemeData theme,
    ColorScheme scheme,
    bool isDark,
    List<_SearchResult> filtered,
  ) {
    if (filtered.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 28,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No results for “$_query”',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching across other categories like People, Spaces or Forge, or check your spelling.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _tab = 0);
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Show all categories'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return InkWell(
          onTap: () => _open(context, item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: item.accentColor.withValues(alpha: 0.14),
                  foregroundColor: item.accentColor,
                  child: Icon(item.icon, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: -0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.accentColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.kind,
                              style: TextStyle(
                                color: item.accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExploreView(ThemeData theme, ColorScheme scheme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      children: [
        // Recent searches section
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent searches',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: -0.1,
                ),
              ),
              TextButton(
                onPressed: _clearAllRecents,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final query in _recentSearches)
                InputChip(
                  avatar: const Icon(Icons.history_rounded, size: 15),
                  label: Text(query),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurface,
                  ),
                  backgroundColor: scheme.surface,
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: () => _applyQuery(query),
                  onDeleted: () => _removeRecent(query),
                  deleteIconColor: scheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 20),
        ],

        // Browse Categories Section
        Text(
          'Browse categories',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 12),

        _CategoryCard(
          icon: DocmacIconlyLight.user,
          color: const Color(0xFF596FD1),
          title: 'People & Contacts',
          subtitle: 'Find friends, collaborators and verified handles',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _tab = _tabs.indexOf('Person'));
          },
        ),
        const SizedBox(height: 10),

        _CategoryCard(
          icon: DocmacIconlyLight.chat,
          color: const Color(0xFF64AE77),
          title: 'Talk Threads',
          subtitle: 'Search direct 1:1 messages and shared media',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _tab = _tabs.indexOf('Talk'));
          },
        ),
        const SizedBox(height: 10),

        _CategoryCard(
          icon: DocmacIconlyLight.category,
          color: const Color(0xFFE39B32),
          title: 'Circles & Spaces',
          subtitle: 'Explore community groups, private circles and topics',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _tab = _tabs.indexOf('Space'));
          },
        ),
        const SizedBox(height: 10),

        _CategoryCard(
          icon: DocmacIconlyLight.discovery,
          color: const Color(0xFF7B65D9),
          title: 'Relays & Drops',
          subtitle: 'Read publishing identities, public drops and articles',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _tab = _tabs.indexOf('Relay'));
          },
        ),
        const SizedBox(height: 10),

        _CategoryCard(
          icon: DocmacIconlyLight.work,
          color: const Color(0xFFD4685A),
          title: 'Forge Perspectives',
          subtitle: 'Collaborative ideas, open prompts and discussions',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _tab = _tabs.indexOf('Forge'));
          },
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(icon, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResult {
  const _SearchResult({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.icon,
    required this.accentColor,
    required this.targetId,
  });

  final String title;
  final String subtitle;
  final String kind;
  final IconData icon;
  final Color accentColor;
  final String targetId;
}
