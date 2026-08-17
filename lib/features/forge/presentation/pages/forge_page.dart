import 'package:flutter/material.dart';

import '../../../../core/ui/docmac_iconly.dart';

/// Forge is Docmac's home for perspectives: ideas that invite a thoughtful
/// response, rather than disposable posts.
class ForgePage extends StatefulWidget {
  const ForgePage({super.key});

  @override
  State<ForgePage> createState() => _ForgePageState();
}

class _ForgePageState extends State<ForgePage> {
  var _selectedFilter = 'Trending';
  final _perspectives = <Perspective>[
    const Perspective(
      author: 'Nora Adeyemi',
      handle: '@nora',
      category: 'Technology',
      title: 'Should AI replace homework?',
      body:
          'The useful question is not whether it can, but what practice still helps people learn to think for themselves.',
      responses: 42,
      appreciations: 128,
      insights: 31,
      age: '2h',
    ),
    const Perspective(
      author: 'David Okafor',
      handle: '@davido',
      category: 'Work',
      title: 'Is being available all day a sign of a healthy team?',
      body:
          'A team can be responsive without treating every notification as an emergency. What boundaries actually work?',
      responses: 18,
      appreciations: 74,
      insights: 12,
      age: '5h',
    ),
    const Perspective(
      author: 'Emma Clarke',
      handle: '@emmac',
      category: 'Culture',
      title: 'What makes a digital community feel like it belongs to you?',
      body:
          'I think it is less about a large audience and more about familiar people returning with care.',
      responses: 27,
      appreciations: 96,
      insights: 22,
      age: 'Yesterday',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPerspective,
        icon: const Icon(DocmacIconlyLight.plus),
        label: const Text('Create perspective'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back to Orbit',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(DocmacIconlyLight.arrowLeft),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Forge',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge),
                            Text('Where ideas get stronger together',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Search Forge',
                        onPressed: () => _notice('Search is coming with Spaces.'),
                        icon: const Icon(DocmacIconlyLight.search),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bring an idea worth exploring.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: colors.onPrimary,
                                        fontWeight: FontWeight.w800,
                                      )),
                              const SizedBox(height: 5),
                              Text('Perspectives invite responses, not rage.',
                                  style: TextStyle(
                                      color: colors.onPrimary
                                          .withValues(alpha: .8))),
                            ],
                          ),
                        ),
                        Icon(DocmacIconlyLight.work,
                            color: colors.onPrimary, size: 34),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        return ChoiceChip(
                          label: Text(filter),
                          selected: filter == _selectedFilter,
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(_selectedFilter == 'Trending'
                          ? 'Ideas gaining thoughtful momentum'
                          : '$_selectedFilter perspectives',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
              sliver: SliverList.separated(
                itemCount: _perspectives.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _PerspectiveCard(
                  perspective: _perspectives[index],
                  onTap: () => _openPerspective(_perspectives[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPerspective() async {
    final result = await Navigator.of(context).push<Perspective>(
      MaterialPageRoute(builder: (_) => const CreatePerspectivePage()),
    );
    if (result != null && mounted) setState(() => _perspectives.insert(0, result));
  }

  Future<void> _openPerspective(Perspective perspective) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => PerspectivePage(perspective: perspective)));

  void _notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

const _filters = ['Trending', 'Latest', 'Tuned In', 'Technology', 'Culture'];

class Perspective {
  const Perspective({
    required this.author,
    required this.handle,
    required this.category,
    required this.title,
    required this.body,
    required this.responses,
    required this.appreciations,
    required this.insights,
    required this.age,
    this.visibility = 'Open in Forge',
  });

  final String author, handle, category, title, body, age, visibility;
  final int responses, appreciations, insights;
}

class _PerspectiveCard extends StatelessWidget {
  const _PerspectiveCard({required this.perspective, required this.onTap});
  final Perspective perspective;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(child: Text(perspective.author.substring(0, 1))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(perspective.author, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${perspective.handle} · ${perspective.age}',
                    style: Theme.of(context).textTheme.bodySmall),
              ])),
              Chip(label: Text(perspective.category)),
            ]),
            const SizedBox(height: 16),
            Text(perspective.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 7),
            Text(perspective.body, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4)),
            const SizedBox(height: 16),
            Row(children: [
              _Metric(icon: DocmacIconlyLight.chat, label: '${perspective.responses} responses'),
              const SizedBox(width: 16),
              _Metric(icon: DocmacIconlyLight.graph, label: '${perspective.insights} insights'),
              const Spacer(),
              Icon(DocmacIconlyLight.arrowRight, color: colors.primary),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 17, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]);
}

