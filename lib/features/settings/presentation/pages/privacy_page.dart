import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/ui/docmac_iconly.dart';

/// User-controlled presence and visibility preferences for the Phase 1 MVP.
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  static const _keys = [
    'last_seen',
    'presence',
    'photo',
    'bio',
    'moments',
    'receipts',
    'typing',
    'archive_unknown',
    'sync_contacts',
    'suggest_contacts',
    'link_previews',
  ];
  static const _audienceDefaults = <String, String>{
    'phone_number': 'Nobody',
    'last_seen_online': 'Nobody',
    'profile_photo': 'Everybody',
    'forwarded_messages': 'Nobody',
    'calls': 'Nobody',
    'voice_messages': 'Everybody',
    'messages': 'Everybody',
    'birthday': 'Nobody',
    'gifts': 'Everybody',
    'bio_visibility': 'Everybody',
    'saved_music': 'Everybody',
    'invites': 'Everybody',
    'delete_after': '18 months',
    'map_preview': 'No previews',
  };
  final values = <String, bool>{};
  final audiences = <String, String>{};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final key in _keys) {
        values[key] = preferences.getBool('docmac_privacy_$key') ??
            (key != 'archive_unknown' && key != 'link_previews');
      }
      for (final entry in _audienceDefaults.entries) {
        audiences[entry.key] =
            preferences.getString('docmac_privacy_${entry.key}') ?? entry.value;
      }
      loading = false;
    });
  }

  Future<void> _set(String key, bool value) async {
    setState(() => values[key] = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('docmac_privacy_$key', value);
  }

  Future<void> _setAudience(String key, String value) async {
    setState(() => audiences[key] = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('docmac_privacy_$key', value);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and security')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Text(
                'You decide what your people can see and how Docmac uses your data.',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
                'Docmac does not infer or display activity you did not choose to share.'),
            const SizedBox(height: 22),
            _choiceSection(context, 'Privacy', const [
              _PrivacyChoice('phone_number', 'Phone number'),
              _PrivacyChoice('last_seen_online', 'Last seen and online'),
              _PrivacyChoice('profile_photo', 'Profile photo'),
              _PrivacyChoice('forwarded_messages', 'Forwarded messages'),
              _PrivacyChoice('calls', 'Calls'),
              _PrivacyChoice('voice_messages', 'Voice messages'),
              _PrivacyChoice('messages', 'Messages'),
              _PrivacyChoice('birthday', 'Birthday'),
              _PrivacyChoice('gifts', 'Gifts'),
              _PrivacyChoice('bio_visibility', 'Bio'),
              _PrivacyChoice('saved_music', 'Saved music'),
              _PrivacyChoice('invites', 'Invites'),
            ]),
            const SizedBox(height: 22),
            _section(context, 'Profile details', [
              const _PrivacyItem(
                  'last_seen', 'Last seen', 'Show when you were last active'),
              const _PrivacyItem('presence', 'Presence',
                  'Let people see when you are available'),
              const _PrivacyItem(
                  'photo', 'Profile photo', 'Show your profile photo'),
              const _PrivacyItem(
                  'bio', 'Bio', 'Show the words you choose about yourself'),
              const _PrivacyItem(
                  'moments', 'Moments', 'Allow people to see your moments'),
            ]),
            const SizedBox(height: 22),
            _section(context, 'Talk', [
              const _PrivacyItem('receipts', 'Read receipts',
                  'Let people know you read their talk'),
              const _PrivacyItem('typing', 'Typing indicator',
                  'Let people know you are typing'),
            ]),
            const SizedBox(height: 22),
            _section(context, 'New talks from unknown people', [
              const _PrivacyItem('archive_unknown', 'Archive and mute',
                  'Automatically archive new talks from people you do not know'),
            ]),
            const SizedBox(height: 22),
            _choiceSection(context, 'Delete my account', const [
              _PrivacyChoice('delete_after', 'If away for'),
            ]),
            const SizedBox(height: 22),
            _actionSection(context, 'Bots and websites', [
              const _PrivacyAction('Clear payment and shipping info',
                  'Remove saved checkout details'),
              const _PrivacyAction('Logged in with Docmac',
                  'Websites where you use Docmac to log in'),
            ]),
            const SizedBox(height: 22),
            _section(context, 'Contacts', [
              const _PrivacyItem('sync_contacts', 'Sync contacts',
                  'Keep your device contacts available in Docmac'),
              const _PrivacyItem(
                  'suggest_contacts',
                  'Suggest frequent contacts',
                  'Show people you talk with often near search'),
            ]),
            const SizedBox(height: 22),
            _choiceSection(context, 'Secret talks', const [
              _PrivacyChoice('map_preview', 'Map preview provider'),
            ]),
            _section(context, '', [
              const _PrivacyItem('link_previews', 'Link previews',
                  'Show previews for links in private talks'),
            ]),
            const SizedBox(height: 22),
            ListTile(
                leading: const Icon(DocmacIconlyLight.danger),
                title: const Text('Blocked people'),
                subtitle: const Text('No blocked people'),
                trailing: const Icon(DocmacIconlyLight.arrowRight, size: 18),
                onTap: () => _notice('Blocked people will appear here.')),
            ListTile(
                leading: const Icon(DocmacIconlyLight.volumeOff),
                title: const Text('Muted people'),
                subtitle: const Text('No muted people'),
                trailing: const Icon(DocmacIconlyLight.arrowRight, size: 18),
                onTap: () => _notice('Muted people will appear here.')),
          ]),
    );
  }

  Widget _section(
          BuildContext context, String heading, List<_PrivacyItem> items) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (heading.isNotEmpty) ...[
          Text(heading, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
        ],
        Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor)),
            child: Column(children: [
              for (final item in items)
                SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(item.title),
                    subtitle: Text(item.subtitle),
                    value: values[item.key]!,
                    onChanged: (value) => _set(item.key, value)),
            ]),
          ),
        ),
      ]);

  Widget _choiceSection(
          BuildContext context, String heading, List<_PrivacyChoice> items) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(heading, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor)),
            child: Column(children: [
              for (final item in items)
                ListTile(
                  title: Text(item.title),
                  trailing: Text(audiences[item.key]!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)),
                  onTap: () => _chooseAudience(item),
                ),
            ]),
          ),
        ),
      ]);

  Widget _actionSection(
          BuildContext context, String heading, List<_PrivacyAction> items) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(heading, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor)),
            child: Column(children: [
              for (final item in items)
                ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.detail),
                  trailing: const Icon(DocmacIconlyLight.arrowRight, size: 18),
                  onTap: () => _notice('${item.title} is ready to configure.'),
                ),
            ]),
          ),
        ),
      ]);

  Future<void> _chooseAudience(_PrivacyChoice item) async {
    final choices = item.key == 'delete_after'
        ? const ['1 month', '6 months', '12 months', '18 months']
        : item.key == 'map_preview'
            ? const ['No previews', 'OpenStreetMap', 'Google Maps']
            : const ['Everybody', 'My people', 'Nobody'];
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final choice in choices)
              ListTile(
                title: Text(choice),
                trailing: audiences[item.key] == choice
                    ? Icon(DocmacIconlyLight.tickSquare,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(context, choice),
              ),
          ],
        ),
      ),
    );
    if (choice != null) await _setAudience(item.key, choice);
  }

  void _notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class _PrivacyItem {
  const _PrivacyItem(this.key, this.title, this.subtitle);
  final String key;
  final String title;
  final String subtitle;
}

class _PrivacyChoice {
  const _PrivacyChoice(this.key, this.title);
  final String key;
  final String title;
}

class _PrivacyAction {
  const _PrivacyAction(this.title, this.detail);
  final String title;
  final String detail;
}
