import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/ui/docmac_iconly.dart';
import '../../../../shared/widgets/docmac_menu_item.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../connections/data/connections_controller.dart';
import '../profile_media_store.dart';

class MePage extends ConsumerStatefulWidget {
  const MePage({super.key});

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

class _MePageState extends ConsumerState<MePage> {
  String? _name;
  String? _username;
  String? _bio;
  String? _headline;
  String? _location;
  String? _photoUrl;
  Uint8List? _profileImageBytes;
  Uint8List? _coverImageBytes;
  String? _website;
  String? _contactEmail;
  String? _contactPhone;
  int _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final connectionsController = ref.watch(connectionsProvider);
    final name = _name ?? _displayNameFor(user?.displayName);
    final username = _username ?? _usernameFor(user?.email, user?.displayName);
    final photoUrl = _photoUrl ?? user?.photoUrl;
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colors.surfaceContainerLowest,
      child: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<ConnectionsState>(
          valueListenable: connectionsController,
          builder: (context, connections, _) {
            void editProfile() => _editProfile(
                  name: name,
                  username: username,
                  photoUrl: photoUrl,
                );

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _ProfileHero(
                  name: name,
                  username: username,
                  isOnline: user != null,
                  bio: _bio,
                  headline: _headline,
                  location: _location,
                  website: _website,
                  photoUrl: photoUrl,
                  profileImageBytes:
                      _profileImageBytes ?? ProfileMediaStore.avatarBytes.value,
                  coverImageBytes:
                      _coverImageBytes ?? ProfileMediaStore.coverBytes.value,
                  following: connections.followingCount,
                  connectionsCount: connections.followerCount,
                  seen: connections.seen,
                  onSettings: () => context.push('/settings'),
                  onShare: () => _shareProfile(name),
                  onEdit: editProfile,
                  onMore: (value) => _handleMore(value, name, username),
                  onPickProfile: () => _pickImage(_ProfileImageTarget.profile),
                  onPickCover: () => _pickImage(_ProfileImageTarget.cover),
                  onFollowing: () => _openConnections(
                    '/connections?tab=followers&filter=following',
                  ),
                  onConnections: () => _openConnections(
                    '/connections?tab=followers&filter=followers',
                  ),
                  onSeen: () => context.push('/moments'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileActions(
                        onEdit: editProfile,
                        onShare: () => _shareProfile(name),
                      ),
                      const SizedBox(height: 22),
                      _ProfileTabs(
                        selectedIndex: _selectedSection,
                        onSelected: (index) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedSection = index);
                        },
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: switch (_selectedSection) {
                          1 => const _SpacesTab(key: ValueKey('spaces-tab')),
                          2 => const _SavedTab(key: ValueKey('saved-tab')),
                          _ => const _MomentsTab(key: ValueKey('moments-tab')),
                        },
                      ),
                      const SizedBox(height: 26),
                      _ConnectionsSection(
                        connections: connections,
                        onFollowers: () => _openConnections(
                          '/connections?tab=followers&filter=followers',
                        ),
                        onContacts: () =>
                            _openConnections('/connections?tab=contacts'),
                        onManage: () => _openConnections('/connections'),
                      ),
                      const SizedBox(height: 26),
                      _ProfileDetailsCard(
                        headline: _headline,
                        location: _location,
                        onEdit: editProfile,
                      ),
                      const SizedBox(height: 20),
                      _LinksContactCard(
                        website: _website,
                        contactEmail: _contactEmail,
                        contactPhone: _contactPhone,
                        onEdit: editProfile,
                      ),
                      const SizedBox(height: 20),
                      _DocmacActionsCard(
                        onManage: () => context.push('/settings'),
                      ),
                      const SizedBox(height: 14),
                      _SignOutRow(onTap: () => context.push('/logout')),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Docmac 1.0.4  ·  Your story stays yours',
                          style: TextStyle(
                            color: colors.onSurfaceVariant.withValues(
                              alpha: .7,
                            ),
                            fontSize: 10.5,
                            letterSpacing: .2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openConnections(String route) {
    HapticFeedback.selectionClick();
    context.push(route);
  }

  void _handleMore(String value, String name, String username) {
    switch (value) {
      case 'connections':
        _openConnections('/connections');
        return;
      case 'share':
        _shareProfile(name);
        return;
      case 'settings':
        context.push('/settings');
        return;
      case 'logout':
        context.push('/logout');
        return;
    }
  }

  Future<void> _shareProfile(String name) async {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Profile links are not available yet. $name’s profile was not '
            'copied or shared.',
          ),
        ),
      );
  }

