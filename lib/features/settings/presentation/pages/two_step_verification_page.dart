import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WhatsApp-style Two-Step Verification screen (Image 4).
/// Allows turning 2FA PIN protection on/off and changing the security PIN.
class TwoStepVerificationPage extends StatefulWidget {
  const TwoStepVerificationPage({super.key});

  @override
  State<TwoStepVerificationPage> createState() =>
      _TwoStepVerificationPageState();
}

class _TwoStepVerificationPageState extends State<TwoStepVerificationPage> {
  static const _enabledKey = 'two_step_verification_enabled';
  static const _pinKey = 'two_step_verification_pin';

  bool _isOn = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isOn = prefs.getBool(_enabledKey) ?? true;
        _loaded = true;
      });
    }
  }

  Future<void> _turnOff() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Turn off two-step verification?'),
        content: const Text(
          'Turning off two-step verification removes your PIN requirement when registering your number.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, false);
      setState(() => _isOn = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Two-step verification has been turned off.')),
        );
      }
    }
  }

  Future<void> _turnOn() async {
    await _showPinDialog(
      title: 'Enable Two-Step Verification',
      description: 'Enter a 6-digit PIN that you will be asked for when you register your phone number:',
      onSaved: (pin) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_enabledKey, true);
        await prefs.setString(_pinKey, pin);
        setState(() => _isOn = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Two-step verification has been enabled.')),
          );
        }
      },
    );
  }

  Future<void> _changePin() async {
    await _showPinDialog(
      title: 'Change PIN',
      description: 'Enter your new 6-digit PIN:',
      onSaved: (pin) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_pinKey, pin);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN successfully changed.')),
          );
        }
      },
    );
  }

  Future<void> _showPinDialog({
    required String title,
    required String description,
    required ValueChanged<String> onSaved,
  }) async {
    final controller = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description, style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  hintText: '6-digit PIN',
                  errorText: errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.length != 6) {
                  setDialogState(() => errorText = 'Enter a valid 6-digit PIN');
                  return;
                }
                Navigator.pop(dialogCtx);
                onSaved(controller.text);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLearnMore() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Two-Step Verification'),
        content: const Text(
          'For added security, two-step verification requires a 6-digit PIN '
          'when resetting or verifying your account on a new device. '
          'Never share this PIN with anyone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Got it'),
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

    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-step verification'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          // Illustration Box with Asterisks and Green Checkmark
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 90,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white70 : Colors.black87,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '* * *',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -6,
                  left: -6,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      _isOn
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      color: _isOn ? brandGreen : scheme.error,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            _isOn
                ? 'Two-step verification is on. You’ll need to enter your PIN if you register your phone number on Docmac again.'
                : 'Two-step verification is off. Turn it on to add an extra layer of security to your account.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
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

          const SizedBox(height: 20),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 12),

          if (_isOn) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.cancel_outlined, color: scheme.onSurface),
              title: const Text('Turn off'),
              onTap: _turnOff,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.password_rounded, color: scheme.onSurface),
              title: const Text('Change PIN'),
              onTap: _changePin,
            ),
          ] else ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: brandGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _turnOn,
                child: const Text(
                  'Turn on',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

