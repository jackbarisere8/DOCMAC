import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../contacts/presentation/pages/contact_pages.dart';
import '../../data/auth_service.dart';
import '../providers/auth_provider.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  ContactCountry _country = docmacCountries.first;
  bool _usePhone = false;
  int _step = 0;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _verificationId;
  int? _resendToken;
  String? _error;

  String get _fullPhoneNumber => _phoneWithCountry(_country, _phone.text);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !_emailValidator(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user =
          await ref.read(authServiceProvider).signInWithEmailAndPassword(
                email: email,
                password: password,
              );
      if (user != null && mounted) {
        await _finishSignIn();
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authMessage(error));
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Unable to sign in. Please verify your credentials.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                await _finishSignIn();
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
      await _finishSignIn();
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authMessage(error));
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to confirm your account. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finishSignIn() async {
    final completed =
        await ref.read(authServiceProvider).hasCompletedOnboarding();
    if (!mounted) return;
    context.go(completed ? '/orbit' : '/register?resume=true');
  }

  void _returnToPhoneEntry() {
    setState(() {
      _step = 0;
      _code.clear();
      _verificationId = null;
      _error = null;
    });
  }

  Future<void> _confirmAndSendCode() async {
    final phoneError = _phoneValidator(_fullPhoneNumber);
    if (phoneError != null) {
      setState(() => _error = phoneError);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm your number'),
        content: Text(
          'We will send a six-digit verification code to\n$_fullPhoneNumber.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Edit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _sendCode();
  }

  Future<void> _chooseCountry() async {
    final country = await _showCountryPicker(context, _country);
    if (country != null && mounted) setState(() => _country = country);
  }

  @override
  Widget build(BuildContext context) {
    if (_usePhone) {
      return _PhoneAuthScaffold(
        verifying: _step == 1,
        loading: _loading,
        onBack: _step == 0
            ? () => setState(() => _usePhone = false)
            : _returnToPhoneEntry,
        onContinue: _step == 0 ? _confirmAndSendCode : _verifyCode,
        child: _step == 0
            ? _MinimalPhoneEntry(
                controller: _phone,
                country: _country,
                onChooseCountry: _chooseCountry,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                error: _error,
              )
            : _MinimalOtpEntry(
                controller: _code,
                phoneNumber: _fullPhoneNumber,
                error: _error,
                onSubmitted: _verifyCode,
                onResend: _loading ? null : _sendCode,
              ),
      );
    }

    return _SignInScaffold(
      loading: _loading,
      error: _error,
      emailController: _email,
      passwordController: _password,
      obscurePassword: _obscurePassword,
      onToggleObscure: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      onSubmitted: _signInWithEmail,
      onForgotPassword: () => context.push('/forgot-password'),
      onSwitchToPhone: () => setState(() {
        _usePhone = true;
        _step = 0;
        _error = null;
      }),
      onGoToRegister: () => context.go('/register'),
      onBack: () => context.go('/'),
    );
  }
}

/// The email sign-in surface now shares the sky identity used by sign-up so
/// the two halves of the auth flow read as one product: soft gradient header,
/// cloud backdrop, and a crisp sheet carrying pill fields.
class _SignInScaffold extends StatelessWidget {
  const _SignInScaffold({
    required this.loading,
    required this.error,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSubmitted,
    required this.onForgotPassword,
    required this.onSwitchToPhone,
    required this.onGoToRegister,
    required this.onBack,
  });

  final bool loading;
  final String? error;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmitted;
  final VoidCallback onForgotPassword;
  final VoidCallback onSwitchToPhone;
  final VoidCallback onGoToRegister;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _SkyPalette.of(isDark);

    return _CreateAccountScaffold(
      eyebrow: 'Docmac account',
      title: 'Welcome back',
      subtitle: 'Sign in to pick up right where you left off.',
      backTooltip: 'Back',
      onBack: onBack,
      loading: loading,
      error: error,
      primaryLabel: 'Sign In',
      primaryButtonKey: const Key('signin-submit'),
      onPrimary: onSubmitted,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SkyTextField(
            key: const Key('signin-email'),
            controller: emailController,
            autofocus: true,
            leadingIcon: Icons.mail_outline_rounded,
            hintText: 'Email address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 12),
          _SkyTextField(
            key: const Key('signin-password'),
            controller: passwordController,
            leadingIcon: Icons.lock_outline_rounded,
            hintText: 'Password',
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            suffix: _PasswordVisibilityButton(
              visible: !obscurePassword,
              onTap: onToggleObscure,
            ),
            onSubmitted: (_) => onSubmitted(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: loading ? null : onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: palette.accent,
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: palette.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or continue with',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: palette.border)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SocialLoginButton(
                  icon: const _GoogleIcon(),
                  label: 'Google',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google Sign-In ready.')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SocialLoginButton(
                  icon: const Icon(Icons.apple, size: 20),
                  label: 'Apple',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Apple Sign-In ready.')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: loading ? null : onSwitchToPhone,
                icon: const Icon(Icons.phone_iphone_rounded, size: 16),
                label: const Text(
                  'Phone number',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: palette.accent,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.muted.withValues(alpha: 0.45),
                ),
              ),
              TextButton(
                onPressed: () => _showAuthHelpSheet(context),
                style: TextButton.styleFrom(
                  foregroundColor: palette.muted,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Help',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          _BottomLink(
            prompt: 'Don\'t have an account?',
            action: 'Sign up',
            onTap: onGoToRegister,
          ),
        ],
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        side: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      icon: icon,
      label: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final red = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final yellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final green = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 0.5, true, red);
    canvas.drawArc(rect, -math.pi * 1.25, math.pi * 0.5, true, yellow);
    canvas.drawArc(rect, math.pi * 0.25, math.pi * 0.5, true, green);
    canvas.drawArc(rect, -math.pi * 0.25, math.pi * 0.5, true, blue);

    canvas.drawCircle(center, radius * 0.58, Paint()..color = Colors.white);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.45, h * 0.38, w * 0.55, h * 0.24), blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A focused, phone-first sign-in surface. It intentionally uses Docmac's
/// neutral layout and blue action color instead of copying another app's UI.
class _PhoneAuthScaffold extends StatelessWidget {
  const _PhoneAuthScaffold({
    required this.verifying,
    required this.loading,
    required this.onBack,
    required this.onContinue,
    required this.child,
  });

  final bool verifying;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: verifying ? 'Edit phone number' : 'Back',
          onPressed: loading ? null : onBack,
          icon: Icon(
            verifying ? Icons.close_rounded : Icons.arrow_back_rounded,
            color: scheme.onSurface,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showAuthHelpSheet(context),
            icon: const Icon(Icons.help_outline_rounded, size: 18),
            label: const Text('Help'),
            style: TextButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: child,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: Align(
              alignment: Alignment.centerRight,
              child: _RoundPhoneAction(
                verifying: verifying,
                loading: loading,
                onPressed: onContinue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimalPhoneEntry extends StatelessWidget {
  const _MinimalPhoneEntry({
    required this.controller,
    required this.country,
    required this.onChooseCountry,
    required this.onChanged,
    required this.error,
  });

  final TextEditingController controller;
  final ContactCountry country;
  final VoidCallback onChooseCountry;
  final ValueChanged<String> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Text(
          'Your phone number',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Confirm your country code and enter the phone number\nlinked to your Docmac account.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 38),
        OutlinedButton(
          onPressed: onChooseCountry,
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            minimumSize: const Size.fromHeight(64),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            side: BorderSide(color: scheme.outlineVariant),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 21)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  country.name,
                  style: TextStyle(color: scheme.onSurface, fontSize: 16),
                ),
              ),
              Text(country.code,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          onChanged: onChanged,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]')),
          ],
          decoration: InputDecoration(
            labelText: 'Phone number',
            prefixText: '${country.code}  ',
            hintText: '801 234 5678',
            filled: false,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: TextStyle(color: scheme.error, fontSize: 13)),
        ],
      ],
    );
  }
}

