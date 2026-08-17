import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One deliberately broad search surface for Phase 1. Results are grouped by
/// product object so expanding it to Firestore later will not alter the UI.
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  String _query = '';
  int _tab = 0;

  static const _results = [
    _SearchResult(
        'Emma Clarke', '@emma', 'Person', Icons.person_outline_rounded, 'emma'),
    _SearchResult(
        'Jack Wilson', '@jack', 'Person', Icons.person_outline_rounded, 'jack'),
    _SearchResult(
        'Weekend plans', 'Your circle', 'Circle', Icons.group_outlined, ''),
    _SearchResult('Docmac', '@docmac · Publishing identity', 'Relay',
        Icons.campaign_outlined, 'docmac'),
    _SearchResult('A calmer way to share, talk and stay close is taking shape.',
        'Docmac · Drop', 'Drop', Icons.article_outlined, 'docmac'),
    _SearchResult('Should AI replace traditional homework?',
        'Jack · Forge Perspective', 'Forge', Icons.account_tree_outlined, 'jack'),
    _SearchResult('A good read', 'Emma · Moment', 'Moment',
        Icons.menu_book_outlined, 'emma'),
    _SearchResult('I found a quieter route by the water.', 'Jack · Talk',
        'Talk', Icons.chat_bubble_outline_rounded, 'jack'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _results.where((result) {
      final matchesQuery =
          result.title.toLowerCase().contains(_query.toLowerCase()) ||
              result.subtitle.toLowerCase().contains(_query.toLowerCase());
      final matchesTab = _tab == 0 || result.kind == _tabs[_tab];
      return matchesQuery && matchesTab;
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Search Docmac')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'People, Relays, Spaces, Drops and Forge')),
        ),
        SizedBox(
          height: 48,
          child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final entry in _tabs.indexed)
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                          label: Text(entry.$2),
                          selected: _tab == entry.$1,
                          onSelected: (_) => setState(() => _tab = entry.$1))),
              ]),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('No matching people, Relays, Spaces, Drops or Forge results.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final result = filtered[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 7),
                      leading: CircleAvatar(child: Icon(result.icon)),
                      title: Text(result.title),
                      subtitle: Text(result.subtitle),
                      trailing: Text(result.kind,
                          style: Theme.of(context).textTheme.labelSmall),
                      onTap: () => _open(context, result),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  void _open(BuildContext context, _SearchResult result) {
    switch (result.kind) {
      case 'Person':
        context.push('/person/${result.personId}');
        return;
      case 'Moment':
        context.push('/moments?person=${result.personId}');
        return;
      case 'Talk':
        context.push('/chat?person=${result.personId}');
        return;
      case 'Relay':
      case 'Drop':
        context.push('/relays/home');
        return;
      case 'Forge':
        context.push('/forge');
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${result.title} opens in Phase 2.')));
        return;
    }
  }
}

const _tabs = ['All', 'Person', 'Relay', 'Space', 'Drop', 'Forge'];

class _SearchResult {
  const _SearchResult(
      this.title, this.subtitle, this.kind, this.icon, this.personId);
  final String title;
  final String subtitle;
  final String kind;
  final IconData icon;
  final String personId;
}
