import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';

/// Space UI: a community container that holds several topical group talks.
/// Data is deliberately kept in memory until the community graph is connected.
class CircleLandingPage extends StatelessWidget {
  const CircleLandingPage({super.key});

  @override
  Widget build(BuildContext context) => _CircleStore.current == null
      ? const CircleWelcomePage()
      : const CircleHomePage();
}

class CircleWelcomePage extends StatelessWidget {
  const CircleWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: () => context.pop(),
                  icon: const Icon(DocmacIconlyLight.closeSquare),
                ),
              ),
              const Spacer(flex: 2),
              const _CircleEmblem(size: 178, showAccent: true),
              const SizedBox(height: 38),
              Text('Create a Space',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 14),
              Text(
                'Bring together a neighbourhood, school, team or interest. '
                'A Space holds members, announcements and several topic groups.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              TextButton.icon(
                onPressed: () => _showCircleExamples(context),
                icon: const Icon(DocmacIconlyLight.discovery, size: 18),
                label: const Text('See example Spaces'),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/spaces/new'),
                  child: const Text('Get started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showCircleExamples(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Space ideas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 14),
            Text(
                '• Neighbourhood watch\n• Campus life\n• Product design team\n• Family plans'),
          ],
        ),
      ),
    ),
  );
}

class NewCirclePage extends StatefulWidget {
  const NewCirclePage({super.key});

  @override
  State<NewCirclePage> createState() => _NewCirclePageState();
}

