import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WhatsApp-style Passkeys screen (Image 1).
/// Enables biometric / screen lock authentication stored in password managers.
class PasskeysPage extends StatefulWidget {
  const PasskeysPage({super.key});

  @override
  State<PasskeysPage> createState() => _PasskeysPageState();
}

class _PasskeysPageState extends State<PasskeysPage> {
  static const _passkeyKey = 'has_registered_passkey';
  bool _hasPasskey = false;
  bool _loading = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPasskeyState();
  }

  Future<void> _loadPasskeyState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasPasskey = prefs.getBool(_passkeyKey) ?? false;
        _loaded = true;
      });
    }
  }

  Future<void> _createPasskey() async {
    HapticFeedback.selectionClick();
    setState(() => _loading = true);

    // Simulate platform biometric/screen-lock enrollment prompt
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_passkeyKey, true);

    if (mounted) {
      setState(() {
        _hasPasskey = true;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passkey created and saved to your device password manager.'),
        ),
      );
    }
  }

  Future<void> _deletePasskey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete passkey?'),
        content: const Text(
          'You will no longer be able to log into Docmac using your face, fingerprint, or screen lock on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_passkeyKey, false);
      setState(() => _hasPasskey = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passkey removed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final brandGreen = isDark ? const Color(0xFF2E9C92) : const Color(0xFF1B6B48);

    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passkeys'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  // Hero Illustration: Person with Key
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: brandGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -4,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.key_rounded,
                                color: brandGreen,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Log in securely and protect your account',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Feature 1: Secure Easy Login
                  const _PasskeyFeatureRow(
                    icon: Icons.shield_outlined,
                    text: 'Create a passkey for a secure, easy way to log into your account.',
                  ),
                  const SizedBox(height: 18),

                  // Feature 2: Biometrics
                  const _PasskeyFeatureRow(
                    icon: Icons.fingerprint_rounded,
                    text: 'Log into Docmac with your face, fingerprint or screen lock.',
                  ),
                  const SizedBox(height: 18),

                  // Feature 3: Password Manager Storage
                  const _PasskeyFeatureRow(
                    icon: Icons.devices_rounded,
                    text: 'Your passkey is stored safely in your password manager.',
                  ),

                  if (_hasPasskey) ...[
                    const SizedBox(height: 28),
                    Divider(color: theme.dividerColor, height: 1),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_circle_rounded, color: brandGreen),
                      title: const Text('Passkey is active on this device'),
                      subtitle: const Text('Saved to your password manager'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                        tooltip: 'Delete passkey',
                        onPressed: _deletePasskey,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Pinned Bottom Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: brandGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _loading ? null : (_hasPasskey ? _deletePasskey : _createPasskey),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _hasPasskey ? 'Delete passkey' : 'Create passkey',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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

class _PasskeyFeatureRow extends StatelessWidget {
  const _PasskeyFeatureRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 22,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: scheme.onSurface,
              fontSize: 14.5,
            ),
          ),
        ),
      ],
    );
  }
}

