import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/feature_flags.dart';
import '../../../../core/ui/docmac_iconly.dart';
import '../../../../shared/widgets/docmac_menu_item.dart';
import 'moment_archive_page.dart';

const _defaultViewers = <_MomentViewerInfo>[
  _MomentViewerInfo('Amara Okafor', 'A', 'Just now', 0xFF34C759, '🔥'),
  _MomentViewerInfo('David Mensah', 'D', '2m ago', 0xFF5B8DEF, null),
  _MomentViewerInfo('Nora Williams', 'N', '6m ago', 0xFFB26BFF, '❤️'),
  _MomentViewerInfo('Tobi Adeyemi', 'T', '11m ago', 0xFFF0A13B, null),
  _MomentViewerInfo('Maya Chen', 'M', '18m ago', 0xFF17B6A3, '👏'),
  _MomentViewerInfo('Liam Brooks', 'L', '24m ago', 0xFFE0657B, null),
  _MomentViewerInfo('Sofia Reyes', 'S', '31m ago', 0xFF7C6BFF, null),
  _MomentViewerInfo('Noah Kim', 'N', '46m ago', 0xFF3AA7E0, '😂'),
];

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key, this.shareWith});

  final String? shareWith;

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  final List<_Moment> _myMoments = AppFeatureFlags.localPreviews
      ? [
          _Moment(
            id: 'mine-1',
            owner: 'You',
            handle: 'Your People',
            initial: 'Y',
            kindLabel: 'TEXT',
            caption: 'A quiet morning, a full heart.',
            icon: Icons.auto_awesome_rounded,
            tint: const Color(0xFF2F6BFF),
            expires: '22h left',
            views: _defaultViewers.length,
            viewers: List.of(_defaultViewers),
            isMine: true,
            audience: 'Your People',
          ),
        ]
      : <_Moment>[];

  final List<_Moment> _peopleMoments = AppFeatureFlags.localPreviews
      ? [
          const _Moment(
            id: 'emma-read',
            owner: 'Emma',
            handle: '@emma',
            initial: 'E',
            kindLabel: 'READ',
            caption: 'A good read',
            icon: Icons.menu_book_rounded,
            tint: Color(0xFF4A6CF7),
            expires: '2h left',
            views: 6,
            viewers: _defaultViewers,
            isMine: false,
            audience: 'Your People',
          ),
          const _Moment(
            id: 'david-win',
            owner: 'David',
            handle: '@davidm',
            initial: 'D',
            kindLabel: 'WIN',
            caption: 'Small wins',
            icon: Icons.emoji_events_rounded,
            tint: Color(0xFFE09A2E),
            expires: '6h left',
            views: 4,
            viewers: _defaultViewers,
            isMine: false,
            audience: 'Your People',
          ),
          const _Moment(
            id: 'nora-notes',
            owner: 'Nora',
            handle: '@noraw',
            initial: 'N',
            kindLabel: 'NOTES',
            caption: 'Sunday notes',
            icon: Icons.edit_note_rounded,
            tint: Color(0xFF9B6BFF),
            expires: '10h left',
            views: 8,
            viewers: _defaultViewers,
            isMine: false,
            audience: 'Your People',
          ),
        ]
      : <_Moment>[];

  final Set<String> _savedMoments = {};
  int _momentSequence = 0;

  Future<void> _createMoment({_MomentKind kind = _MomentKind.text}) async {
    HapticFeedback.selectionClick();
    final draft = await showModalBottomSheet<_MomentDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _CreateMomentSheet(
        shareWith: widget.shareWith,
        initialKind: kind,
      ),
    );
    if (draft == null || !mounted) return;

    final moment = _Moment(
      id: 'mine-${DateTime.now().microsecondsSinceEpoch}-${_momentSequence++}',
      owner: 'You',
      handle: draft.audience,
      initial: 'Y',
      kindLabel: draft.kind.label.toUpperCase(),
      caption: draft.caption,
      icon: draft.kind.icon,
      tint: draft.kind.tint,
      expires: AppFeatureFlags.localPreviews ? '24h left' : 'This session',
      views: 0,
      viewers: const [],
      isMine: true,
      audience: draft.audience,
    );

    setState(() => _myMoments.insert(0, moment));
    _showToast(
      context,
      'Moment added for this session. Sharing is not available yet.',
    );
  }

  Future<void> _openMoment(_Moment moment) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _MomentViewer(
          moment: moment,
          saved: _savedMoments.contains(moment.id),
          onCaptionChanged: (caption) => _updateMoment(
            moment.id,
            (current) => current.copyWith(caption: caption),
          ),
          onSavedChanged: (saved) => _setMomentSaved(moment.id, saved),
        ),
      ),
    );
    if (!mounted) return;
    if (deleted == true) _deleteMoment(moment);
  }

  void _updateMoment(String id, _Moment Function(_Moment) update) {
    setState(() {
      final mineIndex = _myMoments.indexWhere((moment) => moment.id == id);
      if (mineIndex >= 0) {
        _myMoments[mineIndex] = update(_myMoments[mineIndex]);
        return;
      }
      final peopleIndex =
          _peopleMoments.indexWhere((moment) => moment.id == id);
      if (peopleIndex >= 0) {
        _peopleMoments[peopleIndex] = update(_peopleMoments[peopleIndex]);
      }
    });
  }

  void _setMomentSaved(String id, bool saved) {
    setState(() {
      if (saved) {
        _savedMoments.add(id);
      } else {
        _savedMoments.remove(id);
      }
    });
  }

  void _deleteMoment(_Moment moment) {
    setState(() {
      _myMoments.removeWhere((item) => item.id == moment.id);
      _peopleMoments.removeWhere((item) => item.id == moment.id);
      _savedMoments.remove(moment.id);
    });
    _showToast(context, 'Moment removed for this session.');
  }

  Future<void> _handleMomentAction(_Moment moment, String action) async {
    switch (action) {
      case 'edit':
        final caption = await _promptMomentCaption(
          context,
          initial: moment.caption,
        );
        if (!mounted || caption == null) return;
        _updateMoment(
            moment.id, (current) => current.copyWith(caption: caption));
        _showToast(context, 'Caption updated for this session.');
        return;
      case 'delete':
        final confirmed = await _confirmMomentDelete(context, moment);
        if (!mounted || !confirmed) return;
        _deleteMoment(moment);
        return;
      case 'save':
        final saving = !_savedMoments.contains(moment.id);
        _setMomentSaved(moment.id, saving);
        _showToast(
          context,
          saving
              ? 'Saved for this session. Downloading a moment is not available yet.'
              : 'Removed from saved for this session.',
        );
        return;
      case 'share':
        _showShareMomentSheet(context, moment);
        return;
      case 'forward':
        _showForwardMomentSheet(context, moment);
        return;
      case 'report':
        _showReportMomentSheet(context, moment);
        return;
    }
  }

  void _showMomentInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => _MomentInfoSheet(
        onCreate: () {
          Navigator.of(sheetContext).pop();
          _createMoment();
        },
      ),
    );
  }

  void _openArchive() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const MomentArchivePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My moments'),
        actions: [
          IconButton(
            tooltip: 'About moments',
            onPressed: _showMomentInfo,
            icon: const Icon(Icons.info_outline_rounded, size: 22),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            key: const ValueKey('new-moment-text'),
            heroTag: 'new-moment-text',
            tooltip: 'Write a moment',
            onPressed: () => _createMoment(kind: _MomentKind.text),
            backgroundColor: scheme.surface,
            foregroundColor: scheme.onSurface,
            elevation: 2,
            child: const Icon(Icons.edit_rounded, size: 20),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            key: const ValueKey('new-moment'),
            heroTag: 'new-moment',
            tooltip: 'New moment',
            onPressed: () => _createMoment(kind: _MomentKind.photo),
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: const Icon(Icons.photo_camera_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 112),
        children: [
          if (widget.shareWith != null) ...[
            _SharingWithNotice(person: widget.shareWith!),
            const SizedBox(height: 16),
          ],
          _MomentSectionHeader(
            title: 'Your moments',
            detail: AppFeatureFlags.localPreviews
                ? 'Sample views on this device'
                : 'Visible only in this session',
            count: _myMoments.length,
          ),
          const SizedBox(height: 8),
          if (_myMoments.isNotEmpty)
            for (final moment in _myMoments) ...[
              _MomentCard(
                moment: moment,
                saved: _savedMoments.contains(moment.id),
                onOpen: () => _openMoment(moment),
                onViews: () => _showMomentViewers(context, moment),
                onAction: (action) => _handleMomentAction(moment, action),
              ),
              const SizedBox(height: 8),
            ]
          else ...[
            _StartMomentCard(
              onTap: () => _createMoment(kind: _MomentKind.text),
            ),
            const SizedBox(height: 8),
          ],
          _MomentArchiveTile(onTap: _openArchive),
          const SizedBox(height: 18),
          const _MomentExpiryNote(),
          const SizedBox(height: 28),
          _MomentSectionHeader(
            title: 'Your people',
            detail: AppFeatureFlags.localPreviews
                ? 'Sample moments in this preview'
                : 'Not available in this build',
            count: _peopleMoments.length,
          ),
          const SizedBox(height: 8),
          if (_peopleMoments.isEmpty)
            const _MomentEmptyNote(
              detail:
                  'Moments from other people are not available in this build.',
            )
          else
            for (final moment in _peopleMoments) ...[
              _MomentCard(
                moment: moment,
                saved: _savedMoments.contains(moment.id),
                onOpen: () => _openMoment(moment),
                onViews: () => _showMomentViewers(context, moment),
                onAction: (action) => _handleMomentAction(moment, action),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 14),
          const _MomentPrivacyNote(),
        ],
      ),
    );
  }
}

