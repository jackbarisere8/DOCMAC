import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/docmac_iconly.dart';
import '../../../contacts/presentation/pages/contact_pages.dart';
import '../../data/auth_service.dart';
import '../providers/auth_provider.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  ContactCountry _country = docmacCountries.first;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithPhoneAndPassword(
            phoneNumber: _phoneWithCountry(_country, _phone.text),
            password: _password.text,
          );
      if (mounted) context.go('/orbit');
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authMessage(error));
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to sign in right now.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AccountScaffold(
        step: null,
        eyebrow: 'WELCOME BACK',
        title: 'Good to see\nyou again.',
        description: 'Sign in to continue with your people.',
        icon: DocmacIconlyLight.unlock,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PhoneField(
                controller: _phone,
                country: _country,
                onChooseCountry: _chooseCountry,
                validator: (_) => _phoneValidator(
                  _phoneWithCountry(_country, _phone.text),
                ),
              ),
              const SizedBox(height: 14),
              _AccountField(
                controller: _password,
                label: 'Password',
                hint: 'Enter your password',
                icon: DocmacIconlyLight.lock,
                obscureText: _obscure,
                validator: _passwordValidator,
                suffix: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure
                      ? DocmacIconlyLight.show
                      : DocmacIconlyLight.hide),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _AccountError(message: _error!),
              ],
              const SizedBox(height: 22),
              _PrimaryButton(
                label: 'Sign in',
                loading: _loading,
                onPressed: _signIn,
              ),
              const SizedBox(height: 16),
              _BottomLink(
                prompt: 'New to Docmac?',
                action: 'Create an account',
                onTap: () => context.go('/register'),
              ),
            ],
          ),
        ),
      );

  Future<void> _chooseCountry() async {
    final country = await _showCountryPicker(context, _country);
    if (country != null && mounted) setState(() => _country = country);
  }
}