class _NewCirclePageState extends State<NewCirclePage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController(
    text: 'A space for members to share, plan and stay close.',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Space')),
      body: SafeArea(
        child: Column(
          children: [
            TextButton(
              onPressed: () => _showCircleExamples(context),
              child: const Text('See examples of different Spaces'),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                children: [
                  const Center(
                      child: _CircleEmblem(size: 120, showAccent: false)),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () =>
                          _notice('Photo selection will be available soon.'),
                      icon: const Icon(DocmacIconlyLight.camera, size: 18),
                      label: const Text('Change Space photo'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameController,
                    maxLength: 100,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Space name',
                      hintText: 'e.g. Northside community',
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _descriptionController,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 2048,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'About this Space',
                      hintText: 'Tell members what this Space is for',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed:
                      _nameController.text.trim().isEmpty ? null : _create,
                  style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(18)),
                  child: const Icon(DocmacIconlyLight.arrowRight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _create() {
    _CircleStore.create(
      _nameController.text.trim(),
      _descriptionController.text.trim(),
    );
    context.go('/spaces');
  }

  void _notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class CircleHomePage extends StatefulWidget {
  const CircleHomePage({super.key});

  @override
  State<CircleHomePage> createState() => _CircleHomePageState();
}

class _CircleHomePageState extends State<CircleHomePage> {
  @override
  Widget build(BuildContext context) {
    final circle = _CircleStore.current;
    if (circle == null) return const CircleWelcomePage();
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(circle.name),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Space options',
            onSelected: _handleMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'info', child: Text('Space info')),
              PopupMenuItem(value: 'invite', child: Text('Invite members')),
              PopupMenuItem(value: 'settings', child: Text('Space settings')),
            ],
            icon: const Icon(DocmacIconlyLight.moreCircle),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
        children: [
          _CircleSummary(circle: circle),
          const SizedBox(height: 20),
          _CircleRow(
            icon: DocmacIconlyLight.notification,
            iconBackground: colors.secondaryContainer,
            title: 'Announcements',
            subtitle: 'Keep every member in the loop',
            onTap: () => context.push('/spaces/info?tab=announcements'),
          ),
          const SizedBox(height: 22),
          Text('Groups you’re in',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          for (final group in circle.groups)
            _CircleRow(
              icon: group == 'General'
                  ? DocmacIconlyLight.message
                  : DocmacIconlyLight.folder,
              title: group,
              subtitle: group == 'General'
                  ? 'Add members to start chatting'
                  : 'Space group',
              trailing: const Text('Today'),
              onTap: () => context.push('/chat'),
            ),
          const SizedBox(height: 34),
          Text(
            'Members can join any groups you add to this Space.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton.icon(
          onPressed: _addGroup,
          icon: const Icon(DocmacIconlyLight.plus),
          label: const Text('Add group'),
        ),
      ),
    );
  }

  void _handleMenu(String value) {
    switch (value) {
      case 'info':
        context.push('/spaces/info');
        return;
      case 'settings':
        context.push('/spaces/settings');
        return;
      case 'invite':
        _notice('A Space invite link is ready to share.');
        return;
    }
  }

  Future<void> _addGroup() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Group name'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Add')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    setState(() => _CircleStore.current!.groups.add(name.trim()));
    _notice('${name.trim()} added to your Space.');
  }

  void _notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class CircleInfoPage extends StatefulWidget {
  const CircleInfoPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<CircleInfoPage> createState() => _CircleInfoPageState();
}

class _CircleInfoPageState extends State<CircleInfoPage> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final circle = _CircleStore.current;
    if (circle == null) return const CircleWelcomePage();
    return Scaffold(
      appBar: AppBar(title: Text(circle.name)),
      body: Column(
        children: [
          _CircleSummary(circle: circle, compact: true),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Circle')),
              ButtonSegment(value: 1, label: Text('Announcements')),
            ],
            selected: {_tab},
            showSelectedIcon: false,
            onSelectionChanged: (value) => setState(() => _tab = value.first),
          ),
          const SizedBox(height: 12),
          Expanded(
              child: _tab == 0
                  ? _circleDetails(circle)
                  : const _AnnouncementSettings()),
        ],
      ),
    );
  }

  Widget _circleDetails(_Circle circle) => ListView(
        padding: const EdgeInsets.only(bottom: 26),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
            child: Text(circle.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.35,
                    )),
          ),
          const Divider(height: 20),
          _InfoAction(
              icon: DocmacIconlyLight.edit,
              title: 'Edit Circle info',
              onTap: _editInfo),
          _InfoAction(
              icon: DocmacIconlyLight.addUser,
              title: 'Manage groups',
              onTap: () => context.pop()),
          _InfoAction(
              icon: DocmacIconlyLight.setting,
              title: 'Circle settings',
              onTap: () => context.push('/circles/settings')),
          const Divider(height: 26),
          _InfoAction(
              icon: DocmacIconlyLight.folder,
              title: 'View groups (${circle.groups.length})',
              onTap: () => context.pop()),
          const Divider(height: 26),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
            child: Text(
                '${circle.members} Circle member${circle.members == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.labelLarge),
          ),
          _InfoAction(
              icon: DocmacIconlyLight.addUser,
              title: 'Add members',
              emphasized: true,
              onTap: () => _notice('Invite members from your People list.')),
          const ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: CircleAvatar(child: Text('Y')),
            title: Text('You'),
            trailing: Chip(label: Text('Circle owner')),
          ),
          const Divider(height: 26),
          _InfoAction(
              icon: DocmacIconlyLight.swap,
              title: 'Assign new owner',
              onTap: () => _notice('Choose a member to transfer ownership.')),
          _InfoAction(
              icon: DocmacIconlyLight.logout,
              title: 'Exit Circle',
              destructive: true,
              onTap: () => _notice('Owners must assign a new owner first.')),
          _InfoAction(
              icon: DocmacIconlyLight.danger,
              title: 'Report Circle',
              destructive: true,
              onTap: () => _notice('Report options will open here.')),
          _InfoAction(
              icon: DocmacIconlyLight.closeSquare,
              title: 'Deactivate Circle',
              destructive: true,
              onTap: () => context.push('/circles/deactivate')),
        ],
      );

  Future<void> _editInfo() async {
    final controller =
        TextEditingController(text: _CircleStore.current!.description);
    final description = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Circle info'),
        content:
            TextField(controller: controller, maxLines: 4, maxLength: 2048),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (description != null && description.trim().isNotEmpty) {
      setState(() => _CircleStore.current!.description = description.trim());
    }
  }

  void _notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class CircleSettingsPage extends StatelessWidget {
  const CircleSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Circle settings')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: const [
            Text('Circle permissions'),
            SizedBox(height: 28),
            _SettingCopy('Who can add new members', 'Only Circle admins'),
            SizedBox(height: 28),
            _SettingCopy('Who can add new groups', 'Only Circle admins'),
          ],
        ),
      );
}

