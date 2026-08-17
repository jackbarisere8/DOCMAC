import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/ui/docmac_iconly.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          actions: [
            IconButton(
              tooltip: 'Search settings',
              onPressed: () => showSearch<void>(
                context: context,
                delegate: _SettingsSearchDelegate(),
              ),
              icon: const Icon(DocmacIconlyLight.search),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: const Icon(DocmacIconlyLight.profile),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('Your Orbit',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontSize: 16))),
                  const Icon(DocmacIconlyLight.scan),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SettingsRow(
                icon: DocmacIconlyLight.user,
                label: 'Account',
                subtitle: 'Identity, username, and recovery',
                onTap: () => context.push('/settings/account')),
            _SettingsRow(
                icon: DocmacIconlyLight.shieldDone,
                label: 'Privacy',
                subtitle: 'Presence, moments, and conversation controls',
                onTap: () => context.push('/privacy')),
            _SettingsRow(
                icon: DocmacIconlyLight.lock,
                label: 'Security',
                subtitle: 'Passcode, devices, and account protection',
                onTap: () => context.push('/settings/app-lock')),
            _SettingsRow(
                icon: DocmacIconlyLight.category,
                label: 'Lists',
                subtitle: 'Circles, spaces, and invitations',
                onTap: () => _notice(
                    context, 'Your circles and lists are ready to manage.')),
            _SettingsRow(
                icon: DocmacIconlyLight.chat,
                label: 'Talks',
                subtitle: 'Wallpaper and message preferences',
                onTap: () => context.push('/chat/theme')),
            _SettingsRow(
                icon: DocmacIconlyLight.notification,
                label: 'Arrivals',
                subtitle: 'Sounds, calls, badges, and invitations',
                onTap: () => context.push('/notifications')),
            _SettingsRow(
                icon: DocmacIconlyLight.graph,
                label: 'Storage and data',
                subtitle: 'Media downloads, cache, and data usage',
                onTap: () => context.push('/storage')),
            _SettingsRow(
                icon: DocmacIconlyLight.discovery,
                label: 'Connections',
                subtitle: 'People and services connected to your Orbit',
                onTap: () => context.push('/settings/connections')),
            _SettingsRow(
                icon: DocmacIconlyLight.show,
                label: 'Accessibility',
                subtitle: 'Make Docmac work more comfortably for you',
                onTap: () => context.push('/settings/accessibility')),
            _SettingsRow(
                icon: DocmacIconlyLight.discovery,
                label: 'App language',
                subtitle: 'English',
                onTap: () => context.push('/settings/language')),
            _SettingsRow(
                icon: DocmacIconlyLight.infoCircle,
                label: 'Help and feedback',
                subtitle: 'Support, feedback, and product help',
                onTap: () => context.push('/help')),
            const SizedBox(height: 8),
            _SettingsRow(
                icon: DocmacIconlyLight.show,
                label: 'Appearance',
                subtitle: 'Light, dark, and system appearance',
                onTap: () => context.push('/appearance')),
            _SettingsRow(
                icon: DocmacIconlyLight.work,
                label: 'Foundry',
                subtitle: 'Creator impact, rewards, and insights',
                onTap: () => context.push('/foundry')),
          ],
        ),
      );

  static void _notice(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.onTap});

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        ),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: const Icon(DocmacIconlyLight.arrowRight, size: 18),
        onTap: onTap,
      );
}

class _SettingsSearchDelegate extends SearchDelegate<void> {
  static const _settings = [
    'Account',
    'Privacy',
    'Security',
    'Lists',
    'Talks',
    'Arrivals',
    'Storage and data',
    'Connections',
    'Accessibility',
    'App language',
    'Help and feedback',
    'Appearance',
    'Foundry',
  ];

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            tooltip: 'Clear search',
            onPressed: () => query = '',
            icon: const Icon(DocmacIconlyLight.closeSquare),
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        tooltip: 'Close search',
        onPressed: () => close(context, null),
        icon: const Icon(DocmacIconlyLight.arrowLeft),
      );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final matches = _settings
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (matches.isEmpty) {
      return const Center(child: Text('No settings found.'));
    }
    return ListView(
      children: [
        for (final item in matches)
          ListTile(
            leading: const Icon(DocmacIconlyLight.setting),
            title: Text(item),
            onTap: () {
              close(context, null);
              if (item == 'Arrivals') {
                context.push('/notifications');
              } else if (item == 'Appearance') {
                context.push('/appearance');
              } else if (item == 'Account') {
                context.push('/settings/account');
              } else if (item == 'Privacy') {
                context.push('/privacy');
              } else if (item == 'Security') {
                context.push('/settings/app-lock');
              } else if (item == 'Foundry') {
                context.push('/foundry');
              } else if (item == 'Storage and data') {
                context.push('/storage');
              } else if (item == 'Help and feedback') {
                context.push('/help');
              } else if (item == 'Connections') {
                context.push('/settings/connections');
              } else if (item == 'Accessibility') {
                context.push('/settings/accessibility');
              } else if (item == 'App language') {
                context.push('/settings/language');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$item is ready to configure.')),
                );
              }
            },
          ),
      ],
    );
  }
}

class ConnectionSettingsPage extends StatefulWidget {
  const ConnectionSettingsPage({super.key});

  @override
  State<ConnectionSettingsPage> createState() => _ConnectionSettingsPageState();
}

