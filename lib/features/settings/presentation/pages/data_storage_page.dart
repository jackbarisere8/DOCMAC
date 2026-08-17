import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/ui/docmac_iconly.dart';

class DataStoragePage extends StatefulWidget {
  const DataStoragePage({super.key});

  @override
  State<DataStoragePage> createState() => _DataStoragePageState();
}

class _DataStoragePageState extends State<DataStoragePage> {
  static const _toggleKeys = [
    'mobile_download',
    'wifi_download',
    'roaming_download',
    'gallery_private',
    'gallery_circles',
    'gallery_channels',
    'stream_media',
  ];

  final _values = <String, bool>{};
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
      for (final key in _toggleKeys) {
        _values[key] = preferences.getBool('docmac_storage_$key') ??
            (key == 'wifi_download' || key == 'stream_media');
      }
      _loading = false;
    });
  }

  Future<void> _set(String key, bool value) async {
    setState(() => _values[key] = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('docmac_storage_$key', value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Data and storage')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          _SettingsCard(
            title: 'Disk and network usage',
            children: [
              _ActionRow(
                icon: DocmacIconlyLight.graph,
                label: 'Storage usage',
                value: '767.8 MB',
                onTap: () => _notice('Storage management is ready to open.'),
              ),
              _ActionRow(
                icon: DocmacIconlyLight.activity,
                label: 'Data usage',
                value: '15.49 GB',
                onTap: () => _notice('Data-usage details are ready to open.'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsCard(
            title: 'Automatic media download',
            children: [
              _ToggleRow(
                label: 'When using mobile data',
                detail: 'Photos, videos (10 MB), files (1 MB)',
                value: _values['mobile_download']!,
                onChanged: (value) => _set('mobile_download', value),
              ),
              _ToggleRow(
                label: 'When connected to Wi-Fi',
                detail: 'Photos, videos (15 MB), files (3 MB)',
                value: _values['wifi_download']!,
                onChanged: (value) => _set('wifi_download', value),
              ),
              _ToggleRow(
                label: 'When roaming',
                detail: 'Photos only',
                value: _values['roaming_download']!,
                onChanged: (value) => _set('roaming_download', value),
              ),
              ListTile(
                title: Text('Reset auto-download settings',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: _resetDownloads,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsCard(
            title: 'Save to gallery',
            children: [
              _ToggleRow(
                label: 'Private talks',
                detail: _values['gallery_private']! ? 'On' : 'Off',
                value: _values['gallery_private']!,
                onChanged: (value) => _set('gallery_private', value),
              ),
              _ToggleRow(
                label: 'Circles',
                detail: _values['gallery_circles']! ? 'On' : 'Off',
                value: _values['gallery_circles']!,
                onChanged: (value) => _set('gallery_circles', value),
              ),
              _ToggleRow(
                label: 'Channels',
                detail: _values['gallery_channels']! ? 'On' : 'Off',
                value: _values['gallery_channels']!,
                onChanged: (value) => _set('gallery_channels', value),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsCard(
            title: 'Streaming',
            children: [
              _ToggleRow(
                label: 'Stream videos and audio files',
                detail: 'Play media before it finishes downloading',
                value: _values['stream_media']!,
                onChanged: (value) => _set('stream_media', value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resetDownloads() async {
    for (final key in [
      'mobile_download',
      'wifi_download',
      'roaming_download'
    ]) {
      await _set(key, key == 'wifi_download');
    }
    if (mounted) _notice('Auto-download settings were reset.');
  }

  void _notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          )),
                ),
              ),
              ...children,
            ],
          ),
        ),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(label),
        trailing: Text(value,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        onTap: onTap,
      );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        title: Text(label),
        subtitle: Text(detail),
        value: value,
        onChanged: onChanged,
      );
}
