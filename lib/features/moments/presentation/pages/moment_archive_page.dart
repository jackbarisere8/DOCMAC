import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/feature_flags.dart';
import '../../../../core/ui/docmac_iconly.dart';

const _monthsShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

enum _ArchiveSort { newest, oldest, largest }

class _ArchivedMoment {
  const _ArchivedMoment({
    required this.id,
    required this.caption,
    required this.icon,
    required this.colors,
    required this.date,
    required this.sizeBytes,
    required this.duration,
  });

  final String id;
  final String caption;
  final IconData icon;
  final List<Color> colors;
  final DateTime date;
  final int sizeBytes;
  final String duration;
}

List<_ArchivedMoment> _seedArchive() => [
      _ArchivedMoment(
        id: 'archive-sunday-notes',
        caption: 'Sunday notes',
        icon: Icons.edit_note_rounded,
        colors: const [Color(0xFF1B2A41), Color(0xFF3E5C8A)],
        date: DateTime(2026, 10, 4, 9, 15),
        sizeBytes: 3040870,
        duration: '0:15',
      ),
      _ArchivedMoment(
        id: 'archive-good-read',
        caption: 'A good read',
        icon: Icons.menu_book_rounded,
        colors: const [Color(0xFF3B1E5E), Color(0xFF8B5CF6)],
        date: DateTime(2026, 10, 12, 14, 40),
        sizeBytes: 1153434,
        duration: '0:12',
      ),
      _ArchivedMoment(
        id: 'archive-small-wins',
        caption: 'Small wins',
        icon: Icons.emoji_events_rounded,
        colors: const [Color(0xFF6B3A12), Color(0xFFE09A2E)],
        date: DateTime(2026, 10, 22, 18, 5),
        sizeBytes: 135168,
        duration: '0:08',
      ),
      _ArchivedMoment(
        id: 'archive-new-idea',
        caption: 'New idea',
        icon: Icons.lightbulb_rounded,
        colors: const [Color(0xFF1A2740), Color(0xFF5B8DEF)],
        date: DateTime(2026, 10, 29, 7, 50),
        sizeBytes: 4096,
        duration: '0:10',
      ),
      _ArchivedMoment(
        id: 'archive-morning-light',
        caption: 'Morning light',
        icon: Icons.wb_sunny_rounded,
        colors: const [Color(0xFF123E3B), Color(0xFF17A6A0)],
        date: DateTime(2026, 11, 2, 6, 55),
        sizeBytes: 61440,
        duration: '0:20',
      ),
      _ArchivedMoment(
        id: 'archive-on-this-day',
        caption: 'On this day',
        icon: Icons.auto_awesome_rounded,
        colors: const [Color(0xFF3A1722), Color(0xFFE0657B)],
        date: DateTime(2026, 11, 5, 20, 10),
        sizeBytes: 12288,
        duration: '0:09',
      ),
    ];

/// The archive of moments that no longer sit inside the 24-hour window.
///
/// Mirrors the familiar status-archive layout: a dense thumbnail grid with
/// dates, durations and sizes, plus select-all and sorting.
class MomentArchivePage extends StatefulWidget {
  const MomentArchivePage({super.key});

  @override
  State<MomentArchivePage> createState() => _MomentArchivePageState();
}

class _MomentArchivePageState extends State<MomentArchivePage> {
  final List<_ArchivedMoment> _moments =
      AppFeatureFlags.localPreviews ? _seedArchive() : const [];
  final Set<String> _selected = <String>{};
  _ArchiveSort _sort = _ArchiveSort.newest;

  List<_ArchivedMoment> get _sortedMoments {
    final moments = List<_ArchivedMoment>.of(_moments);
    switch (_sort) {
      case _ArchiveSort.newest:
        moments.sort((a, b) => b.date.compareTo(a.date));
      case _ArchiveSort.oldest:
        moments.sort((a, b) => a.date.compareTo(b.date));
      case _ArchiveSort.largest:
        moments.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    }
    return moments;
  }

  bool get _allSelected =>
      _moments.isNotEmpty && _selected.length == _moments.length;

  int get _totalBytes =>
      _moments.fold(0, (total, moment) => total + moment.sizeBytes);

  String get _sortLabel => switch (_sort) {
        _ArchiveSort.newest => 'NEWEST',
        _ArchiveSort.oldest => 'OLDEST',
        _ArchiveSort.largest => 'SIZE',
      };

  void _setSort(_ArchiveSort sort) {
    HapticFeedback.selectionClick();
    setState(() => _sort = sort);
  }