class _MinimalOtpEntry extends StatelessWidget {
  const _MinimalOtpEntry({
    required this.controller,
    required this.phoneNumber,
    required this.error,
    required this.onSubmitted,
    required this.onResend,
  });

  final TextEditingController controller;
  final String phoneNumber;
  final String? error;
  final VoidCallback onSubmitted;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Text(
          'Verify your number',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the six-digit code sent to\n${_maskedPhone(phoneNumber)}.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 36),
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmitted(),
          autofillHints: const [AutofillHints.oneTimeCode],
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            letterSpacing: 12,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '------',
            filled: false,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: scheme.outlineVariant, width: 2),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error, fontSize: 13)),
        ],
        const SizedBox(height: 18),
        TextButton(
          onPressed: onResend,
          child: const Text('Didn\'t receive a code? Send again'),
        ),
      ],
    );
  }
}

class _RoundPhoneAction extends StatelessWidget {
  const _RoundPhoneAction({
    required this.verifying,
    required this.loading,
    required this.onPressed,
  });

  final bool verifying;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filled(
      tooltip: verifying ? 'Verify code' : 'Continue',
      onPressed: loading ? null : onPressed,
      style: IconButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        fixedSize: const Size(60, 60),
      ),
      icon: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.onPrimary,
              ),
            )
          : Icon(verifying ? Icons.check_rounded : Icons.arrow_forward_rounded),
    );
  }
}