class CircleDeactivatePage extends StatelessWidget {
  const CircleDeactivatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final circle = _CircleStore.current;
    if (circle == null) return const CircleWelcomePage();
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Deactivate Circle')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: Column(
            children: [
              const _CircleEmblem(
                  size: 140, showAccent: false, destructive: true),
              const SizedBox(height: 28),
              Text('Deactivate “${circle.name}”?',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text('This action cannot be undone.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 36),
              const _ImpactRow(
                  icon: DocmacIconlyLight.hide,
                  title: 'Groups will be disconnected',
                  detail:
                      'Groups will still work as usual, outside this Circle.'),
              const _ImpactRow(
                  icon: DocmacIconlyLight.volumeOff,
                  title: 'Announcements will close',
                  detail:
                      'Members will no longer receive new Circle announcements.'),
              const _ImpactRow(
                  icon: DocmacIconlyLight.delete,
                  title: 'Circle info will be deleted',
                  detail:
                      'Members will lose access to this Circle’s groups and information.'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError),
                  onPressed: () => _confirmDeactivate(context),
                  child: const Text('Deactivate Circle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeactivate(BuildContext context) {
    _CircleStore.current = null;
    context.go('/circles');
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your Circle has been deactivated.')));
  }
}

class _AnnouncementSettings extends StatefulWidget {
  const _AnnouncementSettings();

  @override
  State<_AnnouncementSettings> createState() => _AnnouncementSettingsState();
}

class _AnnouncementSettingsState extends State<_AnnouncementSettings> {
  bool _chatLock = false;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _InfoAction(
              icon: DocmacIconlyLight.notification,
              title: 'Notifications',
              onTap: () {}),
          _InfoAction(
              icon: DocmacIconlyLight.image,
              title: 'Media visibility',
              onTap: () {}),
          const Divider(height: 28),
          const _InfoAction(
              icon: DocmacIconlyLight.lock,
              title: 'Encryption',
              subtitle: 'Messages and calls are end-to-end encrypted.'),
          const _InfoAction(
              icon: DocmacIconlyLight.activity,
              title: 'Disappearing messages',
              subtitle: 'Off'),
          SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
            secondary: const Icon(DocmacIconlyLight.lock),
            title: const Text('Chat lock'),
            subtitle: const Text('Lock and hide this chat on this device.'),
            value: _chatLock,
            onChanged: (value) => setState(() => _chatLock = value),
          ),
          const _InfoAction(
              icon: DocmacIconlyLight.discovery,
              title: 'Phone number privacy',
              subtitle: 'Your phone number is visible in this Circle.'),
          const Divider(height: 28),
          _InfoAction(
              icon: DocmacIconlyLight.danger,
              title: 'Report announcements',
              destructive: true,
              onTap: () {}),
        ],
      );
}

class _CircleSummary extends StatelessWidget {
  const _CircleSummary({required this.circle, this.compact = false});

  final _Circle circle;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(24, compact ? 4 : 12, 24, compact ? 0 : 8),
        child: Column(
          children: [
            _CircleEmblem(size: compact ? 74 : 96, showAccent: false),
            const SizedBox(height: 10),
            Text(circle.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            Text('Circle · ${circle.groups.length} groups',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}

class _CircleEmblem extends StatelessWidget {
  const _CircleEmblem(
      {required this.size, required this.showAccent, this.destructive = false});

  final double size;
  final bool showAccent;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(size * .24)),
          alignment: Alignment.center,
          child: Icon(DocmacIconlyLight.addUser,
              size: size * .46, color: colors.onPrimaryContainer),
        ),
        if (showAccent || destructive)
          Positioned(
            right: -3,
            bottom: -3,
            child: CircleAvatar(
              radius: size * .13,
              backgroundColor: destructive ? colors.error : colors.primary,
              foregroundColor: destructive ? colors.onError : colors.onPrimary,
              child: Icon(
                  destructive
                      ? DocmacIconlyLight.closeSquare
                      : DocmacIconlyLight.plus,
                  size: size * .15),
            ),
          ),
      ],
    );
  }
}

class _CircleRow extends StatelessWidget {
  const _CircleRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.iconBackground,
      this.trailing});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconBackground;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: iconBackground ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      );
}

class _InfoAction extends StatelessWidget {
  const _InfoAction(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.onTap,
      this.destructive = false,
      this.emphasized = false});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = destructive
        ? colors.error
        : emphasized
            ? colors.primary
            : colors.onSurfaceVariant;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}

class _SettingCopy extends StatelessWidget {
  const _SettingCopy(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow(
      {required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CircleStore {
  _CircleStore._();

  static _Circle? current;

  static void create(String name, String description) {
    current =
        _Circle(name: name, description: description, groups: ['General']);
  }
}

class _Circle {
  _Circle(
      {required this.name, required this.description, required this.groups});

  final String name;
  String description;
  final List<String> groups;
  int members = 1;
}