  void _toggleAll(bool? value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (value == true) {
        _selected
          ..clear()
          ..addAll(_moments.map((moment) => moment.id));
      } else {
        _selected.clear();
      }
    });
  }

  void _toggleOne(_ArchivedMoment moment) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.remove(moment.id)) {
        _selected.add(moment.id);
      }
    });
  }

  void _deleteSelected() {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    setState(() {
      _moments.removeWhere((moment) => _selected.contains(moment.id));
      _selected.clear();
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            count == 1
                ? 'Preview only: removed from this local archive. '
                    'Nothing was deleted from Docmac.'
                : 'Preview only: $count moments removed from this local '
                    'archive. Nothing was deleted from Docmac.',
          ),
        ),
      );
  }

  void _openMoment(_ArchivedMoment moment) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _ArchivedMomentPreview(moment: moment),
      ),
    );
  }

  void _showArchiveInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your moment archive',
                style: Theme.of(sheetContext)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                AppFeatureFlags.localPreviews
                    ? 'This archive is a local preview. The moments shown here '
                        'are sample data, not real archived moments. Nothing '
                        'here is synced or shared.'
                    : 'Moment archiving is not available yet in this build.',
                style: Theme.of(sheetContext)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectionMode = _selected.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Moment archive'),
            const SizedBox(height: 2),
            Text(
              _formatSize(_totalBytes),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (selectionMode) ...[
            IconButton(
              tooltip: 'Delete selected',
              onPressed: _deleteSelected,
              icon: const Icon(DocmacIconlyLight.delete),
            ),
            IconButton(
              tooltip: 'Clear selection',
              onPressed: () => setState(_selected.clear),
              icon: const Icon(Icons.close_rounded),
            ),
          ] else
            PopupMenuButton<_ArchiveSort>(
              key: const ValueKey('moment-archive-sort'),
              tooltip: 'Sort archive',
              icon: const Icon(Icons.sort_rounded),
              onSelected: _setSort,
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: _ArchiveSort.newest,
                  checked: _sort == _ArchiveSort.newest,
                  child: const Text('Newest'),
                ),
                CheckedPopupMenuItem(
                  value: _ArchiveSort.oldest,
                  checked: _sort == _ArchiveSort.oldest,
                  child: const Text('Oldest'),
                ),
                CheckedPopupMenuItem(
                  value: _ArchiveSort.largest,
                  checked: _sort == _ArchiveSort.largest,
                  child: const Text('Largest'),
                ),
              ],
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _moments.isEmpty
          ? _ArchiveEmptyState(onBack: () => Navigator.of(context).pop())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 10, 10),
                  child: Row(
                    children: [
                      Text(
                        _sortLabel,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Select all',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 34,
                        height: 30,
                        child: Checkbox(
                          key: const ValueKey('moment-archive-select-all'),
                          value: _selected.isEmpty
                              ? false
                              : (_allSelected ? true : null),
                          tristate: true,
                          onChanged: _toggleAll,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: scheme.onSurfaceVariant,
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: _sortedMoments.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemBuilder: (context, index) {
                    final moment = _sortedMoments[index];
                    return _ArchiveTile(
                      moment: moment,
                      selected: _selected.contains(moment.id),
                      selectionMode: selectionMode,
                      onTap: () {
                        if (selectionMode) {
                          _toggleOne(moment);
                        } else {
                          _openMoment(moment);
                        }
                      },
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showArchiveInfo,
                    child: Text.rich(
                      TextSpan(
                        text: AppFeatureFlags.localPreviews
                            ? 'Preview archive. These sample moments stay on this screen. '
                            : 'Moment archiving is not available yet. ',
                        children: [
                          TextSpan(
                            text: 'Learn more',
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  const _ArchiveTile({
    required this.moment,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
  });

  final _ArchivedMoment moment;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      key: ValueKey('archive-tile-${moment.id}'),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: moment.colors,
                ),
              ),
            ),
            Positioned(
              right: -12,
              bottom: -10,
              child: Icon(
                moment.icon,
                size: 74,
                color: Colors.white.withValues(alpha: .13),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x44000000),
                      Color(0x00000000),
                      Color(0x55000000)
                    ],
                    stops: [0, .42, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                width: 32,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${moment.date.day}',
                      style: const TextStyle(
                        color: Color(0xFF111B21),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    Text(
                      _monthsShort[moment.date.month - 1],
                      style: const TextStyle(
                        color: Color(0xFF667781),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!selectionMode)
              Positioned(
                top: 7,
                right: 6,
                child: Text(
                  _formatSize(moment.sizeBytes),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .92),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Row(
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    moment.duration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (selectionMode && !selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .85),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            if (selected)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: .28),
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArchivedMomentPreview extends StatelessWidget {
  const _ArchivedMomentPreview({required this.moment});

  final _ArchivedMoment moment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moment.caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_longDate(moment.date)}  ·  ${moment.duration}  ·  ${_formatSize(moment.sizeBytes)}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          moment.colors.first,
                          moment.colors.last,
                          const Color(0xFF080A0F),
                        ],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: Icon(
                            moment.icon,
                            size: 170,
                            color: Colors.white.withValues(alpha: .10),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const _ArchiveTag(label: 'ARCHIVED'),
                                  const Spacer(),
                                  _ArchiveTag(
                                    label: moment.duration,
                                    icon: Icons.schedule_rounded,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                moment.caption,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  height: 1.28,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -.6,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x66000000),
                                      blurRadius: 18,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _longDate(moment.date),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveTag extends StatelessWidget {
  const _ArchiveTag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .24),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white70),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveEmptyState extends StatelessWidget {
  const _ArchiveEmptyState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 32,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your archive is empty',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Moment archiving is not available yet in this build.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
                onPressed: onBack, child: const Text('Back to moments')),
          ],
        ),
      ),
    );
  }
}

String _formatSize(int bytes) {
  const kilobyte = 1024;
  const megabyte = kilobyte * 1024;
  if (bytes >= megabyte) {
    return '${(bytes / megabyte).toStringAsFixed(1)} MB';
  }
  if (bytes >= kilobyte) {
    return '${(bytes / kilobyte).round()} KB';
  }
  return '$bytes B';
}

String _longDate(DateTime date) =>
    '${date.day} ${_monthsShort[date.month - 1]} ${date.year}';