/// A comprehensive two-faced onboarding flow:
/// 1. Phone number verification via SMS OTP
/// 2. Profile identity (Full Name & Avatar)
/// 3. Public handle (@username)
/// 4. Login credentials (Email & Password)
/// Allows login via Email & Password or Phone OTP.
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key, this.resume = false});

  final bool resume;

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  ContactCountry _country = docmacCountries.first;
  int _step = 0;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String? _verificationId;
  int? _resendToken;
  String? _error;

  String get _fullPhoneNumber => _phoneWithCountry(_country, _phone.text);

  @override
  void initState() {
    super.initState();
    if (widget.resume) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        final phone = user.phoneNumber;
        if (phone != null && phone.isNotEmpty) {
          _phone.text = phone;
          _step = 2;
        }
        final name = user.displayName;
        if (name != null && name.isNotEmpty) {
          _name.text = name;
        }
        final email = user.email;
        if (email != null && email.isNotEmpty) {
          _email.text = email;
        }
      }
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
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
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to verify code. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmAndSendCode() async {
    final phoneError = _phoneValidator(_fullPhoneNumber);
    if (phoneError != null) {
      setState(() => _error = phoneError);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm your number'),
        content: Text(
          'We will send a six-digit verification code to\n$_fullPhoneNumber.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Edit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _sendCode();
  }

  Future<void> _chooseCountry() async {
    final country = await _showCountryPicker(context, _country);
    if (country != null && mounted) setState(() => _country = country);
  }

  Future<void> _completeProfile() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Enter the name your people will know.');
      return;
    }

    final username = _username.text.trim().replaceFirst(RegExp(r'^@'), '');
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
      setState(() => _error =
          'Use 3–20 letters, numbers, or underscores for your username.');
      return;
    }

    final email = _email.text.trim();
    if (!_emailValidator(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    final password = _password.text;
    if (password.isNotEmpty && password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password.isEmpty && _confirmPassword.text.isNotEmpty) {
      setState(() => _error = 'Enter a password before confirming it.');
      return;
    }
    if (password.isNotEmpty && _confirmPassword.text != password) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (!_acceptedTerms) {
      setState(
        () => _error =
            'Please accept the Terms of Service and Privacy Policy to continue.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final available =
          await ref.read(authServiceProvider).isUsernameAvailable(username);
      if (!available) throw const UsernameUnavailableException();

      if (password.isNotEmpty) {
        await ref.read(authServiceProvider).completeDualSignUp(
              email: email,
              password: password,
              username: username,
              displayName: name,
            );
      } else {
        await ref.read(authServiceProvider).completePhoneSignUp(
              username: username,
              displayName: name,
              contactEmail: email,
            );
      }

      if (mounted) context.go('/orbit');
    } on UsernameUnavailableException {
      if (mounted) {
        setState(
            () => _error = 'That username is already taken. Choose another.');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _authMessage(error));
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _error = _usernameCheckMessage(error));
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not create account: $e');
      }
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
      _goTo(0);
      return;
    }
    if (_step == 2) {
      if (widget.resume) {
        context.go('/auth');
        return;
      }
      _goTo(1);
      return;
    }
    _goTo(_step - 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _SkyPalette.of(isDark);

    return _CreateAccountScaffold(
      eyebrow: switch (_step) {
        0 => 'Get started',
        1 => 'Verification',
        _ => 'Profile info',
      },
      title: switch (_step) {
        0 => 'Your phone number',
        1 => 'Confirm your number',
        _ => 'Create Account',
      },
      subtitle: switch (_step) {
        0 =>
          'Choose your country and enter your mobile number for OTP verification.',
        1 =>
          'Enter the six-digit code sent to ${_maskedPhone(_fullPhoneNumber)}.',
        _ => 'Join Docmac and take the window seat.',
      },
      backTooltip: _step == 0 ? 'Close signup' : 'Previous step',
      onBack: _step == 0 ? () => context.go('/') : _back,
      loading: _loading,
      error: _error,
      primaryLabel: switch (_step) {
        0 => 'Send code',
        1 => 'Verify and continue',
        _ => 'Create Account',
      },
      onPrimary: switch (_step) {
        0 => _confirmAndSendCode,
        1 => _verifyCode,
        _ => _completeProfile,
      },
      form: switch (_step) {
        0 => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SkyCountryField(
                country: _country,
                onTap: _chooseCountry,
              ),
              const SizedBox(height: 12),
              _SkyTextField(
                key: const Key('signup-phone'),
                controller: _phone,
                autofocus: true,
                leadingIcon: Icons.phone_outlined,
                hintText: 'Phone number',
                prefixText: '${_country.code}  ',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]')),
                ],
                onSubmitted: (_) => _confirmAndSendCode(),
              ),
            ],
          ),
        1 => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SkyTextField(
                key: const Key('signup-otp'),
                controller: _code,
                autofocus: true,
                leadingIcon: Icons.password_rounded,
                hintText: 'Six-digit code',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                letterSpacing: 4,
                onSubmitted: (_) => _verifyCode(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _sendCode,
                  style: TextButton.styleFrom(
                    foregroundColor: palette.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Send a new code',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SkyTextField(
                key: const Key('signup-full-name'),
                controller: _name,
                autofocus: true,
                leadingIcon: Icons.person_outline_rounded,
                hintText: 'Full name',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _usernameFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              _SkyTextField(
                key: const Key('signup-username'),
                controller: _username,
                focusNode: _usernameFocus,
                leadingIcon: Icons.alternate_email_rounded,
                hintText: 'Username',
                prefixText: '@',
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                  const _LowerCaseTextInputFormatter(),
                ],
                onSubmitted: (_) => _emailFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              _SkyTextField(
                key: const Key('signup-email'),
                controller: _email,
                focusNode: _emailFocus,
                leadingIcon: Icons.mail_outline_rounded,
                hintText: 'Email address',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              _SkyTextField(
                key: const Key('signup-password'),
                controller: _password,
                focusNode: _passwordFocus,
                leadingIcon: Icons.lock_outline_rounded,
                hintText: 'Password',
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                suffix: _PasswordVisibilityButton(
                  visible: !_obscurePassword,
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              _SkyTextField(
                key: const Key('signup-confirm-password'),
                controller: _confirmPassword,
                focusNode: _confirmPasswordFocus,
                leadingIcon: Icons.lock_outline_rounded,
                hintText: 'Confirm password',
                obscureText: _obscureConfirmPassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                suffix: _PasswordVisibilityButton(
                  visible: !_obscureConfirmPassword,
                  onTap: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
                onSubmitted: (_) => _completeProfile(),
              ),
              const SizedBox(height: 14),
              _TermsAgreement(
                accepted: _acceptedTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptedTerms = value;
                    if (value) _error = null;
                  });
                },
                onTermsTap: () => _showLegalInfo(context, _LegalDocument.terms),
                onPrivacyTap: () =>
                    _showLegalInfo(context, _LegalDocument.privacy),
              ),
            ],
          ),
      },
      footer: _step == 1
          ? null
          : _BottomLink(
              prompt: 'Already have an account?',
              action: 'Login',
              onTap: () => context.go('/auth'),
            ),
    );
  }
}

