import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WhatsApp-style Security Notifications screen (Image 3)
/// Explains end-to-end encryption and toggles device security alerts.
class SecurityNotificationsPage extends StatefulWidget {
  const SecurityNotificationsPage({super.key});

  @override
  State<SecurityNotificationsPage> createState() =>
      _SecurityNotificationsPageState();
}

class _SecurityNotificationsPageState extends State<SecurityNotificationsPage> {
  static const _prefKey = 'show_security_notifications';
  bool _enabled = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _enabled = prefs.getBool(_prefKey) ?? true;
        _loaded = true;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _enabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  void _showLearnMore() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('End-to-End Encryption'),
        content: const Text(
          'Docmac uses Signal Protocol-compatible cryptographic primitives. '
          'Messages, voice and media are encrypted before leaving your device and '
          'can only be decrypted by the intended recipient’s verified key.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('OK'),
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
    final brandGreen = isDark ? const Color(0xFF2E9C92) : const Color(0xFF1B6B48);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          // Green Padlock Illustration
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: brandGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Your chats and calls are private',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),

          Text(
            'End-to-end encryption keeps your personal messages and calls between you and the people you choose. '
            'No one outside of the chat, not even Docmac, can read, listen to, or share them. This includes your:',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),

          // Features List
          _FeatureRow(
            icon: Icons.chat_bubble_outline_rounded,
            color: brandGreen,
            text: 'Text and voice messages',
          ),
          _FeatureRow(
            icon: Icons.phone_outlined,
            color: brandGreen,
            text: 'Audio and video calls',
          ),
          _FeatureRow(
            icon: Icons.attach_file_rounded,
            color: brandGreen,
            text: 'Photos, videos and documents',
          ),
          _FeatureRow(
            icon: Icons.location_on_outlined,
            color: brandGreen,
            text: 'Location sharing',
          ),
          _FeatureRow(
            icon: Icons.sync_rounded,
            color: brandGreen,
            text: 'Status updates',
          ),

          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: _showLearnMore,
              child: Text(
                'Learn more',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 16),

          // Toggle Section
          if (_loaded)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Show security notifications on this device',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Get notified when your security code changes for a contact’s phone in an end-to-end encrypted chat. '
                        'If you have multiple devices, this setting must be enabled on each device where you want to get notifications. ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _showLearnMore,
                        child: Text(
                          'Learn more',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Switch.adaptive(
                  value: _enabled,
                  activeTrackColor: brandGreen,
                  activeThumbColor: Colors.white,
                  onChanged: _toggle,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