/// A deliberately complete, gated signup journey. Phone authentication alone
/// never opens Orbit; it only unlocks the rest of account setup.
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _email = TextEditingController();
  ContactCountry _country = docmacCountries.first;
  int _step = 0;
  bool _loading = false;
  bool _obscure = true;
  String? _verificationId;
  int? _resendToken;
  String? _error;

  String get _fullPhoneNumber => _phoneWithCountry(_country, _phone.text);

  @override
  void dispose() {
    for (final controller in [
      _phone,
      _code,
      _name,
      _username,
      _password,
      _confirmPassword,
      _email,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phoneError = _phoneValidator(_fullPhoneNumber);
    if (phoneError != null) return setState(() => _error = phoneError);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).sendPhoneVerification(
            phoneNumber: _fullPhoneNumber,
            forceResendingToken: _resendToken,
            onCodeSent: (verificationId, resendToken) {
              if (!mounted) return;
              setState(() {
                _verificationId = verificationId;
                _resendToken = resendToken;
                _step = 1;
                _loading = false;
              });
            },
            onFailure: (error) {
              if (mounted) {
                setState(() {
                  _loading = false;
                  _error = _authMessage(error);
                });
              }
            },
            onAutoVerified: (credential) async {
              try {
                await ref
                    .read(authServiceProvider)
                    .signInWithPhoneCredential(credential);
                if (mounted) _goTo(2);
              } on FirebaseAuthException catch (error) {
                if (mounted) setState(() => _error = _authMessage(error));
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
          );
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authMessage(error));
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not send a code. Try again.');
    } finally {
      if (mounted && _step == 0) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_code.text.trim().length != 6 || _verificationId == null) {
      return setState(() => _error = 'Enter the six-digit code we sent.');
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).verifyPhoneCode(
            verificationId: _verificationId!,
            smsCode: _code.text.trim(),
          );
      if (mounted) _goTo(2);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _continueName() {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Enter the name your people will know.');
      return;
    }
    _goTo(3);
  }

  Future<void> _continueUsername() async {
    final username = _username.text.trim().replaceFirst(RegExp(r'^@'), '');
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)) {
      return setState(() => _error = 'Use 3–20 letters, numbers, or underscores.');
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final available =
          await ref.read(authServiceProvider).isUsernameAvailable(username);
      if (!available) throw const UsernameUnavailableException();
      if (mounted) _goTo(4);
    } on UsernameUnavailableException {
      if (mounted) setState(() => _error = 'That username is already taken.');
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _error = _usernameCheckMessage(error));
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'We could not check that username right now. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _continuePassword() {
    final passwordError = _passwordValidator(_password.text);
    if (passwordError != null) return setState(() => _error = passwordError);
    if (_password.text != _confirmPassword.text) {
      return setState(() => _error = 'Your passwords do not match.');
    }
    _goTo(5);
  }

  Future<void> _complete() async {
    final email = _email.text.trim();
    if (!_emailValidator(email)) {
      return setState(() => _error = 'Enter a valid email address.');
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).completePhoneSignUp(
            phoneNumber: _fullPhoneNumber,
            username: _username.text,
            password: _password.text,
            displayName: _name.text,
            contactEmail: email,
          );
      if (mounted) context.go('/orbit');
    } on UsernameUnavailableException {
      if (mounted) {
        setState(() {
          _step = 3;
          _error = 'That username was just claimed. Choose another.';
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authMessage(error));
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goTo(int step) {
    setState(() {
      _step = step;
      _error = null;
    });
  }

  void _back() {
    if (_step == 0) {
      context.go('/');
      return;
    }
    if (_step == 1) {
      _code.clear();
      _verificationId = null;
      _resendToken = null;
    }
    _goTo(_step - 1);
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_step) {
      0 => _PhoneField(
          controller: _phone,
          country: _country,
          onChooseCountry: _chooseCountry,
          validator: (_) => _phoneValidator(_fullPhoneNumber),
        ),
      1 => _OtpField(controller: _code, onSubmitted: _verifyCode),
      2 => _AccountField(
          controller: _name,
          label: 'Full name',
          hint: 'e.g. Ada Okafor',
          icon: DocmacIconlyLight.user,
          textCapitalization: TextCapitalization.words,
          validator: (_) => null,
        ),
      3 => _AccountField(
          controller: _username,
          label: 'Username',
          hint: 'adaokafor',
          icon: DocmacIconlyLight.profile,
          prefixText: '@',
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
            const _LowerCaseTextInputFormatter(),
          ],
          validator: (_) => null,
        ),
      4 => Column(
          children: [
            _AccountField(
              controller: _password,
              label: 'Create a password',
              hint: '6–24 characters',
              icon: DocmacIconlyLight.lock,
              obscureText: _obscure,
              validator: _passwordValidator,
              suffix: _visibilityButton(),
            ),
            const SizedBox(height: 14),
            _AccountField(
              controller: _confirmPassword,
              label: 'Confirm password',
              hint: 'Repeat your password',
              icon: DocmacIconlyLight.password,
              obscureText: _obscure,
              validator: _passwordValidator,
            ),
          ],
        ),
      _ => _AccountField(
          controller: _email,
          label: 'Email address',
          hint: 'you@example.com',
          icon: DocmacIconlyLight.message,
          keyboardType: TextInputType.emailAddress,
          validator: (_) => null,
        ),
    };
    final details = _signupDetails[_step];
    final submit = switch (_step) {
      0 => _sendCode,
      1 => _verifyCode,
      2 => _continueName,
      3 => _continueUsername,
      4 => _continuePassword,
      _ => _complete,
    };

    return _AccountScaffold(
      step: _step,
      eyebrow: 'CREATE YOUR ACCOUNT',
      title: details.title,
      description: _step == 1
          ? 'We sent a six-digit code to ${_maskedPhone(_fullPhoneNumber)}.'
          : details.description,
      icon: details.icon,
      onBack: _back,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          if (_error != null) ...[
            const SizedBox(height: 14),
            _AccountError(message: _error!),
          ],
          const SizedBox(height: 22),
          _PrimaryButton(label: details.action, loading: _loading, onPressed: submit),
          if (_step == 1) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loading ? null : _sendCode,
              child: const Text('Didn’t receive a code? Send again'),
            ),
          ],
          if (_step == 0) ...[
            const SizedBox(height: 12),
            _BottomLink(
              prompt: 'Already have an account?',
              action: 'Sign in',
              onTap: () => context.go('/auth'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _visibilityButton() => IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(_obscure ? DocmacIconlyLight.show : DocmacIconlyLight.hide),
      );

  Future<void> _chooseCountry() async {
    final country = await _showCountryPicker(context, _country);
    if (country != null && mounted) setState(() => _country = country);
  }
}

class _SignupDetail {
  const _SignupDetail(this.title, this.description, this.action, this.icon);
  final String title;
  final String description;
  final String action;
  final IconData icon;
}

const _signupDetails = [
  _SignupDetail('What’s your\nphone number?', 'We’ll send a secure code to confirm it.', 'Send code', DocmacIconlyLight.call),
  _SignupDetail('Confirm it’s\nyou.', 'Enter the code we sent you.', 'Verify and continue', DocmacIconlyLight.shieldDone),
  _SignupDetail('Tell us your\nname.', 'Use the name your people will recognise.', 'Continue', DocmacIconlyLight.user),
  _SignupDetail('Claim your\nusername.', 'This is your one-of-a-kind Docmac identity.', 'Check availability', DocmacIconlyLight.profile),
  _SignupDetail('Keep it\nprivate.', 'Create a password to protect your account.', 'Continue', DocmacIconlyLight.lock),
  _SignupDetail('Add your\nemail.', 'We’ll keep it with your account for important updates.', 'Finish setup', DocmacIconlyLight.message),
];

class _AccountScaffold extends StatelessWidget {
  const _AccountScaffold({
    required this.step,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
    this.onBack,
  });

  final int? step;
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        tooltip: onBack == null ? 'Back' : 'Previous step',
                        onPressed: onBack ?? () => context.go('/'),
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                      const _BrandLockup(),
                    ],
                  ),
                  if (step != null) ...[
                    const SizedBox(height: 28),
                    _SignupProgress(step: step!),
                  ],
                  const SizedBox(height: 38),
                  Container(
                    width: 66,
                    height: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: Icon(icon, color: scheme.onPrimaryContainer, size: 28),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    eyebrow,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    title,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 31,
                      height: 1.06,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: .65)),
                    ),
                    child: child,
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

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset('assets/images/docmac_logo.png', width: 28, height: 28),
          ),
          const SizedBox(width: 8),
          Text('Docmac', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        ],
      );
}