  String _displayNameFor(String? value) =>
      value?.trim().isNotEmpty == true ? value!.trim() : 'Guest';

  String _usernameFor(String? email, String? displayName) {
    if (email?.endsWith('@phone.docmac.invalid') == true &&
        displayName?.trim().isNotEmpty == true) {
      return displayName!.trim().replaceFirst(RegExp(r'^@'), '');
    }
    final username = email?.split('@').first.trim();
    return username?.isNotEmpty == true ? username! : 'docmac_member';
  }

  Future<void> _editProfile({
    required String name,
    required String username,
    required String? photoUrl,
  }) async {
    final values = await showModalBottomSheet<_ProfileValues>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _EditProfileSheet(
        name: name,
        username: username,
        headline: _headline ?? '',
        bio: _bio ?? '',
        location: _location ?? '',
        photoUrl: photoUrl ?? '',
        website: _website ?? '',
        contactEmail: _contactEmail ?? '',
        contactPhone: _contactPhone ?? '',
      ),
    );

    if (values == null || !mounted) return;
    setState(() {
      _name = values.name;
      _username = values.username;
      _headline = values.headline;
      _bio = values.bio;
      _location = values.location;
      _photoUrl = values.photoUrl;
      _website = values.website;
      _contactEmail = values.contactEmail;
      _contactPhone = values.contactPhone;
    });

    try {
      await ref.read(authServiceProvider).updateDisplayName(values.name);
    } on AuthServiceUnavailableException {
      // The local profile remains editable when Firebase is not configured.
    } catch (_) {
      if (mounted) {
        setState(() => _name = name);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update your name online. The change was not applied.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickImage(_ProfileImageTarget target) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(DocmacIconlyLight.image),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(DocmacIconlyLight.camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 86,
      maxWidth: 1800,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      if (target == _ProfileImageTarget.profile) {
        _profileImageBytes = bytes;
        ProfileMediaStore.avatarBytes.value = bytes;
      } else {
        _coverImageBytes = bytes;
        ProfileMediaStore.coverBytes.value = bytes;
      }
    });
  }
}

enum _ProfileImageTarget { profile, cover }

String _compactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1).replaceFirst('.0', '')}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1).replaceFirst('.0', '')}K';
  }
  return '$value';
}

class _HeroDetail {
  const _HeroDetail(this.icon, this.text);

