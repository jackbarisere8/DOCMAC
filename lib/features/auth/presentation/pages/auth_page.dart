import 'dart:typed_data';

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/ui/docmac_iconly.dart';
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
  final _phone = TextEditingController();
  final _code = TextEditingController();
  ContactCountry _country = docmacCountries.first;
  int _step = 0;
  bool _loading = false;
  String? _verificationId;
  int? _resendToken;
  String? _error;

  String get _fullPhoneNumber => _phoneWithCountry(_country, _phone.text);

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
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
    context.go(completed ? '/orbit' : '/register');
  }

  @override
  Widget build(BuildContext context) => _PhoneAuthScaffold(
        verifying: _step == 1,
        loading: _loading,
        onBack: _step == 0 ? () => context.go('/') : _returnToPhoneEntry,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              Text(country.code, style: TextStyle(color: scheme.onSurfaceVariant)),
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
          Text(error!, textAlign: TextAlign.center, style: TextStyle(color: scheme.error, fontSize: 13)),
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

/// A deliberately complete, gated signup journey. Phone verification unlocks
/// the profile steps; only a completed profile opens Orbit on later launches.
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
  // These only support the pre-profile fallback branch below. Post-OTP
  // onboarding never displays a password field.
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
  Uint8List? _profileImageBytes;

  String get _fullPhoneNumber => _phoneWithCountry(_country, _phone.text);

  @override
  void initState() {
    super.initState();
    // A verified phone session can survive an interrupted first-time setup.
    // Resume at the profile step rather than asking for the same OTP again.
    final user = ref.read(authServiceProvider).currentUser;
    if (user?.phoneNumber != null) {
      _phone.text = user!.phoneNumber!;
      _step = 2;
    }
  }

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

  Future<void> _continueEmail() async {
    final email = _email.text.trim();
    if (email.isNotEmpty && !_emailValidator(email)) {
      setState(() => _error = 'Enter a valid email address or skip this step.');
      return;
    }
    await _complete(contactEmail: email.isEmpty ? null : email);
  }

  Future<void> _complete({String? contactEmail}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).completePhoneSignUp(
            username: _username.text,
            displayName: _name.text,
            contactEmail: contactEmail,
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

  // This is only retained for already-built legacy widget trees. New signup
  // screens never navigate to a password step.
  Future<void> _continuePassword() => _continueEmail();

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
    // Every signup step uses the same full-height onboarding surface. This
    // avoids switching back to the previous card-based design for phone OTP.
    if (_step <= 1) {
      final isPhoneStep = _step == 0;
      return _ProfileSetupScaffold(
        step: _step,
        loading: _loading,
        error: _error,
        title: isPhoneStep ? 'Your phone number' : 'Confirm your number',
        description: isPhoneStep
            ? 'Choose your country and enter the number linked to your account.'
            : 'Enter the six-digit code we sent to ${_maskedPhone(_fullPhoneNumber)}.',
        primaryAction: isPhoneStep ? 'Send code' : 'Verify and continue',
        onClose: () => context.go('/'),
        onBack: _back,
        onContinue: isPhoneStep ? _sendCode : _verifyCode,
        footer: isPhoneStep
            ? _BottomLink(
                prompt: 'Already have an account?',
                action: 'Sign in',
                onTap: () => context.go('/auth'),
              )
            : TextButton(
                onPressed: _loading ? null : _sendCode,
                child: const Text('Didn’t receive a code? Send again'),
              ),
        field: isPhoneStep
            ? _PhoneField(
                controller: _phone,
                country: _country,
                onChooseCountry: _chooseCountry,
                validator: (_) => _phoneValidator(_fullPhoneNumber),
              )
            : _OtpField(controller: _code, onSubmitted: _verifyCode),
      );
    }

    // The post-OTP profile sequence collects a name, username, and optional
    // email. Password fields are deliberately not part of this journey.
    if (_step >= 2) {
      return _ProfileSetupScaffold(
        step: _step - 2,
        loading: _loading,
        error: _error,
        onClose: () => context.go('/'),
        onBack: _back,
        onContinue: switch (_step) {
          2 => _continueName,
          3 => _continueUsername,
          _ => _continueEmail,
        },
        onSkip: _step == 4 ? () => _complete() : null,
        avatar: _step == 2
            ? _ProfileSetupAvatar(
                imageBytes: _profileImageBytes,
                onPickImage: _pickProfileImage,
              )
            : null,
        field: switch (_step) {
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
          _ => _ProfileSetupField(
              key: const Key('signup-email'),
              controller: _email,
              hint: 'Email address (optional)',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onSubmitted: _continueEmail,
            ),
        },
      );
    }

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
          _PrimaryButton(
              label: details.action, loading: _loading, onPressed: submit),
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

/// The post-OTP profile flow mirrors the calm, spacious mobile composition in
/// the approved reference: one piece of information at a time and a bottom
/// action that is always easy to reach.
class _ProfileSetupScaffold extends StatelessWidget {
  const _ProfileSetupScaffold({
    required this.step,
    required this.loading,
    required this.error,
    required this.field,
    required this.onClose,
    required this.onBack,
    required this.onContinue,
    this.title,
    this.description,
    this.primaryAction,
    this.onSkip,
    this.avatar,
    this.footer,
  });

  final int step;
  final bool loading;
  final String? error;
  final Widget field;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final String? title;
  final String? description;
  final String? primaryAction;
  final VoidCallback? onSkip;
  final Widget? avatar;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final defaultCopy = switch (step) {
      0 => (
          title: 'Profile info',
          description: 'Please add the name people will know you by.',
        ),
      1 => (
          title: 'Choose a username',
          description: 'This will be your unique Docmac identity.',
        ),
      _ => (
          title: 'Add your email',
          description: 'An email helps us contact you about your account.',
        ),
    };
    final copy = (
      title: title ?? defaultCopy.title,
      description: description ?? defaultCopy.description,
    );

    return Scaffold(
      backgroundColor: Colors.white,
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
                        tooltip: step == 0 ? 'Close signup' : 'Previous step',
                        onPressed: step == 0 ? onClose : onBack,
                        icon: Icon(
                          step == 0
                              ? Icons.close_rounded
                              : Icons.arrow_back_rounded,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Your phone number is used to sign in.'),
                        )),
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
                    copy.title,
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
                    copy.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (step == 2) ...[
                    const SizedBox(height: 7),
                    Text(
                      'This step is optional.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
                            primaryAction ?? 'Next',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                  if (onSkip != null) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: loading ? null : onSkip,
                      child: const Text('Skip'),
                    ),
                  ],
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

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: controller,
      autofocus: true,
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

class _SignupDetail {
  const _SignupDetail(this.title, this.description, this.action, this.icon);
  final String title;
  final String description;
  final String action;
  final IconData icon;
}

const _signupDetails = [
  _SignupDetail(
      'What’s your\nphone number?',
      'We’ll send a secure code to confirm it.',
      'Send code',
      DocmacIconlyLight.call),
  _SignupDetail('Confirm it’s\nyou.', 'Enter the code we sent you.',
      'Verify and continue', DocmacIconlyLight.shieldDone),
  _SignupDetail(
      'Tell us your\nname.',
      'Use the name your people will recognise.',
      'Continue',
      DocmacIconlyLight.user),
  _SignupDetail(
      'Claim your\nusername.',
      'This is your one-of-a-kind Docmac identity.',
      'Finish setup',
      DocmacIconlyLight.profile),
  _SignupDetail(
      'Keep it\nprivate.',
      'Create a password to protect your account.',
      'Continue',
      DocmacIconlyLight.lock),
  _SignupDetail(
      'Add your\nemail.',
      'We’ll keep it with your account for important updates.',
      'Finish setup',
      DocmacIconlyLight.message),
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
                      IconButton(
                        tooltip: onBack == null ? 'Back' : 'Previous step',
                        onPressed: onBack ?? () => context.go('/'),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.black87),
                      ),
                      TextButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('We use your phone number to sign you in.'),
                        )),
                        icon: const Icon(Icons.help_outline_rounded, size: 18),
                        label: const Text('Help'),
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 84),
                  Text(
                    eyebrow,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 29,
                      height: 1.12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 64),
                  child,
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
            child: Image.asset('assets/images/docmac_logo.png',
                width: 28, height: 28),
          ),
          const SizedBox(width: 8),
          Text('Docmac',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
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
              color: index <= step
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]'))
          ],
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
  ) =>
      newValue.copyWith(text: newValue.text.toLowerCase());
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.label, required this.loading, required this.onPressed});
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
        child: loading
            ? _SignalLoader(color: Theme.of(context).colorScheme.onPrimary)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
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
            final pulse =
                .86 + (math.sin(_controller.value * math.pi * 2) * .14);
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
        Icon(DocmacIconlyLight.infoCircle,
            color: scheme.onErrorContainer, size: 18),
        const SizedBox(width: 9),
        Expanded(
            child: Text(message,
                style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontSize: 12,
                    height: 1.35))),
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

Future<ContactCountry?> _showCountryPicker(
        BuildContext context, ContactCountry _) =>
    context.push<ContactCountry>('/register/country');

String? _phoneValidator(String? value) => value != null &&
        RegExp(r'^\+[1-9][0-9]{7,14}$')
            .hasMatch(value.replaceAll(RegExp(r'[\s()-]'), ''))
    ? null
    : 'Enter a valid phone number with country code.';

String? _passwordValidator(String? value) =>
    value != null && value.length >= 6 && value.length <= 24
        ? null
        : 'Use a password from 6 to 24 characters.';

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
