import 'package:flutter/material.dart';

import '../../../../core/ui/docmac_iconly.dart';

/// Honest placeholder for media storage and download settings.
///
/// Chat currently sends text only. The previous screen showed invented storage
/// and data-usage figures and stored download toggles locally while implying
/// media was being downloaded. Nothing here can change real download behavior
/// yet, so every control is disabled and labelled.
class DataStoragePage extends StatelessWidget {
  const DataStoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Data and storage')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: scheme.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Media messages, downloads, and gallery saving are not '
                    'available yet. Docmac sends text only, so these controls '
                    'are disabled instead of pretending to work.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SettingsCard(
            title: 'Disk and network usage',
            children: [
              _InfoRow(
                icon: DocmacIconlyLight.graph,
                label: 'Storage usage',
                value: 'No media stored',
              ),
              _InfoRow(
                icon: DocmacIconlyLight.activity,
                label: 'Data usage',
                value: 'Not tracked',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SettingsCard(
            title: 'Automatic media download',
            children: [
              _UnavailableRow(
                label: 'When using mobile data',
                detail: 'Not available yet',
              ),
              _UnavailableRow(
                label: 'When connected to Wi-Fi',
                detail: 'Not available yet',
              ),
              _UnavailableRow(
                label: 'When roaming',
                detail: 'Not available yet',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SettingsCard(
            title: 'Save to gallery',
            children: [
              _UnavailableRow(
                  label: 'Private talks', detail: 'Not available yet'),
              _UnavailableRow(label: 'Circles', detail: 'Not available yet'),
              _UnavailableRow(label: 'Channels', detail: 'Not available yet'),
            ],
          ),
          const SizedBox(height: 18),
          const _SettingsCard(
            title: 'Streaming',
            children: [
              _UnavailableRow(
                label: 'Stream videos and audio files',
                detail: 'Not available yet',
              ),
            ],
          ),
        ],
      ),
    );
  }
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
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              ...children,
            ],
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(label),
        trailing: Text(
          value,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
}

class _UnavailableRow extends StatelessWidget {
  const _UnavailableRow({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        title: Text(label),
        subtitle: Text(detail),
        value: false,
        onChanged: null,
      );
}