  final IconData icon;
  final String text;
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.username,
    required this.isOnline,
    required this.bio,
    required this.headline,
    required this.location,
    required this.website,
    required this.photoUrl,
    required this.profileImageBytes,
    required this.coverImageBytes,
    required this.following,
    required this.connectionsCount,
    required this.seen,
    required this.onSettings,
    required this.onShare,
    required this.onEdit,
    required this.onMore,
    required this.onPickProfile,
    required this.onPickCover,
    required this.onFollowing,
    required this.onConnections,
    required this.onSeen,
  });

  static const _coverHeight = 208.0;
  static const _overlap = 28.0;

  final String name;
  final String username;
  final bool isOnline;
  final String? bio;
  final String? headline;
  final String? location;
  final String? website;
  final String? photoUrl;
  final Uint8List? profileImageBytes;
  final Uint8List? coverImageBytes;
  final int following;
  final int connectionsCount;
  final int seen;
  final VoidCallback onSettings;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final ValueChanged<String> onMore;
  final VoidCallback onPickProfile;
  final VoidCallback onPickCover;
  final VoidCallback onFollowing;
  final VoidCallback onConnections;
  final VoidCallback onSeen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasBio = bio?.trim().isNotEmpty == true;
    final details = <_HeroDetail>[
      if (headline?.trim().isNotEmpty == true)
        _HeroDetail(DocmacIconlyLight.star, headline!.trim()),
      if (location?.trim().isNotEmpty == true)
        _HeroDetail(DocmacIconlyLight.location, location!.trim()),
      if (website?.trim().isNotEmpty == true)
        _HeroDetail(DocmacIconlyLight.discovery, _prettyLink(website!)),
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _coverHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverImageBytes != null)
                Image.memory(coverImageBytes!, fit: BoxFit.cover)
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [
                              Color(0xFF05080E),
                              Color(0xFF0B1728),
                              Color(0xFF153457),
                            ]
                          : const [
                              Color(0xFF0A1424),
                              Color(0xFF122A49),
                              Color(0xFF1F4A7A),
                            ],
                    ),
                  ),
                ),
              if (coverImageBytes != null)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66000000),
                        Color(0x11000000),
                        Color(0x77000000),
                      ],
                    ),
                  ),
                ),
              CustomPaint(
                painter: _AuroraCoverPainter(
                  lineColor: Colors.white.withValues(alpha: .07),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x59000000), Color(0x00000000)],
                    stops: [0, .42],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x4D000000), Color(0x00000000)],
                    stops: [0, .34],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 14,
                child: _GlassIconButton(
                  key: const ValueKey('profile-settings'),
                  tooltip: 'Settings',
                  icon: DocmacIconlyLight.setting,
                  onTap: onSettings,
                ),
              ),
              Positioned(
                top: 10,
                right: 14,
                child: Row(
                  children: [
                    _GlassIconButton(
                      key: const ValueKey('profile-share'),
                      tooltip: 'Share profile',
                      icon: DocmacIconlyLight.send,
                      onTap: onShare,
                    ),
                    const SizedBox(width: 6),
                    _GlassIconButton(
                      key: const ValueKey('profile-edit'),
                      tooltip: 'Edit profile',
                      icon: DocmacIconlyLight.edit,
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      key: const ValueKey('profile-more'),
                      tooltip: 'More profile options',
                      offset: const Offset(0, 46),
                      color: scheme.surface,
                      surfaceTintColor: Colors.transparent,
                      onSelected: onMore,
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'connections',
                          child: DocmacMenuItem(
                            icon: DocmacIconlyLight.user,
                            label: 'Manage connections',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: DocmacMenuItem(
                            icon: DocmacIconlyLight.send,
                            label: 'Share profile',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'settings',
                          child: DocmacMenuItem(
                            icon: DocmacIconlyLight.setting,
                            label: 'Profile settings',
                          ),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'logout',
                          child: DocmacMenuItem(
                            icon: DocmacIconlyLight.logout,
                            label: 'Sign out',
                            destructive: true,
                          ),
                        ),
                      ],
                      child: const _GlassCircle(
                        icon: DocmacIconlyLight.moreCircle,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 38,
                child: _CoverButton(onTap: onPickCover),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: _coverHeight - _overlap),
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? .28 : .06),
                    blurRadius: 26,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileAvatar(
                        name: name,
                        photoUrl: photoUrl,
                        imageBytes: profileImageBytes,
                        onPick: onPickProfile,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _IdentityBlock(
                          name: name,
                          username: username,
                          isOnline: isOnline,
                          following: following,
                          connectionsCount: connectionsCount,
                          seen: seen,
                          onFollowing: onFollowing,
                          onConnections: onConnections,
                          onSeen: onSeen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (hasBio)
                    Text(
                      bio!.trim(),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 13,
                        height: 1.45,
                        letterSpacing: -.1,
                      ),
                    )
                  else
                    _AddLinePrompt(
                      icon: DocmacIconlyLight.edit,
                      label: 'Add a short bio to tell your story',
                      onTap: onEdit,
                    ),
                  const SizedBox(height: 12),
                  if (details.isNotEmpty)
                    _HeroDetails(details: details)
                  else
                    _AddLinePrompt(
                      icon: DocmacIconlyLight.location,
                      label: 'Add your headline, location and links',
                      onTap: onEdit,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroDetails extends StatelessWidget {
  const _HeroDetails({required this.details});

  final List<_HeroDetail> details;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          for (final detail in details)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    detail.icon,
                    size: 13.5,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      detail.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AddLinePrompt extends StatelessWidget {
  const _AddLinePrompt({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(icon, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _prettyLink(String value) {
  final trimmed = value.trim().replaceFirst(RegExp(r'^https?://'), '');
  final withoutSlash = trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
  if (withoutSlash.length <= 32) return withoutSlash;
  return '${withoutSlash.substring(0, 29)}…';
}

class _AuroraCoverPainter extends CustomPainter {
  const _AuroraCoverPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8FC7E8).withValues(alpha: .22),
          const Color(0xFF8FC7E8).withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * .82, size.height * .22),
          radius: size.width * .52,
        ),
      );
    canvas.drawRect(Offset.zero & size, glow);

    final warmth = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD9B07A).withValues(alpha: .16),
          const Color(0xFFD9B07A).withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * .12, size.height * .9),
          radius: size.width * .55,
        ),
      );
    canvas.drawRect(Offset.zero & size, warmth);

    final line = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final radius = size.width * (.46 + i * .13);
      canvas.drawCircle(
        Offset(size.width * .90, size.height * .06),
        radius,
        line,
      );
    }
    for (var i = 0; i < 4; i++) {
      final radius = size.width * (.30 + i * .15);
      canvas.drawCircle(
        Offset(size.width * .08, size.height * 1.05),
        radius,
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraCoverPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .24),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Icon(icon, color: Colors.white, size: 17),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: _GlassCircle(icon: icon),
        ),
      ),
    );
  }
}

