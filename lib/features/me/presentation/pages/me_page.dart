import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/docmac_iconly.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
    final name = _name ?? _displayNameFor(user?.displayName);
    final username = _username ?? _usernameFor(user?.email, user?.displayName);
    final photoUrl = _photoUrl ?? user?.photoUrl;
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colors.surfaceContainerLowest,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
          children: [
            Row(
              children: [
                Text('Me', style: Theme.of(context).textTheme.headlineLarge),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: PopupMenuButton<String>(
                    tooltip: 'Profile options',
                    color: colors.surface,
                    surfaceTintColor: Colors.transparent,
                    onSelected: (selection) {
                      if (selection == 'settings') context.push('/settings');
                    },
                    icon:
                        Icon(DocmacIconlyLight.moreCircle,
                            color: colors.secondary),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(DocmacIconlyLight.setting),
                            SizedBox(width: 10),
                            Text('Settings'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ProfileHeader(
              name: name,
              photoUrl: photoUrl,
              profileImageBytes:
                  _profileImageBytes ?? ProfileMediaStore.avatarBytes.value,
              coverImageBytes:
                  _coverImageBytes ?? ProfileMediaStore.coverBytes.value,
              onPickProfile: () {
                _pickImage(_ProfileImageTarget.profile);
              },
              onPickCover: () {
                _pickImage(_ProfileImageTarget.cover);
              },
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '@$username',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_bio?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                _bio!.trim(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _editProfile(
                  name: name,
                  username: username,
                  photoUrl: photoUrl,
                ),
                icon: const Icon(DocmacIconlyLight.edit, size: 18),
                label: const Text('Edit profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.onSurface,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 34),
            _ProfileSections(
              selectedIndex: _selectedSection,
              onSelected: (index) => setState(() => _selectedSection = index),
            ),
            const SizedBox(height: 28),
            Text('Your Docmac', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _ProfileAction(
              icon: DocmacIconlyLight.user,
              title: 'Your Links',
              color: colors.onSurface,
              onTap: () => context.push('/people'),
            ),
            _ProfileAction(
              icon: DocmacIconlyLight.category,
              title: 'Spaces',
              color: colors.onSurface,
              onTap: () => context.push('/spaces'),
            ),
            _ProfileAction(
              icon: DocmacIconlyLight.discovery,
              title: 'Relays',
              color: colors.onSurface,
              onTap: () => context.push('/relays'),
            ),
            _ProfileAction(
              icon: DocmacIconlyLight.work,
              title: 'Forge',
              color: colors.onSurface,
              onTap: () => context.push('/forge'),
            ),
            _ProfileAction(
              icon: DocmacIconlyLight.chart,
              title: 'Foundry',
              color: colors.onSurface,
              onTap: () => context.push('/foundry'),
            ),
            const SizedBox(height: 20),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 12),
            _ProfileAction(
              icon: DocmacIconlyLight.logout,
              title: 'Sign out',
              color: colors.error,
              onTap: () => context.push('/logout'),
            ),
          ],
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _EditProfileSheet(
        name: name,
        username: username,
        bio: _bio ?? '',
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
      _bio = values.bio;
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
      // The local profile remains editable when the account service is offline.
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.photoUrl,
    required this.profileImageBytes,
    required this.coverImageBytes,
    required this.onPickProfile,
    required this.onPickCover,
  });

  final String name;
  final String? photoUrl;
  final Uint8List? profileImageBytes;
  final Uint8List? coverImageBytes;
  final VoidCallback onPickProfile;
  final VoidCallback onPickCover;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 164,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.secondary, colors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: coverImageBytes == null
                  ? null
                  : Image.memory(coverImageBytes!, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 116,
            right: 12,
            child: _ProfileMediaButton(
              tooltip: 'Change cover photo',
              onTap: onPickCover,
            ),
          ),
          Positioned(
            top: 106,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _ProfilePicture(
                  name: name,
                  photoUrl: photoUrl,
                  imageBytes: profileImageBytes,
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: _ProfileMediaButton(
                    tooltip: 'Change profile photo',
                    onTap: onPickProfile,
                    compact: true,
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

class _ProfileMediaButton extends StatelessWidget {
  const _ProfileMediaButton({
    required this.tooltip,
    required this.onTap,
    this.compact = false,
  });

  final String tooltip;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 40.0;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              DocmacIconlyLight.camera,
              color: Theme.of(context).colorScheme.onPrimary,
              size: compact ? 19 : 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePicture extends StatelessWidget {
  const _ProfilePicture({
    required this.name,
    required this.photoUrl,
    required this.imageBytes,
  });

  final String name;
  final String? photoUrl;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials = name.isEmpty ? 'D' : name.substring(0, 1).toUpperCase();

    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
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
    );
  }
}

class _InitialTile extends StatelessWidget {
  const _InitialTile({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.darkBackground),
        child: Center(
          child: Text(
            initials,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      );
}

class _ProfileSections extends StatelessWidget {
  const _ProfileSections(
      {required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _labels = ['Moments', 'Spaces', 'Saved'];

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var index = 0; index < _labels.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        _labels[index],
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: index == selectedIndex
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 3,
                        width: index == selectedIndex ? 34 : 0,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
      );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.name,
    required this.username,
    required this.bio,
    required this.photoUrl,
    required this.website,
    required this.contactEmail,
    required this.contactPhone,
  });

  final String name;
  final String username;
  final String bio;
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
  late final TextEditingController _bioController;
  late final TextEditingController _photoController;
  late final TextEditingController _websiteController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _contactPhoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _usernameController = TextEditingController(text: widget.username);
    _bioController = TextEditingController(text: widget.bio);
    _photoController = TextEditingController(text: widget.photoUrl);
    _websiteController = TextEditingController(text: widget.website);
    _contactEmailController = TextEditingController(text: widget.contactEmail);
    _contactPhoneController = TextEditingController(text: widget.contactPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _photoController.dispose();
    _websiteController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit profile',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 18),
              _ProfileField(controller: _nameController, label: 'Name'),
              const SizedBox(height: 12),
              _ProfileField(controller: _usernameController, label: 'Username'),
              const SizedBox(height: 12),
              _ProfileField(
                controller: _bioController,
                label: 'About',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _ProfileField(
                  controller: _photoController, label: 'Profile photo URL'),
              const SizedBox(height: 20),
              Text('Links & contact',
                  style: Theme.of(context).textTheme.labelLarge),
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
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(
                    context,
                    _ProfileValues(
                      name: name,
                      username: _usernameController.text.trim(),
                      bio: _bioController.text.trim(),
                      photoUrl: _photoController.text.trim(),
                      website: _websiteController.text.trim(),
                      contactEmail: _contactEmailController.text.trim(),
                      contactPhone: _contactPhoneController.text.trim(),
                    ),
                  );
                },
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
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label),
      );
}

class _ProfileValues {
  const _ProfileValues({
    required this.name,
    required this.username,
    required this.bio,
    required this.photoUrl,
    required this.website,
    required this.contactEmail,
    required this.contactPhone,
  });

  final String name;
  final String username;
  final String bio;
  final String photoUrl;
  final String website;
  final String contactEmail;
  final String contactPhone;
}