class _SignupProgress extends StatelessWidget {
  const _SignupProgress({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(
        6,
        (index) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 4,
            margin: EdgeInsets.only(right: index == 5 ? 0 : 5),
            decoration: BoxDecoration(
              color: index <= step ? scheme.primary : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.country,
    required this.onChooseCountry,
    required this.validator,
  });
  final TextEditingController controller;
  final ContactCountry country;
  final VoidCallback onChooseCountry;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Country / region', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onChooseCountry,
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            minimumSize: const Size.fromHeight(56),
            side: BorderSide(color: scheme.outlineVariant),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(children: [
            Text(country.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                country.name,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              country.code,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ]),
        ),
        const SizedBox(height: 14),
        _AccountField(
          controller: controller,
          label: 'Phone number',
          hint: '801 234 5678',
          icon: DocmacIconlyLight.call,
          keyboardType: TextInputType.phone,
          prefixText: country.code,
          validator: validator,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]'))],
        ),
      ],
    );
  }
}

class _OtpField extends StatelessWidget {
  const _OtpField({required this.controller, required this.onSubmitted});
  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => onSubmitted(),
        autofillHints: const [AutofillHints.oneTimeCode],
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              letterSpacing: 10,
              fontWeight: FontWeight.w800,
            ),
        decoration: const InputDecoration(
          labelText: 'Verification code',
          hintText: '••••••',
          counterText: '',
        ),
      );
}

class _AccountField extends StatelessWidget {
  const _AccountField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.prefixText,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? prefixText;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool autocorrect;
  final bool enableSuggestions;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          prefixText: prefixText == null ? null : '$prefixText ',
          suffixIcon: suffix,
        ),
      );
}

class _LowerCaseTextInputFormatter extends TextInputFormatter {
  const _LowerCaseTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toLowerCase());
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.loading, required this.onPressed});
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
        child: loading
            ? _SignalLoader(color: Theme.of(context).colorScheme.onPrimary)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 9),
                  const Icon(DocmacIconlyLight.arrowRight, size: 18),
                ],
              ),
      );
}