class _CoverButton extends StatelessWidget {
  const _CoverButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Change cover photo',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .28),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(DocmacIconlyLight.camera, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text(
                'Cover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.photoUrl,
    required this.imageBytes,
    required this.onPick,
  });

  final String name;
  final String? photoUrl;
  final Uint8List? imageBytes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = name.isEmpty ? 'D' : name.substring(0, 1).toUpperCase();

    return SizedBox(
      width: 98,
      height: 98,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 94,
            height: 94,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF173B6C),
                  Color(0xFF6D9FD1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A2F73).withValues(alpha: .18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: imageBytes != null
                    ? Image.memory(imageBytes!, fit: BoxFit.cover)
                    : photoUrl?.trim().isNotEmpty == true
                        ? Image.network(
                            photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _InitialTile(initials: initials),
                          )
                        : _InitialTile(initials: initials),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Tooltip(
              message: 'Change profile photo',
              child: Material(
                color: scheme.onSurface,
                shape: const CircleBorder(),
                child: InkWell(
                  key: const ValueKey('profile-photo-button'),
                  onTap: onPick,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Icon(
                      DocmacIconlyLight.camera,
                      color: scheme.surface,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialTile extends StatelessWidget {
  const _InitialTile({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF101A2E), Color(0xFF0A2F73)],
          ),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
        ),
      );
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({
    required this.name,
    required this.username,
    required this.isOnline,
    required this.following,
    required this.connectionsCount,
    required this.seen,
    required this.onFollowing,
    required this.onConnections,
    required this.onSeen,
  });

  final String name;
  final String username;
  final bool isOnline;
  final int following;
  final int connectionsCount;
  final int seen;
  final VoidCallback onFollowing;
  final VoidCallback onConnections;
  final VoidCallback onSeen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  key: const ValueKey('profile-name'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Verified Docmac account',
                child: Container(
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .09),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    DocmacIconlyLight.shieldDone,
                    color: scheme.primary,
                    size: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.1,
                  ),
                ),
              ),
              if (isOnline) ...[
                const SizedBox(width: 8),
                Text(
                  'Online',
                  key: const ValueKey('profile-online-status'),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _StatsLine(
            following: following,
            connectionsCount: connectionsCount,
            seen: seen,
            onFollowing: onFollowing,
            onConnections: onConnections,
            onSeen: onSeen,
          ),
        ],
      ),
    );
  }
}

class _StatsLine extends StatelessWidget {
  const _StatsLine({
    required this.following,
    required this.connectionsCount,
    required this.seen,
    required this.onFollowing,
    required this.onConnections,
    required this.onSeen,
  });