void _showAuthHelpSheet(BuildContext context) {
  HapticFeedback.lightImpact();
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: scheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Private & Secure Identity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Docmac accounts are secured with your chosen email and password. '
              'We never require or sell your phone number or SMS data. '
              'Your unique username provides a private handle for talks, circles, and relays.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The create-account surface leans into Docmac's travel-inspired identity:
/// a soft sky, sculpted clouds, and a crisp white sheet that carries the form.
/// One scrollable column keeps every field reachable on small screens while
/// the big bottom action stays easy to hit.
class _CreateAccountScaffold extends StatelessWidget {
  const _CreateAccountScaffold({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.backTooltip,
    required this.onBack,
    required this.loading,
    required this.error,
    required this.primaryLabel,
    required this.onPrimary,
    required this.form,
    this.footer,
    this.primaryButtonKey,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String backTooltip;
  final VoidCallback onBack;
  final bool loading;
  final String? error;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Widget form;
  final Widget? footer;
  final Key? primaryButtonKey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _SkyPalette.of(isDark);
    final media = MediaQuery.of(context);
    final heroHeight =
        media.padding.top + (media.size.height < 700 ? 200.0 : 224.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: palette.sheet,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.skyBottom,
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: ValueKey(eyebrow),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                _SkyHero(
                  height: heroHeight,
                  eyebrow: eyebrow,
                  title: title,
                  subtitle: subtitle,
                  backTooltip: backTooltip,
                  onBack: onBack,
                  palette: palette,
                  isDark: isDark,
                ),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: math.max(
                      0.0,
                      constraints.maxHeight - heroHeight,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: palette.sheet,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.45)
                            : const Color(0xFF0B2440).withValues(alpha: 0.09),
                        blurRadius: 34,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 38,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: palette.handle,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              form,
                              if (error != null) ...[
                                const SizedBox(height: 12),
                                _SkyErrorBanner(message: error!),
                              ],
                              const SizedBox(height: 16),
                              _SkyPrimaryButton(
                                label: primaryLabel,
                                loading: loading,
                                palette: palette,
                                buttonKey: primaryButtonKey,
                                onPressed: onPrimary,
                              ),
                              if (footer != null) ...[
                                const SizedBox(height: 18),
                                footer!,
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _SkyHero extends StatelessWidget {
  const _SkyHero({
    required this.height,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.backTooltip,
    required this.onBack,
    required this.palette,
    required this.isDark,
  });

  final double height;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String backTooltip;
  final VoidCallback onBack;
  final _SkyPalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.skyTop,
                  palette.skyMid,
                  palette.skyBottom,
                ],
                stops: const [0, 0.62, 1],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _SkyCloudsPainter(
                palette: palette,
                isDark: isDark,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 6, 26, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _SkyBackButton(
                            tooltip: backTooltip,
                            onTap: onBack,
                            palette: palette,
                            isDark: isDark,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          eyebrow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.15,
                          ),
                        ),
                        const SizedBox(height: 7),
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              maxLines: 1,
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 30,
                                height: 1.05,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.9,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 13,
                            height: 1.38,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
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

class _SkyBackButton extends StatelessWidget {
  const _SkyBackButton({
    required this.tooltip,
    required this.onTap,
    required this.palette,
    required this.isDark,
  });

  final String tooltip;
  final VoidCallback onTap;
  final _SkyPalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_rounded,
                color: palette.ink,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkyCloudsPainter extends CustomPainter {
  const _SkyCloudsPainter({
    required this.palette,
    required this.isDark,
  });

  final _SkyPalette palette;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width.clamp(320.0, 520.0);
    _cloud(
      canvas,
      Offset(size.width * 0.43, size.height * 0.20),
      scale * 0.023,
      opacity: 0.65,
    );
    _cloud(
      canvas,
      Offset(size.width * 0.12, size.height * 0.18),
      scale * 0.052,
      opacity: 0.92,
    );
    _cloud(
      canvas,
      Offset(size.width * 0.94, size.height * 0.10),
      scale * 0.038,
      opacity: 0.78,
    );
    _cloud(
      canvas,
      Offset(size.width * 0.57, size.height * 0.49),
      scale * 0.070,
      opacity: 0.42,
    );
    _cloud(
      canvas,
      Offset(size.width * 0.72, size.height * 0.37),
      scale * 0.137,
    );
  }

  void _cloud(
    Canvas canvas,
    Offset center,
    double radius, {
    double opacity = 1,
  }) {
    if (radius <= 0) return;
    final path = Path()
      ..addOval(
        Rect.fromCenter(
          center: center.translate(0, radius * 0.55),
          width: radius * 4.7,
          height: radius * 1.15,
        ),
      );
    const puffs = <(double, double, double)>[
      (-1.62, 0.38, 0.57),
      (-0.96, 0.02, 0.78),
      (-0.17, -0.38, 1.00),
      (0.64, -0.30, 0.90),
      (1.38, 0.09, 0.70),
      (1.82, 0.42, 0.49),
    ];
    for (final puff in puffs) {
      path.addOval(
        Rect.fromCircle(
          center: center.translate(puff.$1 * radius, puff.$2 * radius),
          radius: puff.$3 * radius,
        ),
      );
    }

    final bounds = path.getBounds();
    final shadowAlpha = (isDark ? 0.28 : 0.22) * opacity;
    canvas.drawPath(
      path.shift(Offset(0, radius * 0.38)),
      Paint()
        ..color = palette.cloudShadow.withValues(alpha: shadowAlpha)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, radius * 0.44),
    );

    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topCenter,
          bounds.bottomCenter,
          [
            palette.cloudLight.withValues(alpha: opacity),
            palette.cloudShade.withValues(alpha: opacity),
          ],
        ),
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(
            bounds.left + bounds.width * 0.36,
            bounds.top + bounds.height * 0.20,
          ),
          bounds.width * 0.56,
          [
            Colors.white.withValues(alpha: (isDark ? 0.10 : 0.62) * opacity),
            Colors.white.withValues(alpha: 0),
          ],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SkyCloudsPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.palette != palette;
}

class _SkyPalette {
  const _SkyPalette({
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.sheet,
    required this.field,
    required this.fieldFocused,
    required this.ink,
    required this.muted,
    required this.icon,
    required this.border,
    required this.accent,
    required this.handle,
    required this.cloudLight,
    required this.cloudShade,
    required this.cloudShadow,
  });

  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;
  final Color sheet;
  final Color field;
  final Color fieldFocused;
  final Color ink;
  final Color muted;
  final Color icon;
  final Color border;
  final Color accent;
  final Color handle;
  final Color cloudLight;
  final Color cloudShade;
  final Color cloudShadow;

  static _SkyPalette of(bool isDark) => isDark ? _dark : _light;

  static const _light = _SkyPalette(
    skyTop: Color(0xFFA6DFF7),
    skyMid: Color(0xFFD8F0FC),
    skyBottom: Color(0xFFF4FBFF),
    sheet: Colors.white,
    field: Color(0xFFF4F6F9),
    fieldFocused: Colors.white,
    ink: Color(0xFF0B1736),
    muted: Color(0xFF64748B),
    icon: Color(0xFF7F8B9E),
    border: Color(0xFFE1E7F0),
    accent: Color(0xFF1E2A78),
    handle: Color(0xFFE2E8F0),
    cloudLight: Colors.white,
    cloudShade: Color(0xFFD9EDF9),
    cloudShadow: Color(0xFF4FA7CB),
  );

  static const _dark = _SkyPalette(
    skyTop: Color(0xFF17415F),
    skyMid: Color(0xFF0D2438),
    skyBottom: Color(0xFF081524),
    sheet: Color(0xFF0A1321),
    field: Color(0xFF151F2E),
    fieldFocused: Color(0xFF111B29),
    ink: Color(0xFFF8FAFC),
    muted: Color(0xFF96A5B9),
    icon: Color(0xFF8494A9),
    border: Color(0xFF26354A),
    accent: Color(0xFF4265E8),
    handle: Color(0xFF26354A),
    cloudLight: Color(0xFFC3DAE8),
    cloudShade: Color(0xFF5E8098),
    cloudShadow: Colors.black,
  );
}

class _SkyCountryField extends StatelessWidget {
  const _SkyCountryField({
    required this.country,
    required this.onTap,
  });

  final ContactCountry country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _SkyPalette.of(
      Theme.of(context).brightness == Brightness.dark,
    );
    return Material(
      color: palette.field,
      borderRadius: BorderRadius.circular(27),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: SizedBox(
            height: 54,
            child: Row(
              children: [
                Text(country.flag, style: const TextStyle(fontSize: 21)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    country.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  country.code,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: palette.icon,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkyTextField extends StatefulWidget {
  const _SkyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.autofocus = false,
    this.leadingIcon,
    this.prefixText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
    this.obscureText = false,
    this.suffix,
    this.onSubmitted,
    this.maxLength,
    this.letterSpacing = 0,
  });

  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final bool autofocus;
  final IconData? leadingIcon;
  final String? prefixText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool autocorrect;
  final bool enableSuggestions;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;
  final double letterSpacing;

  @override
  State<_SkyTextField> createState() => _SkyTextFieldState();
}

class _SkyTextFieldState extends State<_SkyTextField> {
  late final bool _ownsFocusNode = widget.focusNode == null;
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _focused = _focusNode.hasFocus;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted || _focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _SkyPalette.of(isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: 54,
      decoration: BoxDecoration(
        color: _focused ? palette.fieldFocused : palette.field,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: _focused ? palette.ink : Colors.transparent,
          width: 1.25,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          if (widget.leadingIcon != null) ...[
            Icon(
              widget.leadingIcon,
              size: 20,
              color: _focused ? palette.ink : palette.icon,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textCapitalization: widget.textCapitalization,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              autocorrect: widget.autocorrect,
              enableSuggestions: widget.enableSuggestions,
              autofillHints: widget.autofillHints,
              maxLength: widget.maxLength,
              onSubmitted: widget.onSubmitted,
              cursorColor: palette.ink,
              textAlignVertical: TextAlignVertical.center,
              maxLines: 1,
              style: TextStyle(
                color: palette.ink,
                fontSize: 15,
                height: 1.2,
                fontWeight: FontWeight.w500,
                letterSpacing: widget.letterSpacing,
              ),
              decoration: InputDecoration(
                // The global input decoration theme fills every field with
                // AppColors.lightCard. Left on, that painted a white rectangle
                // with a visible seam inside the grey pill. The pill owns the
                // background, so the inner field must stay transparent.
                filled: false,
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: palette.muted.withValues(alpha: 0.78),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
                prefixText: widget.prefixText,
                prefixStyle: TextStyle(
                  color: palette.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                suffixIcon: widget.suffix,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordVisibilityButton extends StatelessWidget {
  const _PasswordVisibilityButton({
    required this.visible,
    required this.onTap,
  });

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _SkyPalette.of(
      Theme.of(context).brightness == Brightness.dark,
    );
    return IconButton(
      tooltip: visible ? 'Hide password' : 'Show password',
      onPressed: onTap,
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: palette.icon,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    );
  }
}

class _TermsAgreement extends StatefulWidget {
  const _TermsAgreement({
    required this.accepted,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  State<_TermsAgreement> createState() => _TermsAgreementState();
}

class _TermsAgreementState extends State<_TermsAgreement> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTermsTap;
    _privacyRecognizer = TapGestureRecognizer()..onTap = widget.onPrivacyTap;
  }

  @override
  void didUpdateWidget(covariant _TermsAgreement oldWidget) {
    super.didUpdateWidget(oldWidget);
    _termsRecognizer.onTap = widget.onTermsTap;
    _privacyRecognizer.onTap = widget.onPrivacyTap;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _SkyPalette.of(isDark);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Semantics(
            checked: widget.accepted,
            label: 'I agree to the Terms of Service and Privacy Policy',
            child: GestureDetector(
              key: const Key('signup-terms'),
              onTap: () => widget.onChanged(!widget.accepted),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: widget.accepted ? palette.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.accepted ? palette.accent : palette.border,
                    width: 1.5,
                  ),
                ),
                child: widget.accepted
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                color: palette.muted,
                fontSize: 11.5,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  recognizer: _termsRecognizer,
                  style: TextStyle(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: palette.ink,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  recognizer: _privacyRecognizer,
                  style: TextStyle(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: palette.ink,
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

class _SkyErrorBanner extends StatelessWidget {
  const _SkyErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: isDark ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkyPrimaryButton extends StatelessWidget {
  const _SkyPrimaryButton({
    required this.label,
    required this.loading,
    required this.palette,
    required this.onPressed,
    this.buttonKey,
  });

  final String label;
  final bool loading;
  final _SkyPalette palette;
  final VoidCallback onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          key: buttonKey ?? const Key('signup-submit'),
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: palette.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: palette.accent.withValues(alpha: 0.55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                ),
        ),
      ),
    );
  }
}

class _LowerCaseTextInputFormatter extends TextInputFormatter {
  const _LowerCaseTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toLowerCase());
}

class _BottomLink extends StatelessWidget {
  const _BottomLink({
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _SkyPalette.of(isDark);
    return Center(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: palette.muted,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text.rich(
          TextSpan(
            text: '$prompt ',
            style: TextStyle(
              fontSize: 13,
              color: palette.muted,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(
                text: action,
                style: TextStyle(
                  color: palette.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _LegalDocument { terms, privacy }

void _showLegalInfo(BuildContext context, _LegalDocument document) {
  HapticFeedback.selectionClick();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final palette = _SkyPalette.of(isDark);
  final title =
      document == _LegalDocument.terms ? 'Terms of Service' : 'Privacy Policy';
  final body = document == _LegalDocument.terms
      ? 'By creating a Docmac account, you agree to use the service honestly, '
          'respect the people you connect with, and keep your account '
          'credentials secure. You are responsible for activity that happens '
          'on your account.'
      : 'Docmac uses your name, username, and email to create and secure your '
          'account. We do not sell your personal data. You stay in control of '
          'what you share, and you can adjust your visibility from Privacy '
          'settings at any time.';

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: palette.sheet,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          22 + MediaQuery.viewPaddingOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.handle,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: Icon(Icons.close_rounded, color: palette.icon),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                color: palette.muted,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _phoneWithCountry(ContactCountry country, String phone) {
  final compact = phone.replaceAll(RegExp(r'[\s()\-]'), '');
  if (compact.startsWith('+')) return compact;
  return '${country.code.replaceAll(' ', '')}${compact.replaceFirst(RegExp(r'^0+'), '')}';
}

String _maskedPhone(String phoneNumber) => phoneNumber.length <= 6
    ? phoneNumber
    : '${phoneNumber.substring(0, 4)} ••• ${phoneNumber.substring(phoneNumber.length - 3)}';

Future<ContactCountry?> _showCountryPicker(
        BuildContext context, ContactCountry _) =>
    context.push<ContactCountry>('/register/country');

String? _phoneValidator(String? value) => value != null &&
        RegExp(r'^\+[1-9][0-9]{7,14}$')
            .hasMatch(value.replaceAll(RegExp(r'[\s()-]'), ''))
    ? null
    : 'Enter a valid phone number with country code.';

bool _emailValidator(String email) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

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
      return 'The phone number or verification code is incorrect.';
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