class PerspectivePage extends StatefulWidget {
  const PerspectivePage({super.key, required this.perspective});
  final Perspective perspective;

  @override
  State<PerspectivePage> createState() => _PerspectivePageState();
}

class _PerspectivePageState extends State<PerspectivePage> {
  final _response = TextEditingController();
  final _responses = <_Response>[
    const _Response('Amara', 'Insightful', 'Homework should become a reflection on the process, not just a test of recall.'),
    const _Response('Tobi', 'Challenge', 'We still need the productive struggle that makes a concept stick.'),
  ];

  @override
  void dispose() { _response.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final item = widget.perspective;
    return Scaffold(
      appBar: AppBar(title: const Text('Perspective')),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), children: [
            Chip(label: Text(item.category)),
            const SizedBox(height: 12),
            Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(item.body, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55)),
            const SizedBox(height: 22),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _ReactionButton(icon: DocmacIconlyLight.heart, label: 'Appreciate ${item.appreciations}'),
              const _ReactionButton(icon: DocmacIconlyLight.tickSquare, label: 'Support'),
              const _ReactionButton(icon: DocmacIconlyLight.danger, label: 'Challenge'),
              _ReactionButton(icon: DocmacIconlyLight.graph, label: 'Insightful ${item.insights}'),
            ]),
            const SizedBox(height: 28),
            Text('${_responses.length} responses', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            for (final response in _responses) _ResponseCard(response: response),
            const SizedBox(height: 14),
            _ResolutionCard(),
          ])),
          SafeArea(top: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: [
              Expanded(child: TextField(controller: _response, decoration: const InputDecoration(hintText: 'Add a thoughtful response'))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _addResponse, icon: const Icon(DocmacIconlyLight.send)),
            ]),
          )),
        ]),
      ),
    );
  }

  void _addResponse() {
    final text = _response.text.trim();
    if (text.isEmpty) return;
    setState(() => _responses.insert(0, _Response('You', 'Response', text)));
    _response.clear();
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(onPressed: () {}, icon: Icon(icon, size: 18), label: Text(label));
}

class _Response { const _Response(this.author, this.kind, this.body); final String author, kind, body; }

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({required this.response});
  final _Response response;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text(response.author, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(width: 8), Chip(label: Text(response.kind))]),
      const SizedBox(height: 7), Text(response.body),
    ])),
  );
}

class _ResolutionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Resolution', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 5),
      const Text('When the discussion has matured, the author can record what changed and what the community learned.'),
    ]),
  );
}

class CreatePerspectivePage extends StatefulWidget {
  const CreatePerspectivePage({super.key});
  @override
  State<CreatePerspectivePage> createState() => _CreatePerspectivePageState();
}

class _CreatePerspectivePageState extends State<CreatePerspectivePage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  var _category = 'Technology';
  var _visibility = 'Open in Forge';

  @override
  void dispose() { _title.dispose(); _body.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create perspective')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Start a conversation worth returning to.', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 24),
      TextField(controller: _title, maxLength: 120, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Title', hintText: 'What idea are you exploring?')),
      const SizedBox(height: 12),
      TextField(controller: _body, minLines: 5, maxLines: 8, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Your perspective', hintText: 'Share enough context for people to respond thoughtfully.')),
      const SizedBox(height: 16),
      DropdownButtonFormField(initialValue: _category, decoration: const InputDecoration(labelText: 'Category'), items: const ['Technology', 'Culture', 'Work', 'Learning', 'Society'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setState(() => _category = value!)),
      const SizedBox(height: 12),
      DropdownButtonFormField(initialValue: _visibility, decoration: const InputDecoration(labelText: 'Visibility'), items: const ['Open in Forge', 'My circles', 'Only me'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setState(() => _visibility = value!)),
      const SizedBox(height: 28),
      FilledButton(onPressed: _publish, child: const Text('Publish perspective')),
    ])),
  );

  void _publish() {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
    Navigator.of(context).pop(Perspective(author: 'You', handle: '@you', category: _category, title: _title.text.trim(), body: _body.text.trim(), responses: 0, appreciations: 0, insights: 0, age: 'Now', visibility: _visibility));
  }
}