  final int following;
  final int connectionsCount;
  final int seen;
  final VoidCallback onFollowing;
  final VoidCallback onConnections;
  final VoidCallback onSeen;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 1,
      children: [
        _InlineStat(
          key: const ValueKey('profile-stat-followers'),
          value: _compactCount(connectionsCount),
          label: 'Connections',
          onTap: onConnections,
        ),
        const _StatSeparator(),
        _InlineStat(
          key: const ValueKey('profile-stat-following'),
          value: _compactCount(following),
          label: 'Links',
          onTap: onFollowing,
        ),
        const _StatSeparator(),
        _InlineStat(
          key: const ValueKey('profile-stat-likes'),
          value: _compactCount(seen),
          label: 'Seen',
          onTap: onSeen,
        ),
      ],
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({
    super.key,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$label: $value',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.2,
                    ),
                  ),
                  TextSpan(
                    text: ' $label',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatSeparator extends StatelessWidget {
  const _StatSeparator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        '·',
        style: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: .6),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({
    required this.onEdit,
    required this.onShare,
  });

  final VoidCallback onEdit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey('profile-edit-action'),
            onPressed: onEdit,
            icon: const Icon(DocmacIconlyLight.edit, size: 16),
            label: const Text('Edit profile'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey('profile-share-action'),
            onPressed: onShare,
            icon: const Icon(DocmacIconlyLight.send, size: 15),
            label: const Text('Share profile'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: scheme.surfaceContainerHigh,
              foregroundColor: scheme.onSurface,
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectionsSection extends StatelessWidget {
  const _ConnectionsSection({
    required this.connections,
    required this.onFollowers,
    required this.onContacts,
    required this.onManage,
  });

  final ConnectionsState connections;
  final VoidCallback onFollowers;
  final VoidCallback onContacts;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = connections.followerCount + connections.contactCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Connections',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$total',
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              key: const ValueKey('profile-manage-connections'),
              onPressed: onManage,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .24 : .035),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ConnectionDoor(
                    key: const ValueKey('profile-connections-followers'),
                    label: 'Linked to you',
                    value: _compactCount(connections.followerCount),
                    hint: connections.requestCount > 0
                        ? '${connections.requestCount} requests waiting'
                        : 'People linked to you',
                    highlightHint: connections.requestCount > 0,
                    people: [
                      for (final person in connections.followers.take(3))
                        _PreviewFace(person.initials, person.tint),
                    ],
                    onTap: onFollowers,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: scheme.outlineVariant,
                ),
                Expanded(
                  child: _ConnectionDoor(
                    key: const ValueKey('profile-connections-contacts'),
                    label: 'Contacts',
                    value: _compactCount(connections.contactCount),
                    hint: '${connections.onDocmacContactCount} on Docmac',
                    people: [
                      for (final contact in connections.contacts.take(3))
                        _PreviewFace(contact.initials, contact.tint),
                    ],
                    onTap: onContacts,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewFace {
  const _PreviewFace(this.initials, this.tint);

  final String initials;
  final Color tint;
}

class _ConnectionDoor extends StatelessWidget {
  const _ConnectionDoor({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.people,
    required this.onTap,
    this.highlightHint = false,
  });

  final String label;
  final String value;
  final String hint;
  final List<_PreviewFace> people;
  final VoidCallback onTap;
  final bool highlightHint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MiniFaceStack(people: people),
                  const Spacer(),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: .08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      DocmacIconlyLight.arrowRight,
                      size: 13,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 25,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      highlightHint ? scheme.primary : scheme.onSurfaceVariant,
                  fontSize: 10.5,
                  fontWeight: highlightHint ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniFaceStack extends StatelessWidget {
  const _MiniFaceStack({required this.people});

  final List<_PreviewFace> people;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (people.isEmpty) {
      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(
          DocmacIconlyLight.user1,
          size: 12,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return SizedBox(
      width: 26 + (people.length - 1) * 16,
      height: 26,
      child: Stack(
        children: [
          for (var index = 0; index < people.length; index++)
            Positioned(
              left: index * 16,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    people[index].tint.withValues(alpha: .22),
                    scheme.surface,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
                child: Text(
                  people[index].initials,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _tabs = ['Moments', 'Spaces', 'Saved'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < _tabs.length; index++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Semantics(
                    button: true,
                    selected: selectedIndex == index,
                    label: '${_tabs[index]} tab',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('profile-tab-$index'),
                        onTap: () => onSelected(index),
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selectedIndex == index
                                ? scheme.primary.withValues(alpha: .1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _tabs[index],
                            style: TextStyle(
                              color: selectedIndex == index
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                              fontSize: 12.5,
                              fontWeight: selectedIndex == index
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              letterSpacing: -.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: .8),
        ),
      ],
    );
  }
}

class _ProfileMoment {
  const _ProfileMoment({
    required this.caption,
    required this.icon,
    required this.colors,
    required this.views,
    this.pinned = false,
  });

  final String caption;
  final IconData icon;
  final List<Color> colors;
  final String views;
  final bool pinned;
}

const _profileMoments = [
  _ProfileMoment(
    caption: 'Sunday notes',
    icon: Icons.edit_note_rounded,
    colors: [Color(0xFF1B2A41), Color(0xFF3E5C8A)],
    views: '537',
    pinned: true,
  ),
  _ProfileMoment(
    caption: 'A good read',
    icon: Icons.menu_book_rounded,
    colors: [Color(0xFF3B1E5E), Color(0xFF8B5CF6)],
    views: '412',
  ),
  _ProfileMoment(
    caption: 'Small wins',
    icon: Icons.emoji_events_rounded,
    colors: [Color(0xFF6B3A12), Color(0xFFE09A2E)],
    views: '223',
  ),
  _ProfileMoment(
    caption: 'Morning light',
    icon: Icons.wb_sunny_rounded,
    colors: [Color(0xFF123E3B), Color(0xFF17A6A0)],
    views: '196',
  ),
  _ProfileMoment(
    caption: 'On this day',
    icon: Icons.auto_awesome_rounded,
    colors: [Color(0xFF3A1722), Color(0xFFE0657B)],
    views: '96',
  ),
  _ProfileMoment(
    caption: 'New idea',
    icon: Icons.lightbulb_rounded,
    colors: [Color(0xFF1A2740), Color(0xFF5B8DEF)],
    views: '114',
  ),
];

class _MomentsTab extends StatelessWidget {
  const _MomentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _profileMoments.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.22,
          ),
          itemBuilder: (context, index) {
            final moment = _profileMoments[index];
            return _MomentTile(
              moment: moment,
              onTap: () => context.push('/moments'),
            );
          },
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            key: const ValueKey('profile-moments-see-more'),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/moments/archive');
            },
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              backgroundColor: scheme.primary.withValues(alpha: .08),
              textStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -.1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 38),
              shape: const StadiumBorder(),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('See more'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MomentTile extends StatelessWidget {
  const _MomentTile({required this.moment, required this.onTap});

  final _ProfileMoment moment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: moment.colors,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  right: -10,
                  top: -8,
                  child: Icon(
                    moment.icon,
                    size: 62,
                    color: Colors.white.withValues(alpha: .13),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0x66000000)],
                        stops: [.52, 1],
                      ),
                    ),
                  ),
                ),
                if (moment.pinned)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .22),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .26),
                        ),
                      ),
                      child: const Text(
                        'PINNED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 7,
                  right: 7,
                  bottom: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        moment.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            DocmacIconlyLight.show,
                            color: Colors.white.withValues(alpha: .72),
                            size: 9,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            moment.views,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpacesTab extends StatelessWidget {
  const _SpacesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          _SpaceRow(
            icon: DocmacIconlyLight.category,
            title: 'Design club',
            detail: '12 members · 3 active now',
            onTap: () => context.push('/spaces'),
          ),
          Divider(height: 1, indent: 60, color: scheme.outlineVariant),
          _SpaceRow(
            icon: DocmacIconlyLight.activity,
            title: 'Music room',
            detail: '8 members · 1 active now',
            onTap: () => context.push('/spaces'),
          ),
        ],
      ),
    );
  }
}

class _SpaceRow extends StatelessWidget {
  const _SpaceRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: scheme.onSurface, size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    detail,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(DocmacIconlyLight.arrowRight,
                size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SavedTab extends StatelessWidget {
  const _SavedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          _SavedRow(
            colors: const [Color(0xFF1B2A41), Color(0xFF3E5C8A)],
            title: 'Sunday notes',
            detail: 'Saved moment · Open in Moments',
            onTap: () => context.push('/moments'),
          ),
          Divider(height: 1, indent: 60, color: scheme.outlineVariant),
          _SavedRow(
            colors: const [Color(0xFF123E3B), Color(0xFF17A6A0)],
            title: 'Morning light',
            detail: 'Saved moment · Open in Moments',
            onTap: () => context.push('/moments'),
          ),
        ],
      ),
    );
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({
    required this.colors,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final List<Color> colors;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                DocmacIconlyLight.bookmark,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    detail,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(DocmacIconlyLight.arrowRight,
                size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({
    required this.headline,
    required this.location,
    required this.onEdit,
  });

  final String? headline;
  final String? location;
  final VoidCallback onEdit;

  bool _has(String? value) => value?.trim().isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[
      if (_has(headline))
        _DetailRow(
          icon: DocmacIconlyLight.star,
          label: 'Headline',
          value: headline!.trim(),
          onTap: onEdit,
        ),
      if (_has(location))
        _DetailRow(
          icon: DocmacIconlyLight.location,
          label: 'Location',
          value: location!.trim(),
          onTap: onEdit,
        ),
      if (!_has(headline) && !_has(location))
        _DetailRow(
          icon: DocmacIconlyLight.edit,
          label: 'Make your profile yours',
          value: 'Add a headline and location',
          onTap: onEdit,
        ),
      _DetailRow(
        icon: DocmacIconlyLight.lock,
        label: 'Connections visibility',
        value: 'Connections and contacts only',
        onTap: () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Only connections and contacts can see your full profile.',
                ),
              ),
            );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Personal details',
          actionKey: const ValueKey('profile-details-edit'),
          actionTooltip: 'Edit profile details',
          onAction: onEdit,
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                rows[index],
                if (index < rows.length - 1)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: scheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LinksContactCard extends StatelessWidget {
  const _LinksContactCard({
    required this.website,
    required this.contactEmail,
    required this.contactPhone,
    required this.onEdit,
  });

  final String? website;
  final String? contactEmail;
  final String? contactPhone;
  final VoidCallback onEdit;

  bool _has(String? value) => value?.trim().isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[
      if (_has(website))
        _DetailRow(
          icon: DocmacIconlyLight.discovery,
          label: 'Website',
          value: website!.trim(),
          onTap: onEdit,
        ),
      if (_has(contactEmail))
        _DetailRow(
          icon: DocmacIconlyLight.message,
          label: 'Contact email',
          value: contactEmail!.trim(),
          onTap: onEdit,
        ),
      if (_has(contactPhone))
        _DetailRow(
          icon: DocmacIconlyLight.call,
          label: 'Contact phone',
          value: contactPhone!.trim(),
          onTap: onEdit,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Links & contact',
          actionKey: const ValueKey('profile-links-edit'),
          actionTooltip: 'Edit links and contact details',
          onAction: onEdit,
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              if (rows.isEmpty)
                _DetailRow(
                  icon: DocmacIconlyLight.edit,
                  label: 'Add a link or contact',
                  value: 'Give people another way to reach you',
                  onTap: onEdit,
                )
              else
                for (var index = 0; index < rows.length; index++) ...[
                  rows[index],
                  if (index < rows.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: scheme.outlineVariant,
                    ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionKey,
    required this.actionTooltip,
    required this.onAction,
  });

  final String title;
  final Key actionKey;
  final String actionTooltip;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.3,
                ),
          ),
        ),
        IconButton(
          key: actionKey,
          tooltip: actionTooltip,
          visualDensity: VisualDensity.compact,
          onPressed: onAction,
          icon: Icon(
            DocmacIconlyLight.edit,
            size: 17,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 16, color: scheme.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(DocmacIconlyLight.arrowRight,
                size: 13, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _DocmacActionsCard extends StatelessWidget {
  const _DocmacActionsCard({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Explore Docmac',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.3,
                    ),
              ),
            ),
            TextButton(
              onPressed: onManage,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Settings'),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _QuickLink(
                icon: DocmacIconlyLight.category,
                label: 'Spaces',
                onTap: () => context.push('/spaces'),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _QuickLink(
                icon: DocmacIconlyLight.discovery,
                label: 'Relays',
                onTap: () => context.push('/relays'),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _QuickLink(
                icon: DocmacIconlyLight.work,
                label: 'Forge',
                onTap: () => context.push('/forge'),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _QuickLink(
                icon: DocmacIconlyLight.chart,
                label: 'Foundry',
                onTap: () => context.push('/foundry'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 15, color: scheme.primary),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutRow extends StatelessWidget {
  const _SignOutRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(DocmacIconlyLight.logout, color: scheme.error, size: 18),
              const SizedBox(width: 10),
              Text(
                'Sign out',
                style: TextStyle(
                  color: scheme.error,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(DocmacIconlyLight.arrowRight,
                  color: scheme.error.withValues(alpha: .55), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.name,
    required this.username,
    required this.headline,
    required this.bio,
    required this.location,
    required this.photoUrl,
    required this.website,
    required this.contactEmail,
    required this.contactPhone,
  });

  final String name;
  final String username;
  final String headline;
  final String bio;
  final String location;
  final String photoUrl;
  final String website;
  final String contactEmail;
  final String contactPhone;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _headlineController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _photoController;
  late final TextEditingController _websiteController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _contactPhoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _usernameController = TextEditingController(text: widget.username);
    _headlineController = TextEditingController(text: widget.headline);
    _bioController = TextEditingController(text: widget.bio);
    _locationController = TextEditingController(text: widget.location);
    _photoController = TextEditingController(text: widget.photoUrl);
    _websiteController = TextEditingController(text: widget.website);
    _contactEmailController = TextEditingController(text: widget.contactEmail);
    _contactPhoneController = TextEditingController(text: widget.contactPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _photoController.dispose();
    _websiteController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      _ProfileValues(
        name: name,
        username: _usernameController.text.trim(),
        headline: _headlineController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        photoUrl: _photoController.text.trim(),
        website: _websiteController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 18 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit profile',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'A clear headline and location make your profile feel human.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Only your name is saved to your account in this build. '
                'Headline, bio, location, links, and contact details are not '
                'saved or published yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              _ProfileField(controller: _nameController, label: 'Name'),
              const SizedBox(height: 12),
              _ProfileField(
                controller: _usernameController,
                label: 'Username',
                readOnly: true,
                helperText:
                    'Usernames are permanent. Ask support if you need to change yours.',
              ),
              const SizedBox(height: 12),
              _ProfileField(
                controller: _headlineController,
                label: 'Headline',
                hintText: 'Product engineer · Building calm things',
              ),
              const SizedBox(height: 12),
              _ProfileField(
                controller: _bioController,
                label: 'About',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _ProfileField(
                controller: _locationController,
                label: 'Location',
                hintText: 'Uyo, Nigeria',
              ),
              const SizedBox(height: 12),
              _ProfileField(
                controller: _photoController,
                label: 'Profile photo URL',
              ),
              const SizedBox(height: 20),
              Text(
                'Links & contact',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              _ProfileField(
                controller: _websiteController,
                label: 'Website link',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              _ProfileField(
                controller: _contactEmailController,
                label: 'Contact email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _ProfileField(
                controller: _contactPhoneController,
                label: 'Contact phone',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    this.hintText,
    this.helperText,
    this.maxLines = 1,
    this.keyboardType,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? helperText;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          helperText: helperText,
        ),
      );
}

class _ProfileValues {
  const _ProfileValues({
    required this.name,
    required this.username,
    required this.headline,
    required this.bio,
    required this.location,
    required this.photoUrl,
    required this.website,
    required this.contactEmail,
    required this.contactPhone,
  });

  final String name;
  final String username;
  final String headline;
  final String bio;
  final String location;
  final String photoUrl;
  final String website;
  final String contactEmail;
  final String contactPhone;
}
