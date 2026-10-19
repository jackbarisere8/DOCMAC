import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../contacts/presentation/pages/contact_pages.dart';

/// WhatsApp-style Change Number flow with two steps:
/// 1. Pre-migration notice & advice screen
/// 2. Old and new phone number entry with country pickers
class ChangeNumberPage extends StatefulWidget {
  const ChangeNumberPage({super.key});

  @override
  State<ChangeNumberPage> createState() => _ChangeNumberPageState();
}

class _ChangeNumberPageState extends State<ChangeNumberPage> {
  int _step = 0; // 0 = Info/Notice, 1 = Number entry

  final _oldPhoneController = TextEditingController();
  final _newPhoneController = TextEditingController();

  ContactCountry _oldCountry = docmacCountries.first;
  ContactCountry _newCountry = docmacCountries.first;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentNumber();
  }

  Future<void> _loadCurrentNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('user_phone_number');
    final phone = savedPhone ?? '';

    if (phone.isNotEmpty && mounted) {
      // Find matching country if prefixed
      for (final country in docmacCountries) {
        if (phone.startsWith(country.code)) {
          setState(() {
            _oldCountry = country;
            _oldPhoneController.text = phone.substring(country.code.length).trim();
          });
          return;
        }
      }
      setState(() => _oldPhoneController.text = phone);
    }
  }

  @override
  void dispose() {
    _oldPhoneController.dispose();
    _newPhoneController.dispose();
    super.dispose();
  }

  Future<void> _chooseOldCountry() async {
    final country = await context.push<ContactCountry>('/register/country');
    if (country != null && mounted) {
      setState(() => _oldCountry = country);
    }
  }

  Future<void> _chooseNewCountry() async {
    final country = await context.push<ContactCountry>('/register/country');
    if (country != null && mounted) {
      setState(() => _newCountry = country);
    }
  }

  Future<void> _submitChangeNumber() async {
    final oldDigits = _oldPhoneController.text.replaceAll(RegExp(r'\s+'), '');
    final newDigits = _newPhoneController.text.replaceAll(RegExp(r'\s+'), '');

    if (oldDigits.isEmpty) {
      setState(() => _error = 'Enter your old phone number');
      return;
    }
    if (newDigits.isEmpty) {
      setState(() => _error = 'Enter your new phone number');
      return;
    }
    if (oldDigits == newDigits && _oldCountry.code == _newCountry.code) {
      setState(() => _error = 'New phone number cannot be identical to the old number');
      return;
    }

    final fullOldNumber = '${_oldCountry.code} $oldDigits';
    final fullNewNumber = '${_newCountry.code} $newDigits';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm number change'),
        content: Text(
          'You are about to change your phone number from $fullOldNumber to $fullNewNumber.\n\nYour account settings and chats will be transferred.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone_number', fullNewNumber);

      await Future<void>.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone number successfully updated to $fullNewNumber'),
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change number'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step = 0);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: _step == 0
            ? _buildOverviewStep(theme, scheme, isDark)
            : _buildInputStep(theme, scheme, isDark),
      ),
    );
  }

  Widget _buildOverviewStep(ThemeData theme, ColorScheme scheme, bool isDark) {
    final brandGreen = isDark ? const Color(0xFF2E9C92) : const Color(0xFF1B6B48);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            children: [
              // Dual SIM Cards Illustration
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SimCard(
                        fillColor: brandGreen,
                        iconColor: Colors.white,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '• • •',
                          style: TextStyle(
                            fontSize: 18,
                            letterSpacing: 2,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _SimCard(
                        fillColor: brandGreen.withValues(alpha: 0.28),
                        iconColor: brandGreen,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Change number',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Events and scheduled calls will not be migrated to your new number and will be deleted.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Before you change your number, confirm that you’re able to receive SMS or calls on your new number.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'If you have both a new number and a new phone, change your number on your old phone first.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'Once you change your number:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              const _NoticeBullet(
                text: 'Your account info, groups and settings will move from your old number to your new number.',
              ),
              const _NoticeBullet(
                text: 'Any pending payments will be canceled.',
              ),
              const _NoticeBullet(
                text: 'Business platform will be disconnected.',
              ),
            ],
          ),
        ),

        // Pinned Bottom Action Button
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
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _step = 1);
              },
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputStep(ThemeData theme, ColorScheme scheme, bool isDark) {
    final brandGreen = isDark ? const Color(0xFF2E9C92) : const Color(0xFF1B6B48);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            children: [
              Text(
                'Enter your old phone number with country code:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _PhoneRow(
                country: _oldCountry,
                onCountryTap: _chooseOldCountry,
                controller: _oldPhoneController,
                hintText: 'Old phone number',
              ),
              const SizedBox(height: 32),

              Text(
                'Enter your new phone number with country code:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _PhoneRow(
                country: _newCountry,
                onCountryTap: _chooseNewCountry,
                controller: _newPhoneController,
                hintText: 'New phone number',
              ),

              if (_error != null) ...[
                const SizedBox(height: 18),
                Text(
                  _error!,
                  style: TextStyle(color: scheme.error, fontSize: 13),
                ),
              ],
            ],
          ),
        ),

        // Pinned Bottom Next Button
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
              onPressed: _loading ? null : _submitChangeNumber,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Next',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({
    required this.country,
    required this.onCountryTap,
    required this.controller,
    required this.hintText,
  });

  final ContactCountry country;
  final VoidCallback onCountryTap;
  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = theme.dividerColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Country code box
        InkWell(
          onTap: onCountryTap,
          child: Container(
            width: 80,
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: divider, width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  country.code,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Phone number input
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(14),
            ],
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.only(bottom: 8),
              isDense: true,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: divider, width: 1.5),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: divider, width: 1.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SimCard extends StatelessWidget {
  const _SimCard({
    required this.fillColor,
    required this.iconColor,
  });

  final Color fillColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 72,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sim_card_outlined,
          color: iconColor,
          size: 34,
        ),
      ),
    );
  }
}

class _NoticeBullet extends StatelessWidget {
  const _NoticeBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