class _ConnectionSettingsPageState extends State<ConnectionSettingsPage> {
  bool _contactSync = false;
  bool _suggestions = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Connections')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Text('Keep your circle intentional',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Choose how Docmac finds and suggests people to you.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sync contacts'),
              subtitle: const Text('Find people you already know'),
              value: _contactSync,
              onChanged: (value) => setState(() => _contactSync = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Connection suggestions'),
              subtitle: const Text('Suggest people you may want to add'),
              value: _suggestions,
              onChanged: (value) => setState(() => _suggestions = value),
            ),
            const SizedBox(height: 12),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(DocmacIconlyLight.discovery),
              title: const Text('Connected services'),
              subtitle: const Text('No services connected'),
              trailing: const Icon(DocmacIconlyLight.arrowRight, size: 18),
              onTap: () => _notice('There are no connected services yet.'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(DocmacIconlyLight.hide),
              title: const Text('Blocked connections'),
              subtitle: const Text('Review people you have blocked'),
              trailing: const Icon(DocmacIconlyLight.arrowRight, size: 18),
              onTap: () => _notice('You have no blocked connections.'),
            ),
          ],
        ),
      );

  void _notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() =>
      _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  double _textSize = 1;
  bool _reduceMotion = false;
  bool _haptics = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Accessibility')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Text('Make Docmac yours',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Adjust the app so it is easier and more comfortable to use.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Text('Text size', style: Theme.of(context).textTheme.labelLarge),
            Slider(
              value: _textSize,
              min: .85,
              max: 1.25,
              divisions: 4,
              label: '${(_textSize * 100).round()}%',
              onChanged: (value) => setState(() => _textSize = value),
            ),
            Text('Preview text',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 15 * _textSize,
                    )),
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reduce motion'),
              subtitle: const Text('Limit animations throughout the app'),
              value: _reduceMotion,
              onChanged: (value) => setState(() => _reduceMotion = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Haptic feedback'),
              subtitle: const Text('Feel gentle taps when you interact'),
              value: _haptics,
              onChanged: (value) => setState(() => _haptics = value),
            ),
          ],
        ),
      );
}

class AppLanguageSettingsPage extends StatefulWidget {
  const AppLanguageSettingsPage({super.key});

  @override
  State<AppLanguageSettingsPage> createState() => _AppLanguageSettingsPageState();
}

class _AppLanguageSettingsPageState extends State<AppLanguageSettingsPage> {
  String _language = 'English';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('App language')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Text('Choose your language',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('This changes the language used throughout Docmac.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            for (final language in const ['English', 'Français', 'Español'])
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(language),
                value: language,
                groupValue: _language,
                onChanged: (value) {
                  if (value != null) setState(() => _language = value);
                },
              ),
          ],
        ),
      );
}

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const _AccountAction(
                icon: DocmacIconlyLight.shieldDone, label: 'Security alerts'),
            const _AccountAction(
                icon: DocmacIconlyLight.password, label: 'Passkeys'),
            const _AccountAction(
                icon: DocmacIconlyLight.message, label: 'Email address'),
            const _AccountAction(
                icon: DocmacIconlyLight.call, label: 'Change phone number'),
            const _AccountAction(
                icon: DocmacIconlyLight.shieldDone,
                label: 'Two-step verification'),
            const SizedBox(height: 10),
            Divider(color: Theme.of(context).dividerColor),
            const _AccountAction(
                icon: DocmacIconlyLight.delete,
                label: 'Delete account',
                isDestructive: true),
          ],
        ),
      );
}

class _AccountAction extends StatelessWidget {
  const _AccountAction(
      {required this.icon, required this.label, this.isDestructive = false});

  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: Icon(icon,
            color: isDestructive
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.secondary),
        title: Text(label,
            style: isDestructive
                ? TextStyle(color: Theme.of(context).colorScheme.error)
                : null),
        trailing: const Icon(DocmacIconlyLight.arrowRight, size: 18),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label is ready to configure.')),
        ),
      );
}

class AppLockSettingsPage extends StatefulWidget {
  const AppLockSettingsPage({super.key});

  @override
  State<AppLockSettingsPage> createState() => _AppLockSettingsPageState();
}

class _AppLockSettingsPageState extends State<AppLockSettingsPage> {
  static const _enabledKey = 'docmac_app_lock_enabled';
  static const _pinKey = 'docmac_app_lock_pin';
  final _pinController = TextEditingController();
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled = preferences.getBool(_enabledKey) ?? false;
      _pinController.text = preferences.getString(_pinKey) ?? '';
      _loading = false;
    });
  }

  Future<void> _setEnabled(bool value) async {
    if (value && _pinController.text.trim().length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a 4-digit passcode first.')),
      );
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, value);
    if (mounted) setState(() => _enabled = value);
  }

  Future<void> _savePasscode() async {
    if (_pinController.text.trim().length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your passcode must contain 4 digits.')),
      );
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pinKey, _pinController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passcode saved. App lock is ready.')),
    );
  }

  Future<void> _lockNow() async {
    final savedPin = (await SharedPreferences.getInstance()).getString(_pinKey);
    if (!mounted || savedPin == null || savedPin.length != 4) return;
    final unlockController = TextEditingController();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(DocmacIconlyLight.lock),
            SizedBox(width: 10),
            Text('Docmac locked')
          ],
        ),
        content: TextField(
          controller: unlockController,
          autofocus: true,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(labelText: 'Enter passcode'),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              if (unlockController.text == savedPin) {
                Navigator.pop(dialogContext);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('That passcode does not match.')),
                );
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    unlockController.dispose();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Lock app')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Text('Keep your talks private',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Set a passcode and use it whenever you lock Docmac.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 26),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(labelText: '4-digit passcode'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
              onPressed: _savePasscode, child: const Text('Save passcode')),
          const SizedBox(height: 18),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lock app'),
            subtitle: Text(_enabled ? 'App lock is on' : 'App lock is off'),
            value: _enabled,
            onChanged: _setEnabled,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _enabled ? _lockNow : null,
            icon: const Icon(DocmacIconlyLight.lock),
            label: const Text('Lock now'),
          ),
        ],
      ),
    );
  }
}