class _SharingWithNotice extends StatelessWidget {
  const _SharingWithNotice({required this.person});

  final String person;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: scheme.onSurface),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              AppFeatureFlags.localPreviews
                  ? 'Preview only: new moments stay in this session. Sharing with $person is not available yet.'
                  : 'New moments stay in this session only. Sharing with $person is not available yet.',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentEmptyNote extends StatelessWidget {
  const _MomentEmptyNote({required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 19, color: scheme.onSurface),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detail,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentSectionHeader extends StatelessWidget {
  const _MomentSectionHeader({
    required this.title,
    required this.detail,
    required this.count,
  });

  final String title;
  final String detail;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.3,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '$count',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.moment,
    required this.saved,
    required this.onOpen,
    required this.onViews,
    required this.onAction,
  });

  final _Moment moment;
  final bool saved;
  final VoidCallback onOpen;
  final VoidCallback onViews;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = moment.tint;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('moment-card-${moment.id}'),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 2, 10),
          child: Row(
            children: [
              _MomentAvatar(moment: moment),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            moment.isMine ? 'Your moment' : moment.owner,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              letterSpacing: -.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          moment.isMine ? 'Just now' : moment.expires,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      moment.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (moment.isMine)
                          _ViewsChip(
                            key: ValueKey('moment-views-${moment.id}'),
                            views: moment.views,
                            onTap: onViews,
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 13,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to view',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        if (moment.isMine)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                moment.expires,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        if (saved)
                          Icon(
                            DocmacIconlyBold.bookmark,
                            size: 12,
                            color: tint,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                key: ValueKey('moment-card-menu-${moment.id}'),
                tooltip: 'Moment options',
                onSelected: onAction,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                itemBuilder: (_) => _momentMenuEntries(
                  moment: moment,
                  saved: saved,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentAvatar extends StatelessWidget {
  const _MomentAvatar({required this.moment});

  final _Moment moment;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = moment.tint;
    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: tint.withValues(alpha: .55), width: 1.5),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tint.withValues(alpha: dark ? .24 : .16),
        ),
        child: Text(
          moment.initial,
          style: TextStyle(
            color: dark ? Colors.white : tint,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ViewsChip extends StatelessWidget {
  const _ViewsChip({
    super.key,
    required this.views,
    required this.onTap,
  });

  final int views;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(DocmacIconlyLight.show, size: 11, color: scheme.onSurface),
              const SizedBox(width: 4),
              Text(
                views == 0
                    ? 'No views yet'
                    : '$views ${views == 1 ? 'view' : 'views'}',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded,
                  size: 12, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentPrivacyNote extends StatelessWidget {
  const _MomentPrivacyNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(DocmacIconlyLight.lock, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            AppFeatureFlags.localPreviews
                ? 'Preview only: moments stay in this session. Nothing is sent to other people and no views are tracked.'
                : 'Moments stay in this session in this build. They are not shared with other people.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _MomentArchiveTile extends StatelessWidget {
  const _MomentArchiveTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('moment-archive'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moment archive',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Past moments kept outside the 24-hour window',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentExpiryNote extends StatelessWidget {
  const _MomentExpiryNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 12,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            AppFeatureFlags.localPreviews
                ? 'Preview only: moments stay in this session. Nothing is sent to other people.'
                : 'Saving, sharing, and view tracking are not available in this build.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _StartMomentCard extends StatelessWidget {
  const _StartMomentCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: scheme.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start a moment',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFeatureFlags.localPreviews
                          ? 'Add a thought, a photo, or a small win.'
                          : 'Write or capture a moment in this session.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentViewer extends StatefulWidget {
  const _MomentViewer({
    required this.moment,
    required this.saved,
    required this.onCaptionChanged,
    required this.onSavedChanged,
  });

  final _Moment moment;
  final bool saved;
  final ValueChanged<String> onCaptionChanged;
  final ValueChanged<bool> onSavedChanged;

  @override
  State<_MomentViewer> createState() => _MomentViewerState();
}

class _MomentViewerState extends State<_MomentViewer> {
  late String _caption = widget.moment.caption;
  late bool _saved = widget.saved;
  final Set<String> _reactions = {};

  int get _viewCount => widget.moment.views;

  Future<void> _handleMenu(String action) async {
    switch (action) {
      case 'edit':
        final caption = await _promptMomentCaption(context, initial: _caption);
        if (!mounted || caption == null) return;
        setState(() => _caption = caption);
        widget.onCaptionChanged(caption);
        _showToast(context, 'Caption updated for this session.');
        return;
      case 'delete':
        final confirmed = await _confirmMomentDelete(context, widget.moment);
        if (!mounted) return;
        if (confirmed) Navigator.of(context).pop(true);
        return;
      case 'save':
        final saving = !_saved;
        setState(() => _saved = saving);
        widget.onSavedChanged(saving);
        _showToast(
          context,
          saving
              ? 'Saved for this session. Downloading a moment is not available yet.'
              : 'Removed from saved for this session.',
        );
        return;
      case 'share':
        _showShareMomentSheet(context, widget.moment);
        return;
      case 'forward':
        _showForwardMomentSheet(context, widget.moment);
        return;
      case 'report':
        _showReportMomentSheet(context, widget.moment);
        return;
    }
  }

  void _showViewers() => _showMomentViewers(context, widget.moment);

  @override
  Widget build(BuildContext context) {
    final moment = widget.moment;
    final isMine = moment.isMine;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('moment-viewer-back'),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  _ViewerAvatar(moment: moment),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMine ? 'My moment' : moment.owner,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMine
                              ? (AppFeatureFlags.localPreviews
                                  ? '${moment.expires}  ·  ${moment.audience}'
                                  : 'Stays in this session  ·  Not shared')
                              : '${moment.handle}  ·  ${moment.expires}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _darkPopupMenu(
                    context: context,
                    moment: moment,
                    saved: _saved,
                    onSelected: _handleMenu,
                    iconKey: const ValueKey('moment-viewer-menu'),
                  ),
                ],
              ),
            ),
            if (AppFeatureFlags.localPreviews)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 2.5,
                    value: .58,
                    backgroundColor: Colors.white.withValues(alpha: .12),
                    valueColor: AlwaysStoppedAnimation<Color>(moment.tint),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _momentGradient(moment.tint),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          top: -80,
                          right: -60,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: .07),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -100,
                          left: -55,
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: .18),
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(
                            moment.icon,
                            size: 175,
                            color: Colors.white.withValues(alpha: .10),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(26, 24, 26, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  _GlassTag(label: moment.kindLabel),
                                  const Spacer(),
                                  _GlassTag(
                                    label: moment.expires,
                                    icon: Icons.schedule_rounded,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                _caption,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 29,
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
                              const SizedBox(height: 22),
                              Center(
                                child: Container(
                                  width: 34,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .26),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: isMine
                  ? Row(
                      children: [
                        _ViewerCountButton(
                          count: _viewCount,
                          onTap: _showViewers,
                        ),
                        const Spacer(),
                        _ViewerPillButton(
                          icon: Icons.campaign_outlined,
                          label: 'Boost',
                          onTap: () => _showToast(
                            context,
                            'Boost is not available yet. No one else can see a moment in this build.',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ViewerCircleButton(
                          icon: DocmacIconlyLight.upload,
                          tooltip: 'Sharing is not available yet',
                          onTap: () =>
                              _showShareMomentSheet(context, widget.moment),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(23),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (final reaction in const [
                                  '❤️',
                                  '👏',
                                  '🔥',
                                  '😂',
                                  '😮',
                                ])
                                  _ReactionButton(
                                    emoji: reaction,
                                    selected: _reactions.contains(reaction),
                                    onTap: () => setState(() {
                                      if (!_reactions.remove(reaction)) {
                                        _reactions.add(reaction);
                                      }
                                    }),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        _ViewerPillButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Reply',
                          onTap: () => _showToast(
                            context,
                            'Replies are not available yet. Nothing was sent.',
                          ),
                        ),
                      ],
                    ),
            ),
            if (isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  AppFeatureFlags.localPreviews
                      ? 'Preview only: this moment stays in this session and '
                          'is not shared with anyone.'
                      : 'Your moment stays in this session. Nothing was shared.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .38),
                    fontSize: 10.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewerAvatar extends StatelessWidget {
  const _ViewerAvatar({required this.moment});

  final _Moment moment;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: moment.tint.withValues(alpha: .24),
          border: Border.all(
            color: moment.tint.withValues(alpha: .5),
            width: 1.5,
          ),
        ),
        child: Text(
          moment.initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      );
}

class _GlassTag extends StatelessWidget {
  const _GlassTag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
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

class _ViewerCountButton extends StatelessWidget {
  const _ViewerCountButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          key: const ValueKey('moment-viewer-count'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(23),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(DocmacIconlyLight.show,
                    size: 18, color: Colors.white),
                const SizedBox(width: 7),
                Text(
                  'Seen by $count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      );
}

class _ViewerPillButton extends StatelessWidget {
  const _ViewerPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(23),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ViewerCircleButton extends StatelessWidget {
  const _ViewerCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: .10),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
          ),
        ),
      );
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: selected ? 1.22 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Text(emoji, style: const TextStyle(fontSize: 21)),
          ),
        ),
      );
}

class _CreateMomentSheet extends StatefulWidget {
  const _CreateMomentSheet({
    this.shareWith,
    this.initialKind = _MomentKind.text,
  });

  final String? shareWith;
  final _MomentKind initialKind;

  @override
  State<_CreateMomentSheet> createState() => _CreateMomentSheetState();
}

class _CreateMomentSheetState extends State<_CreateMomentSheet> {
  final _caption = TextEditingController();
  late _MomentKind _kind = widget.initialKind;
  late String _audience;

  List<String> get _audiences => [
        'Your People',
        'Close Friends',
        'Everyone',
        'Only me',
        if (widget.shareWith != null) 'Only ${widget.shareWith}',
      ];

  @override
  void initState() {
    super.initState();
    _audience =
        widget.shareWith == null ? 'Your People' : 'Only ${widget.shareWith}';
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _share() {
    final caption = _caption.text.trim();
    Navigator.of(context).pop(
      _MomentDraft(
        caption: caption.isEmpty ? 'A new moment' : caption,
        kind: _kind,
        audience: _audience,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .92,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New moment',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'A tiny update that lives for 24 hours.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _caption,
                builder: (context, value, _) => _MomentPreview(
                  kind: _kind,
                  caption: value.text.trim(),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final kind in _MomentKind.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            kind.icon,
                            size: 17,
                            color: _kind == kind
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                          label: Text(kind.label),
                          selected: _kind == kind,
                          showCheckmark: false,
                          selectedColor: scheme.primary,
                          labelStyle: TextStyle(
                            color: _kind == kind
                                ? scheme.onPrimary
                                : scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _kind = kind);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _caption,
                autofocus: true,
                maxLines: 3,
                maxLength: 160,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Caption',
                  hintText: 'What’s happening?',
                  alignLabelWithHint: true,
                  counterStyle: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Emoji',
                    onPressed: () => _caption.text = '${_caption.text} ✨',
                    icon: const Icon(Icons.emoji_emotions_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Who can see this?',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final audience in _audiences)
                    ChoiceChip(
                      label: Text(audience),
                      selected: _audience == audience,
                      showCheckmark: false,
                      selectedColor: scheme.primary,
                      labelStyle: TextStyle(
                        color: _audience == audience
                            ? scheme.onPrimary
                            : scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _audience = audience),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Only the people you choose can open this moment. It disappears automatically.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _share,
                      icon: const Icon(DocmacIconlyLight.send, size: 18),
                      label: Text(AppFeatureFlags.localPreviews
                          ? 'Share moment'
                          : 'Save on this device'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentPreview extends StatelessWidget {
  const _MomentPreview({required this.kind, required this.caption});

  final _MomentKind kind;
  final String caption;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 178,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: _momentGradient(kind.tint),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -35,
              top: -45,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
            ),
            Icon(
              kind.icon,
              size: 90,
              color: Colors.white.withValues(alpha: .12),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.white24,
                      child: Text(
                        'Y',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '24h',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                caption.isEmpty ? 'A small window into your day.' : caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: caption.isEmpty ? Colors.white70 : Colors.white,
                  fontSize: 22,
                  height: 1.22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.4,
                ),
              ),
            ),
          ],
        ),
      );
}

class _MomentInfoSheet extends StatelessWidget {
  const _MomentInfoSheet({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = AppFeatureFlags.localPreviews
        ? const [
            (
              Icons.people_outline_rounded,
              'Audience is a preview',
              'Choosing Your People, close friends, everyone, or only yourself does not send anything yet.',
            ),
            (
              DocmacIconlyLight.show,
              'No view tracking',
              'View counts on the sample moments are demo data. This build does not track real views.',
            ),
            (
              Icons.more_horiz_rounded,
              'Actions are preview-only',
              'Save, share, forward, edit, and delete change only this session.',
            ),
          ]
        : const [
            (
              Icons.smartphone_rounded,
              'Local preview',
              'Moments stay in this session only and are not shared with other people.',
            ),
            (
              Icons.visibility_off_outlined,
              'No view tracking',
              'No one else can see a moment in this build, so there are no views to report.',
            ),
            (
              Icons.lock_outline_rounded,
              'No sharing yet',
              'Saving outside Docmac, forwarding, and posting to Talks or Circles are not available.',
            ),
          ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moments, privately',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            AppFeatureFlags.localPreviews
                ? 'Preview only: add a thought, a photo, or a small win in this session. Nothing is sent to other people and no views are tracked.'
                : 'This build is a local preview. Create a moment in this session; it is not shared and no one else can view it.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 18),
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.$1,
                    size: 19,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$3,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a moment'),
            ),
          ),
        ],
      ),
    );
  }
}

enum _MomentKind {
  text('Text', Icons.text_fields_rounded, Color(0xFF2F6BFF)),
  photo('Photo', Icons.photo_camera_back_outlined, Color(0xFF0F9D8A)),
  video('Video', Icons.videocam_outlined, Color(0xFFB144F0)),
  voice('Voice', Icons.mic_none_rounded, Color(0xFFF08C2E)),
  music('Music', Icons.music_note_rounded, Color(0xFFE2477E)),
  poll('Poll', Icons.poll_outlined, Color(0xFF4A63D8)),
  question('Question', Icons.help_outline_rounded, Color(0xFF7A57D1));

  const _MomentKind(this.label, this.icon, this.tint);

  final String label;
  final IconData icon;
  final Color tint;
}

class _MomentDraft {
  const _MomentDraft({
    required this.caption,
    required this.kind,
    required this.audience,
  });

  final String caption;
  final _MomentKind kind;
  final String audience;
}

class _Moment {
  const _Moment({
    required this.id,
    required this.owner,
    required this.handle,
    required this.initial,
    required this.kindLabel,
    required this.caption,
    required this.icon,
    required this.tint,
    required this.expires,
    required this.views,
    required this.viewers,
    required this.isMine,
    required this.audience,
  });

  final String id;
  final String owner;
  final String handle;
  final String initial;
  final String kindLabel;
  final String caption;
  final IconData icon;
  final Color tint;
  final String expires;
  final int views;
  final List<_MomentViewerInfo> viewers;
  final bool isMine;
  final String audience;

  _Moment copyWith({
    String? caption,
    int? views,
    String? expires,
  }) =>
      _Moment(
        id: id,
        owner: owner,
        handle: handle,
        initial: initial,
        kindLabel: kindLabel,
        caption: caption ?? this.caption,
        icon: icon,
        tint: tint,
        expires: expires ?? this.expires,
        views: views ?? this.views,
        viewers: viewers,
        isMine: isMine,
        audience: audience,
      );
}

class _MomentViewerInfo {
  const _MomentViewerInfo(
    this.name,
    this.initial,
    this.seenAt,
    this.tint,
    this.reaction,
  );

  final String name;
  final String initial;
  final String seenAt;
  final int tint;
  final String? reaction;
}

class _ShareTarget {
  const _ShareTarget({
    required this.icon,
    required this.tint,
    required this.title,
    required this.detail,
    required this.confirmation,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String detail;
  final String confirmation;
}

const _shareTargets = [
  _ShareTarget(
    icon: Icons.link_rounded,
    tint: Color(0xFF5B8DEF),
    title: 'Copy link',
    detail: 'Moment links are not available yet',
    confirmation: 'Moment links are not available yet.',
  ),
  _ShareTarget(
    icon: DocmacIconlyLight.chat,
    tint: Color(0xFF34C759),
    title: 'Share to a Talk',
    detail: 'Sharing to a Talk is not available yet',
    confirmation: 'Sharing a moment in a Talk is not available yet.',
  ),
  _ShareTarget(
    icon: DocmacIconlyLight.category,
    tint: Color(0xFFF0A13B),
    title: 'Share to a Circle',
    detail: 'Sharing to a Circle is not available yet',
    confirmation: 'Sharing a moment in a Circle is not available yet.',
  ),
  _ShareTarget(
    icon: DocmacIconlyLight.download,
    tint: Color(0xFFB26BFF),
    title: 'Save to device',
    detail: 'Saving outside Docmac is not available yet',
    confirmation: 'Saving a moment to your device is not available yet.',
  ),
];

const _sampleForwardPeople = [
  ('Emma Clarke', 'E', 0xFF4A6CF7),
  ('David Mensah', 'D', 0xFF5B8DEF),
  ('Amara Okafor', 'A', 0xFF34C759),
  ('Nora Williams', 'N', 0xFFB26BFF),
  ('Tobi Adeyemi', 'T', 0xFFF0A13B),
];

List<(String, String, int)> get _forwardPeople => AppFeatureFlags.localPreviews
    ? _sampleForwardPeople
    : const <(String, String, int)>[];

const _reportReasons = [
  'Spam or misleading content',
  'Nudity or sexual content',
  'Hate or harassment',
  'Violence or dangerous content',
  'I just don’t like it',
];

List<PopupMenuEntry<String>> _momentMenuEntries({
  required _Moment moment,
  required bool saved,
}) =>
    [
      if (moment.isMine)
        const PopupMenuItem(
          value: 'edit',
          child: DocmacMenuItem(
            icon: DocmacIconlyLight.edit,
            label: 'Edit caption',
          ),
        ),
      const PopupMenuItem(
        value: 'forward',
        child: DocmacMenuItem(
          icon: DocmacIconlyLight.send,
          label: 'Forward',
        ),
      ),
      PopupMenuItem(
        value: 'save',
        child: DocmacMenuItem(
          icon: saved ? DocmacIconlyBold.bookmark : DocmacIconlyLight.bookmark,
          label: saved ? 'Saved' : 'Save',
        ),
      ),
      const PopupMenuItem(
        value: 'share',
        child: DocmacMenuItem(
          icon: DocmacIconlyLight.upload,
          label: 'Share',
        ),
      ),
      const PopupMenuItem(
        value: 'report',
        child: DocmacMenuItem(
          icon: DocmacIconlyLight.danger,
          label: 'Report',
        ),
      ),
      if (moment.isMine) ...[
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: DocmacMenuItem(
            icon: DocmacIconlyLight.delete,
            label: 'Delete moment',
            destructive: true,
          ),
        ),
      ],
    ];

Widget _darkPopupMenu({
  required BuildContext context,
  required _Moment moment,
  required bool saved,
  required ValueChanged<String> onSelected,
  required Key iconKey,
}) {
  const menuColor = Color(0xFF1E1E1E);
  final theme = Theme.of(context);
  return Theme(
    data: theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        surface: menuColor,
        onSurface: Colors.white,
        onSurfaceVariant: const Color(0xFFA6A6A6),
        error: const Color(0xFFFF7A7A),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: menuColor,
        surfaceTintColor: Colors.transparent,
        elevation: 18,
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
    ),
    child: PopupMenuButton<String>(
      key: iconKey,
      tooltip: 'Moment options',
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 23),
      onSelected: onSelected,
      itemBuilder: (_) => _momentMenuEntries(moment: moment, saved: saved),
    ),
  );
}

LinearGradient _momentGradient(Color tint) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(tint, Colors.black, .08)!,
        Color.lerp(tint, Colors.black, .46)!,
        const Color(0xFF080A0F),
      ],
      stops: const [0, .46, 1],
    );

Future<String?> _promptMomentCaption(
  BuildContext context, {
  required String initial,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _CaptionEditorDialog(initial: initial),
    );

class _CaptionEditorDialog extends StatefulWidget {
  const _CaptionEditorDialog({required this.initial});

  final String initial;

  @override
  State<_CaptionEditorDialog> createState() => _CaptionEditorDialogState();
}

class _CaptionEditorDialogState extends State<_CaptionEditorDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    Navigator.of(context).pop(value.isEmpty ? 'A new moment' : value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Edit caption'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 160,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Say something…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      );
}

Future<bool> _confirmMomentDelete(
  BuildContext context,
  _Moment moment,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
          moment.isMine ? 'Delete this moment?' : 'Delete this saved moment?'),
      content: Text(
        '“${moment.caption}” will disappear immediately. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> _showMomentViewers(
  BuildContext context,
  _Moment moment,
) async {
  final viewers = moment.viewers;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .55,
      minChildSize: .36,
      maxChildSize: .9,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seen by ${viewers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        moment.isMine
                            ? 'Private to ${moment.audience.toLowerCase()}.'
                            : 'People who watched this moment.',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .08),
                  ),
                  child: const Icon(
                    DocmacIconlyLight.show,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (viewers.isEmpty)
              const _NoViewersYet()
            else
              for (final viewer in viewers) _ViewedByRow(viewer: viewer),
          ],
        ),
      ),
    ),
  );
}

class _ViewedByRow extends StatelessWidget {
  const _ViewedByRow({required this.viewer});

  final _MomentViewerInfo viewer;

  @override
  Widget build(BuildContext context) {
    final tint = Color(viewer.tint);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: .2),
            ),
            child: Text(
              viewer.initial,
              style: TextStyle(
                color: tint,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  viewer.seenAt,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (viewer.reaction != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                viewer.reaction!,
                style: const TextStyle(fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoViewersYet extends StatelessWidget {
  const _NoViewersYet();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.visibility_off_outlined,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No views yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your moment is still fresh. Check back soon.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      );
}

Future<void> _showShareMomentSheet(
  BuildContext context,
  _Moment moment,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppFeatureFlags.localPreviews
                  ? 'Share moment'
                  : 'Sharing is not available yet',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose where this moment should travel next.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            for (final target in _shareTargets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: target.tint.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(target.icon, color: target.tint, size: 21),
                ),
                title: Text(
                  target.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  target.detail,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showToast(context, target.confirmation);
                },
              ),
          ],
        ),
      );
    },
  );
}

Future<void> _showForwardMomentSheet(
  BuildContext context,
  _Moment moment,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forward moment',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              _forwardPeople.isEmpty
                  ? 'Forwarding is not available yet.'
                  : 'Send “${moment.caption}” to one of your people.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            if (_forwardPeople.isEmpty)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline_rounded),
                title: Text('Forwarding is not available yet'),
                subtitle: Text(
                    'This build cannot forward a moment to another account.'),
              )
            else
              for (final person in _forwardPeople)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Color(person.$3).withValues(alpha: .16),
                    foregroundColor: Color(person.$3),
                    child: Text(
                      person.$2,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  title: Text(
                    person.$1,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: Icon(
                    DocmacIconlyLight.send,
                    size: 18,
                    color: scheme.primary,
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showToast(
                      context,
                      'Forwarding is not available yet. Nothing was sent.',
                    );
                  },
                ),
          ],
        ),
      );
    },
  );
}

Future<void> _showReportMomentSheet(
  BuildContext context,
  _Moment moment,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report moment',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Your report is private. Tell us what feels wrong with this moment.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            for (final reason in _reportReasons)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.flag_outlined,
                  size: 19,
                  color: scheme.onSurfaceVariant,
                ),
                title: Text(
                  reason,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 17),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showToast(
                    context,
                    'This report was not sent. Reporting is not available yet.',
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}

void _showToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
