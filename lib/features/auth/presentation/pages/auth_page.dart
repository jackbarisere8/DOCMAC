
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../contacts/presentation/pages/contact_pages.dart';
import '../../../me/presentation/profile_media_store.dart';
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

    return _EmailSignInScaffold(
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

class _EmailSignInScaffold extends StatelessWidget {
  const _EmailSignInScaffold({
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: loading ? null : onBack,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in with your email to continue.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 36),
                          TextField(
                            key: const Key('signin-email'),
                            controller: emailController,
                            autofocus: true,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: 'Email address',
                              hintText: 'name@example.com',
                              filled: false,
                              prefixIcon:
                                  const Icon(Icons.email_outlined, size: 20),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: scheme.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: scheme.primary, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            key: const Key('signin-password'),
                            controller: passwordController,
                            obscureText: obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => onSubmitted(),
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'Password',
                              filled: false,
                              prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: onToggleObscure,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: scheme.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: scheme.primary, width: 2),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: onForgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: scheme.error, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const Key('signin-submit'),
                            onPressed: loading ? null : onSubmitted,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: loading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: scheme.onPrimary,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: TextButton(
                              onPressed: onSwitchToPhone,
                              child: const Text('Sign in with phone number'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: onGoToRegister,
                              child: Text.rich(
                                TextSpan(
                                  text: "Don't have an account? ",
                                  style:
                                      TextStyle(color: scheme.onSurfaceVariant),
                                  children: const [
                                    TextSpan(
                                      text: 'Sign up',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
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
      ),
    );
  }
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: verifying ? 'Edit phone number' : 'Back',
                  onPressed: loading ? null : onBack,
                  icon: Icon(
                    verifying ? Icons.close_rounded : Icons.arrow_back_rounded,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Expanded(
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
            ],
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
  final _passwordFocus = FocusNode();
  ContactCountry _country = docmacCountries.first;
  int _step = 0;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _verificationId;
  int? _resendToken;
  String? _error;
  Uint8List? _profileImageBytes;

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
          _step = 3;
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
    _passwordFocus.dispose();
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

  void _continueName() {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Enter the name your people will know.');
      return;
    }
    _goTo(3);
  }

  Future<void> _continueUsername() async {
    final username = _username.text.trim().replaceFirst(RegExp(r'^@'), '');
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
      return setState(
          () => _error = 'Use 3–20 letters, numbers, or underscores.');
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

  Future<void> _complete() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!_emailValidator(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).completeDualSignUp(
            email: email,
            password: password,
            username: _username.text,
            displayName: _name.text,
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
      _code.clear();
      _verificationId = null;
      _resendToken = null;
      _goTo(0);
      return;
    }
    _goTo(_step - 1);
  }

  @override
  Widget build(BuildContext context) {
    final isFirstStep = _step == 0;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _ProfileSetupScaffold(
      isFirstStep: isFirstStep,
      loading: _loading,
      error: _error,
      title: switch (_step) {
        0 => 'Your phone number',
        1 => 'Confirm your number',
        2 => 'Profile info',
        3 => 'Choose a username',
        _ => 'Login credentials',
      },
      description: switch (_step) {
        0 =>
          'Choose your country and enter your mobile number for OTP verification.',
        1 => 'Enter the six-digit code sent to ${_maskedPhone(_fullPhoneNumber)}.',
        2 => 'Please add the name people will know you by.',
        3 => 'This will be your unique Docmac identity.',
        _ => 'Set your email and password to sign in to Docmac anytime.',
      },
      primaryAction: switch (_step) {
        0 => 'Send code',
        1 => 'Verify and continue',
        2 => 'Next',
        3 => 'Next',
        _ => 'Complete setup',
      },
      onClose: () => context.go('/'),
      onBack: _back,
      onContinue: switch (_step) {
        0 => _confirmAndSendCode,
        1 => _verifyCode,
        2 => _continueName,
        3 => _continueUsername,
        _ => _complete,
      },
      avatar: _step == 2
          ? _ProfileSetupAvatar(
              imageBytes: _profileImageBytes,
              onPickImage: _pickProfileImage,
            )
          : null,
      field: switch (_step) {
        0 => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: _chooseCountry,
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(56),
                  side: BorderSide(color: scheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Text(_country.flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _country.name,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _country.code,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('signup-phone'),
                controller: _phone,
                autofocus: true,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _confirmAndSendCode(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  prefixText: '${_country.code} ',
                  hintText: '801 234 5678',
                  filled: false,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
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
            ],
          ),
        1 => Column(
            children: [
              TextField(
                key: const Key('signup-otp'),
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verifyCode(),
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  letterSpacing: 10,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  filled: false,
                  enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: scheme.outlineVariant, width: 2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: scheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loading ? null : _sendCode,
                child: const Text('Didn’t receive a code? Send again'),
              ),
            ],
          ),
        2 => _ProfileSetupField(
            key: const Key('signup-full-name'),
            controller: _name,
            hint: 'Full name',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onSubmitted: _continueName,
          ),
        3 => _ProfileSetupField(
            key: const Key('signup-username'),
            controller: _username,
            hint: 'Username',
            prefixText: '@',
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              const _LowerCaseTextInputFormatter(),
            ],
            onSubmitted: _continueUsername,
          ),
        _ => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProfileSetupField(
                key: const Key('signup-email'),
                controller: _email,
                hint: 'Email address',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onSubmitted: () => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 24),
              _ProfileSetupField(
                key: const Key('signup-password'),
                controller: _password,
                focusNode: _passwordFocus,
                autofocus: false,
                hint: 'Password (min. 6 characters)',
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                onSubmitted: _complete,
              ),
            ],
          ),
      },
      footer: _step == 0
          ? _BottomLink(
              prompt: 'Already have an account?',
              action: 'Sign in',
              onTap: () => context.go('/auth'),
            )
          : null,
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 86,
        maxWidth: 1200,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _profileImageBytes = bytes);
      ProfileMediaStore.avatarBytes.value = bytes;
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'We could not open the camera. Try again.');
      }
    }
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

/// The profile flow mirrors the calm, spacious mobile composition in
/// Docmac: one piece of information at a time and a bottom action
/// that is always easy to reach.
class _ProfileSetupScaffold extends StatelessWidget {
  const _ProfileSetupScaffold({
    required this.isFirstStep,
    required this.loading,
    required this.error,
    required this.title,
    required this.description,
    required this.primaryAction,
    required this.field,
    required this.onClose,
    required this.onBack,
    required this.onContinue,
    this.avatar,
    this.footer,
  });

  final bool isFirstStep;
  final bool loading;
  final String? error;
  final String title;
  final String description;
  final String primaryAction;
  final Widget field;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final Widget? avatar;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: isFirstStep ? 'Close signup' : 'Previous step',
                        onPressed: isFirstStep ? onClose : onBack,
                        icon: Icon(
                          isFirstStep
                              ? Icons.close_rounded
                              : Icons.arrow_back_rounded,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAuthHelpSheet(context),
                        icon: const Icon(Icons.help_outline_rounded, size: 18),
                        label: const Text('Help'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 27,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (avatar != null) ...[
                    const SizedBox(height: 34),
                    Center(child: avatar!),
                    const SizedBox(height: 34),
                  ] else
                    const SizedBox(height: 78),
                  field,
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  FilledButton(
                    onPressed: loading ? null : onContinue,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: accent.withValues(alpha: .55),
                      shape: const StadiumBorder(),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : Text(
                            primaryAction,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: 4),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSetupField extends StatelessWidget {
  const _ProfileSetupField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    this.prefixText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
    this.obscureText = false,
    this.suffixIcon,
    this.focusNode,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSubmitted;
  final String? prefixText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool autocorrect;
  final bool enableSuggestions;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      autofillHints: autofillHints,
      onSubmitted: (_) => onSubmitted(),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        suffixIcon: suffixIcon,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent, width: 1.8),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent, width: 2.4),
        ),
      ),
    );
  }
}


class _ProfileSetupAvatar extends StatelessWidget {
  const _ProfileSetupAvatar({
    required this.imageBytes,
    required this.onPickImage,
  });

  final Uint8List? imageBytes;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4F1),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: imageBytes == null
                    ? const Icon(Icons.person_outline_rounded,
                        color: Color(0xFF7F8D84), size: 54)
                    : Image.memory(imageBytes!, fit: BoxFit.cover),
              ),
            ),
          ),
          Positioned(
            right: -3,
            bottom: 1,
            child: Material(
              color: accent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onPickImage,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(Icons.camera_alt_outlined,
                      color: Colors.white, size: 23),
                ),
              ),
            ),
          ),
        ],
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
  const _BottomLink(
      {required this.prompt, required this.action, required this.onTap});
  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(
          onPressed: onTap,
          child: Text.rich(TextSpan(text: '$prompt ', children: [
            TextSpan(
                text: action,
                style: const TextStyle(fontWeight: FontWeight.w800))
          ])),
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
