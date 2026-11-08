import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WhatsApp-style Lists settings page and Edit Lists modal (Images 3 & 4).
/// Allows creating custom chat filter lists, reordering them, and managing presets.
class ListsSettingsPage extends StatefulWidget {
  const ListsSettingsPage({super.key});

  @override
  State<ListsSettingsPage> createState() => _ListsSettingsPageState();
}

class _ListItemData {
  const _ListItemData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    this.isPreset = true,
  });

  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final bool isPreset;
}

class _ListsSettingsPageState extends State<ListsSettingsPage> {
  static const _activeListsKey = 'docmac_user_lists_order';
  static const _removedPresetsKey = 'docmac_removed_preset_lists';

  static const _defaultLists = [
    _ListItemData(
      id: 'unread',
      name: 'Unread',
      subtitle: 'Preset',
      icon: Icons.mark_chat_unread_outlined,
      isPreset: true,
    ),
    _ListItemData(
      id: 'favorites',
      name: 'Favorites',
      subtitle: 'Add people or groups',
      icon: Icons.favorite_border_rounded,
      isPreset: true,
    ),
    _ListItemData(
      id: 'groups',
      name: 'Groups',
      subtitle: 'Preset',
      icon: Icons.group_outlined,
      isPreset: true,
    ),
  ];

  late List<_ListItemData> _activeLists = List.of(_defaultLists);
  List<_ListItemData> _availablePresets = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_activeListsKey);
    final removedIds = prefs.getStringList(_removedPresetsKey) ?? [];

    if (savedIds != null && savedIds.isNotEmpty) {
      final loaded = <_ListItemData>[];
      for (final id in savedIds) {
        final match = _defaultLists.where((item) => item.id == id).firstOrNull;
        if (match != null) {
          loaded.add(match);
        } else {
          // Custom user list
          loaded.add(_ListItemData(
            id: id,
            name: id,
            subtitle: 'Custom',
            icon: Icons.list_alt_rounded,
            isPreset: false,
          ));
        }
      }
      _activeLists = loaded;
    }

    _availablePresets.clear();
    for (final id in removedIds) {
      final match = _defaultLists.where((item) => item.id == id).firstOrNull;
      if (match != null) {
        _availablePresets.add(match);
      }
    }

    if (mounted) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _saveLists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _activeListsKey,
      _activeLists.map((item) => item.id).toList(),
    );
    await prefs.setStringList(
      _removedPresetsKey,
      _availablePresets.map((item) => item.id).toList(),
    );
  }

  void _openEditLists() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditListsSheet(
        activeLists: List.of(_activeLists),
        availablePresets: List.of(_availablePresets),
        onSaved: (newActive, newAvailable) {
          setState(() {
            _activeLists = newActive;
            _availablePresets = newAvailable;
          });
          _saveLists();
        },
      ),
    );
  }

  void _createCustomList() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Create a custom list'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'List name (e.g. Work, Family)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogCtx);
                setState(() {
                  _activeLists.add(_ListItemData(
                    id: name,
                    name: name,
                    subtitle: 'Custom',
                    icon: Icons.list_alt_rounded,
                    isPreset: false,
                  ));
                });
                _saveLists();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit lists',
            onPressed: _openEditLists,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          // Graphic: Stacked Chips (Chat, Heart, Plus)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ChipGraphic(
                    icon: Icons.chat_bubble_rounded,
                    color: isDark
                        ? const Color(0xFF2E9C92)
                        : const Color(0xFF1B6B48),
                  ),
                  const SizedBox(width: 8),
                  _ChipGraphic(
                    icon: Icons.favorite_rounded,
                    color: isDark
                        ? const Color(0xFF2E9C92)
                        : const Color(0xFF1B6B48),
                  ),
                  const SizedBox(width: 8),
                  _ChipGraphic(
                    icon: Icons.add_rounded,
                    color: isDark
                        ? const Color(0xFF2E9C92)
                        : const Color(0xFF1B6B48),
                  ),
                ],
              ),
            ),
          ),

          Text(
            'Focus on who matters most.\nEasily send and share across Docmac.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Lists are saved on this device only. They do not filter the '
              'Talk inbox yet.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // "+ Create a custom list" pill button
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(24),
              ),
              child: InkWell(
                onTap: _createCustomList,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18, color: scheme.onSurface),
                      const SizedBox(width: 8),
                      Text(
                        'Create a custom list',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 16),

          // Your lists section
          Text(
            'Your lists',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          for (final item in _activeLists)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.icon, color: scheme.onSurfaceVariant),
              title: Text(item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(item.subtitle,
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
              onTap: _openEditLists,
            ),

          const SizedBox(height: 24),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 16),

          // Available presets section
          Text(
            'Available presets',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          if (_availablePresets.isEmpty)
            Text(
              'If you remove a preset list like Unread or Groups, it will become available here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            )
          else
            for (final item in _availablePresets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(item.icon, color: scheme.onSurfaceVariant),
                title: Text(item.name),
                subtitle: const Text('Tap to add back'),
                trailing: Icon(Icons.add_circle_outline_rounded,
                    color: scheme.primary),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _availablePresets.remove(item);
                    _activeLists.add(item);
                  });
                  _saveLists();
                },
              ),
        ],
      ),
    );
  }
}