/// A compact animated Iconly mark used while an account action is in flight.
class _SignalLoader extends StatefulWidget {
  const _SignalLoader({required this.color});
  final Color color;

  @override
  State<_SignalLoader> createState() => _SignalLoaderState();
}

class _SignalLoaderState extends State<_SignalLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 34,
        height: 22,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final pulse = .86 + (math.sin(_controller.value * math.pi * 2) * .14);
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: pulse,
                  child: Icon(
                    DocmacIconlyLight.discovery,
                    color: widget.color.withValues(alpha: .28),
                    size: 27,
                  ),
                ),
                Transform.rotate(
                  angle: _controller.value * math.pi * 2,
                  child: Icon(
                    DocmacIconlyLight.discovery,
                    color: widget.color,
                    size: 21,
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _BottomLink extends StatelessWidget {
  const _BottomLink({required this.prompt, required this.action, required this.onTap});
  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(
          onPressed: onTap,
          child: Text.rich(TextSpan(text: '$prompt ', children: [TextSpan(text: action, style: const TextStyle(fontWeight: FontWeight.w800))])),
        ),
      );
}

class _AccountError extends StatelessWidget {
  const _AccountError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(DocmacIconlyLight.infoCircle, color: scheme.onErrorContainer, size: 18),
        const SizedBox(width: 9),
        Expanded(child: Text(message, style: TextStyle(color: scheme.onErrorContainer, fontSize: 12, height: 1.35))),
      ]),
    );
  }
}

String _phoneWithCountry(ContactCountry country, String phone) {
  final compact = phone.replaceAll(RegExp(r'[\s()\-]'), '');
  if (compact.startsWith('+')) return compact;
  return '${country.code.replaceAll(' ', '')}${compact.replaceFirst(RegExp(r'^0+'), '')}';
}

String _maskedPhone(String phoneNumber) => phoneNumber.length <= 6
    ? phoneNumber
    : '${phoneNumber.substring(0, 4)} ••• ${phoneNumber.substring(phoneNumber.length - 3)}';

Future<ContactCountry?> _showCountryPicker(BuildContext context, ContactCountry _) =>
    context.push<ContactCountry>('/register/country');

String? _phoneValidator(String? value) => value != null && RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(value.replaceAll(RegExp(r'[\s()-]'), ''))
    ? null
    : 'Enter a valid phone number with country code.';

String? _passwordValidator(String? value) => value != null && value.length >= 6 && value.length <= 24
    ? null
    : 'Use a password from 6 to 24 characters.';

bool _emailValidator(String email) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

String _usernameCheckMessage(FirebaseException error) {
  debugPrint(
    'Username Firestore failure: code=${error.code}, message=${error.message}',
  );

  switch (error.code) {
    case 'permission-denied':
      return 'Username checking is blocked by Firestore security rules. Please try again after signing in.';
    case 'unavailable':
      return 'Username checking is temporarily unavailable. Check your connection and try again.';
    case 'failed-precondition':
      return 'Username checking needs additional Firestore configuration. Please try again later.';
    default:
      return error.message ?? 'We could not check that username right now.';
  }
}

String _authMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'operation-not-allowed':
      return 'Phone sign-in is disabled for this Firebase project. Enable the Phone provider in Firebase Authentication, then try again.';
    case 'app-not-authorized':
    case 'missing-client-identifier':
    case 'captcha-check-failed':
    case 'invalid-app-credential':
      return 'Firebase could not validate this Android build for phone sign-in. Add this app’s SHA-1 and SHA-256 fingerprints in Firebase, then download a fresh google-services.json.';
    case 'invalid-phone-number':
      return 'Enter a valid international phone number.';
    case 'invalid-verification-code':
      return 'That verification code is not valid.';
    case 'session-expired':
      return 'That code expired. Send a new one and try again.';
    case 'wrong-password':
    case 'user-not-found':
    case 'invalid-credential':
      return 'The phone number or password is incorrect.';
    case 'network-request-failed':
      return 'Check your internet connection and try again.';
    case 'quota-exceeded':
      return 'SMS quota has been reached. Try again later.';
    case 'too-many-requests':
      return 'Too many attempts were made. Please wait before requesting another code.';
    default:
      return error.message ?? 'Authentication failed. Please try again.';
  }
}