class _ChipGraphic extends StatelessWidget {
  const _ChipGraphic({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

/// Edit Lists modal bottom sheet (Image 3)
class _EditListsSheet extends StatefulWidget {
  const _EditListsSheet({
    required this.activeLists,
    required this.availablePresets,
    required this.onSaved,
  });

  final List<_ListItemData> activeLists;
  final List<_ListItemData> availablePresets;
  final void Function(List<_ListItemData> active, List<_ListItemData> available)
      onSaved;

  @override
  State<_EditListsSheet> createState() => _EditListsSheetState();
}

class _EditListsSheetState extends State<_EditListsSheet> {
  late List<_ListItemData> _active;
  late List<_ListItemData> _available;

  @override
  void initState() {
    super.initState();
    _active = List.of(widget.activeLists);
    _available = List.of(widget.availablePresets);
  }

  void _deleteItem(int index) {
    HapticFeedback.selectionClick();
    final item = _active.removeAt(index);
    if (item.isPreset) {
      _available.add(item);
    }
    setState(() {});
  }

  void _restoreItem(int index) {
    HapticFeedback.selectionClick();
    final item = _available.removeAt(index);
    _active.add(item);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Header: Cancel (X) - Title "Edit Lists" - Save (Checkmark)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Edit Lists',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_rounded),
                    tooltip: 'Save',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      widget.onSaved(_active, _available);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'You can edit lists and filters here or reorder how they appear on the Chats tab.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: theme.dividerColor, height: 1),

            // Reorderable lists
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
              child: Text(
                'Your lists',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _active.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _active.removeAt(oldIndex);
                  _active.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final item = _active[index];
                return ListTile(
                  key: ValueKey(item.id),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(item.icon, color: scheme.onSurfaceVariant),
                  title: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(item.subtitle,
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 13)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline_rounded, size: 20),
                        tooltip: 'Delete',
                        onPressed: () => _deleteItem(index),
                      ),
                      const SizedBox(width: 4),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle_rounded, size: 22),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 14),
            Divider(color: theme.dividerColor, height: 1),

            // Available presets section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
              child: Text(
                'Available presets',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            if (_available.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
                child: Text(
                  'If you remove a preset list like Unread or Groups, it will become available here.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              )
            else
              for (int i = 0; i < _available.length; i++)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading:
                      Icon(_available[i].icon, color: scheme.onSurfaceVariant),
                  title: Text(_available[i].name),
                  trailing: IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded,
                        color: scheme.primary),
                    onPressed: () => _restoreItem(i),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
