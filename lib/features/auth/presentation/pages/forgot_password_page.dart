import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth_service.dart';
import '../providers/auth_provider.dart';

/// Three-step reset matching the reference flow: email, six-digit code, then a
/// new password with live strength feedback.
///
/// Codes and reset tokens are issued by the Cloud Functions in `functions/`.
/// The client only ever holds them transiently; the server stores hashes.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

enum _ResetStage { email, code, password, done }

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  static const _resendWindow = 60;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  _ResetStage _stage = _ResetStage.email;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _devCode;
  String? _resetToken;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  int get _step => switch (_stage) {
        _ResetStage.email => 1,
        _ResetStage.code => 2,
        _ResetStage.password => 3,
        _ResetStage.done => 3,
      };

  int get _strength {
    final value = _password.text;
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= 8) score += 1;
    if (value.length >= 12) score += 1;
    if (RegExp(r'[a-z]').hasMatch(value) && RegExp(r'[A-Z]').hasMatch(value)) {
      score += 1;
    }
    if (RegExp(r'\d').hasMatch(value)) score += 1;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score += 1;
    return score.clamp(0, 4);
  }

  bool get _canSubmitPassword =>
      _password.text.length >= 8 && _password.text == _confirm.text;

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendWindow);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final devCode = await ref
          .read(authServiceProvider)
          .requestPasswordResetCode(email: email);
      if (!mounted) return;
      setState(() {
        _stage = _ResetStage.code;
        _devCode = devCode;
      });
      _code.clear();
      _startCountdown();
    } on PasswordResetException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to send a code. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_loading || _secondsLeft > 0) return;
    await _sendCode();
  }

  Future<void> _verifyCode() async {
    if (_loading) return;
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the six digits from the email.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await ref.read(authServiceProvider).verifyPasswordResetCode(
            email: _email.text.trim(),
            code: code,
          );
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _resetToken = token;
        _stage = _ResetStage.password;
        _secondsLeft = 0;
      });
    } on PasswordResetException catch (error) {
      if (mounted) {
        setState(() {
          _error = _messageFor(error);
          if (error.code == 'code_expired' ||
              error.code == 'too_many_attempts') {
            _secondsLeft = 0;
          }
        });
      }
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to verify that code.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeReset() async {
    final password = _password.text;
    if (password.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = 'The passwords do not match.');
      return;
    }

    final token = _resetToken;
    if (token == null) {
      _restart();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).completePasswordReset(
            token: token,
            password: password,
          );
      if (!mounted) return;
      setState(() {
        _stage = _ResetStage.done;
        _code.clear();
        _password.clear();
        _confirm.clear();
      });
    } on PasswordResetException catch (error) {
      if (mounted) {
        setState(() {
          _error = _messageFor(error);
          if (error.code == 'invalid_token') {
            _stage = _ResetStage.email;
            _resetToken = null;
          }
        });
      }
    } on AuthServiceUnavailableException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to reset your password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _restart() {
    _timer?.cancel();
    setState(() {
      _stage = _ResetStage.email;
      _error = null;
      _secondsLeft = 0;
      _devCode = null;
      _resetToken = null;
      _code.clear();
      _password.clear();
      _confirm.clear();
    });
  }

  void _back() {
    if (_stage == _ResetStage.code) {
      _timer?.cancel();
      setState(() {
        _stage = _ResetStage.email;
        _error = null;
        _secondsLeft = 0;
      });
      return;
    }
    if (_stage == _ResetStage.password) {
      _restart();
      return;
    }
    context.go('/auth');
  }

  String _messageFor(PasswordResetException error) {
    switch (error.code) {
      case 'invalid_email':
        return 'That email address is not valid.';
      case 'invalid_code':
        return 'That code is incorrect. Check the six digits and try again.';
      case 'code_expired':
        return 'That code has expired. Request a new one.';
      case 'too_many_attempts':
        return 'Too many incorrect attempts. Request a new code.';
      case 'rate_limited':
        final wait = error.retryAfterSeconds;
        return wait == null
            ? 'Too many requests. Try again in a little while.'
            : 'Too many requests. Try again in ${wait}s.';
      case 'invalid_token':
        return 'Your reset session expired. Start again.';
      case 'weak_password':
        return 'Choose a stronger password with at least 8 characters.';
      case 'network':
        return 'Can’t reach the reset service. Check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _ResetPalette.of(isDark);
    final media = MediaQuery.of(context);
    final headerHeight = media.padding.top + 88;
    final step = _step;

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
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: headerHeight,
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
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Row(
                      children: [
                        _ResetBackButton(
                          palette: palette,
                          isDark: isDark,
                          onTap: _back,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StepBar(
                            step: step,
                            total: 3,
                            palette: palette,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '$step of 3',
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: media.size.height - headerHeight,
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
                  minimum: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeIn,
                          child: switch (_stage) {
                            _ResetStage.email => _buildEmailStage(palette),
                            _ResetStage.code => _buildCodeStage(palette),
                            _ResetStage.password =>
                              _buildPasswordStage(palette),
                            _ResetStage.done => _buildDoneStage(palette),
                          },
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
    );
  }

  Widget _buildEmailStage(_ResetPalette palette) {
    return Form(
      child: Column(
        key: const ValueKey('reset-email'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StageIcon(icon: Icons.lock_reset_rounded, palette: palette),
          const SizedBox(height: 20),
          _StageTitle(text: 'Forgot password?', palette: palette),
          const SizedBox(height: 8),
          Text(
            'No worries, it happens. Enter the email on your account and '
            'we’ll send you a six-digit code to choose a new password.',
            style: TextStyle(
              color: palette.muted,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 26),
          _ResetField(
            key: const Key('forgot-email'),
            controller: _email,
            autofocus: true,
            leadingIcon: Icons.mail_outline_rounded,
            hintText: 'Email address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => _sendCode(),
            validator: (value) => _emailPattern.hasMatch(value?.trim() ?? '')
                ? null
                : 'Enter a valid email address',
            palette: palette,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ResetErrorBanner(message: _error!),
          ],
          const SizedBox(height: 24),
          _ResetPrimaryButton(
            key: const Key('forgot-submit'),
            label: 'Send code',
            loading: _loading,
            palette: palette,
            onPressed: _sendCode,
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => context.go('/auth'),
              style: TextButton.styleFrom(
                foregroundColor: palette.muted,
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text.rich(
                TextSpan(
                  text: 'Remembered it? ',
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.muted,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    TextSpan(
                      text: 'Sign in',
                      style: TextStyle(
                        color: palette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStage(_ResetPalette palette) {
    final email = _email.text.trim();
    return Column(
      key: const ValueKey('reset-code-stage'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StageIcon(icon: Icons.mark_email_read_rounded, palette: palette),
        const SizedBox(height: 20),
        _StageTitle(text: 'Check your email', palette: palette),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Enter the six-digit code we sent to ',
            style: TextStyle(
              color: palette.muted,
              fontSize: 13.5,
              height: 1.5,
            ),
            children: [
              TextSpan(
                text: email,
                style: TextStyle(
                  color: palette.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        if (_devCode != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Emulator code: $_devCode',
              style: TextStyle(
                color: palette.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _OtpField(
          controller: _code,
          palette: palette,
          hasError: _error != null,
          onCompleted: (_) => _verifyCode(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          _ResetErrorBanner(message: _error!),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn’t get it? ',
              style: TextStyle(color: palette.muted, fontSize: 12.5),
            ),
            if (_secondsLeft > 0)
              Text(
                'Resend in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: palette.muted.withValues(alpha: 0.75),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              TextButton(
                onPressed: _loading ? null : _resend,
                style: TextButton.styleFrom(
                  foregroundColor: palette.accent,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _loading ? 'Sending…' : 'Resend code',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _ResetPrimaryButton(
          key: const Key('forgot-verify'),
          label: 'Verify code',
          loading: _loading,
          palette: palette,
          onPressed: _verifyCode,
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: _loading ? null : _back,
            style: TextButton.styleFrom(
              foregroundColor: palette.muted,
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text.rich(
              TextSpan(
                text: 'Wrong address? ',
                style: TextStyle(
                  fontSize: 13,
                  color: palette.muted,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(
                    text: 'Use a different email',
                    style: TextStyle(
                      color: palette.ink,
                      fontWeight: FontWeight.w700,
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

  Widget _buildPasswordStage(_ResetPalette palette) {
    final matches =
        _password.text.isNotEmpty && _password.text == _confirm.text;

    return Column(
      key: const ValueKey('reset-password-stage'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StageIcon(icon: Icons.key_rounded, palette: palette),
        const SizedBox(height: 20),
        _StageTitle(text: 'Create new password', palette: palette),
        const SizedBox(height: 8),
        Text(
          'Make it one you haven’t used before. You’ll need it the next time '
          'you log in.',
          style: TextStyle(
            color: palette.muted,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _ResetField(
          key: const Key('reset-password'),
          controller: _password,
          autofocus: true,
          leadingIcon: Icons.lock_outline_rounded,
          hintText: 'New password',
          obscureText: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.next,
          palette: palette,
        ),
        const SizedBox(height: 12),
        _ResetField(
          key: const Key('reset-confirm'),
          controller: _confirm,
          leadingIcon: Icons.lock_outline_rounded,
          hintText: 'Confirm new password',
          obscureText: _obscureConfirm,
          onToggleObscure: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _completeReset(),
          palette: palette,
        ),
        const SizedBox(height: 14),
        _StrengthMeter(strength: _strength, palette: palette),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _RuleChip(
                label: 'At least 8 characters',
                met: _password.text.length >= 8,
                palette: palette,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RuleChip(
                label: 'Passwords match',
                met: matches,
                palette: palette,
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          _ResetErrorBanner(message: _error!),
        ],
        const SizedBox(height: 22),
        _ResetPrimaryButton(
          key: const Key('reset-submit'),
          label: 'Reset Password',
          loading: _loading,
          palette: palette,
          enabled: _canSubmitPassword,
          onPressed: _completeReset,
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: _loading ? null : _restart,
            style: TextButton.styleFrom(
              foregroundColor: palette.muted,
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Start over',
              style: TextStyle(
                fontSize: 13,
                color: palette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoneStage(_ResetPalette palette) {
    return Column(
      key: const ValueKey('reset-done-stage'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    palette.accent,
                    palette.accent.withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.28),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        _StageTitle(
          text: 'Password updated',
          palette: palette,
          centered: true,
        ),
        const SizedBox(height: 10),
        Text(
          'Your password has been changed. Sign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.muted,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        _ResetPrimaryButton(
          key: const Key('reset-done'),
          label: 'Back to sign in',
          loading: false,
          palette: palette,
          onPressed: () => context.go('/auth'),
        ),
      ],
    );
  }
}

class _OtpField extends StatefulWidget {
  const _OtpField({
    required this.controller,
    required this.palette,
    required this.onCompleted,
    this.hasError = false,
  });

  final TextEditingController controller;
  final _ResetPalette palette;
  final ValueChanged<String> onCompleted;
  final bool hasError;

  @override
  State<_OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<_OtpField> {
  static const _length = 6;

  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
    widget.controller.addListener(_handleText);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    widget.controller.removeListener(_handleText);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocus() {
    if (!mounted || _focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  void _handleText() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = math.min(52.0, (constraints.maxWidth - gap * 5) / 6);

        return Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < _length; index++) ...[
                  if (index > 0) const SizedBox(width: gap),
                  _OtpBox(
                    width: width,
                    digit: index < code.length ? code[index] : '',
                    active: _focused &&
                        (index == code.length ||
                            (code.length == _length && index == _length - 1)),
                    hasError: widget.hasError,
                    palette: widget.palette,
                  ),
                ],
              ],
            ),
            // One invisible field sits over the boxes: paste, backspace and
            // keyboard handling all behave natively, and the boxes are only a
            // rendering of its value.
            Positioned.fill(
              child: TextField(
                key: const Key('forgot-code'),
                controller: widget.controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: _length,
                autofillHints: const [AutofillHints.oneTimeCode],
                enableInteractiveSelection: false,
                showCursor: false,
                cursorColor: Colors.transparent,
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.length == _length) widget.onCompleted(value);
                },
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.width,
    required this.digit,
    required this.active,
    required this.hasError,
    required this.palette,
  });

  final double width;
  final String digit;
  final bool active;
  final bool hasError;
  final _ResetPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = hasError
        ? theme.colorScheme.error
        : active
            ? palette.accent
            : palette.border.withValues(alpha: isDark ? 0.9 : 1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: width,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? palette.sheet : palette.field,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
          width: active || hasError ? 1.6 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: palette.accent.withValues(alpha: isDark ? 0.22 : 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Text(
        digit,
        style: TextStyle(
          color: palette.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength, required this.palette});

  final int strength;
  final _ResetPalette palette;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color color;
    final String label;
    if (strength <= 1) {
      color = const Color(0xFFE4572E);
      label = strength == 0 ? 'Strength' : 'Weak';
    } else if (strength == 2) {
      color = const Color(0xFFE5A50A);
      label = 'Fair';
    } else if (strength == 3) {
      color = const Color(0xFF2E9E5B);
      label = 'Good';
    } else {
      color = const Color(0xFF2E9E5B);
      label = 'Strong';
    }

    final track = palette.muted.withValues(alpha: isDark ? 0.26 : 0.16);

    return Row(
      children: [
        for (var index = 0; index < 4; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 5,
              decoration: BoxDecoration(
                color: index < strength ? color : track,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: strength == 0 ? palette.muted : color,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({
    required this.label,
    required this.met,
    required this.palette,
  });

  final String label;
  final bool met;
  final _ResetPalette palette;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const success = Color(0xFF2E9E5B);
    final color = met ? success : palette.muted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: met
            ? success.withValues(alpha: isDark ? 0.16 : 0.08)
            : palette.field,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({
    required this.step,
    required this.total,
    required this.palette,
  });

  final int step;
  final int total;
  final _ResetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < total; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 5,
              decoration: BoxDecoration(
                color: index < step ? palette.accent : palette.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ResetBackButton extends StatelessWidget {
  const _ResetBackButton({
    required this.palette,
    required this.isDark,
    required this.onTap,
  });

  final _ResetPalette palette;
  final bool isDark;
  final VoidCallback onTap;

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
          message: 'Back',
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

class _StageIcon extends StatelessWidget {
  const _StageIcon({required this.icon, required this.palette});

  final IconData icon;
  final _ResetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: palette.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: palette.accent, size: 26),
      ),
    );
  }
}

class _StageTitle extends StatelessWidget {
  const _StageTitle({
    required this.text,
    required this.palette,
    this.centered = false,
  });

  final String text;
  final _ResetPalette palette;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: palette.ink,
        fontSize: 26,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
      ),
    );
  }
}

class _ResetField extends StatefulWidget {
  const _ResetField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.palette,
    this.leadingIcon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.autofocus = false,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.obscureText = false,
    this.onToggleObscure,
  });

  final TextEditingController controller;
  final String hintText;
  final _ResetPalette palette;
  final IconData? leadingIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool autofocus;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final VoidCallback? onToggleObscure;

  @override
  State<_ResetField> createState() => _ResetFieldState();
}

class _ResetFieldState extends State<_ResetField> {
  final _focusNode = FocusNode();
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
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted || _focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _focused ? palette.sheet : palette.field,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: _focused ? palette.ink : Colors.transparent,
          width: 1.25,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SizedBox(
        height: 54,
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
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                autofillHints: widget.autofillHints,
                onFieldSubmitted: widget.onSubmitted,
                validator: widget.validator,
                onChanged: widget.onChanged,
                obscureText: widget.obscureText,
                enableSuggestions: !widget.obscureText,
                autocorrect: !widget.obscureText,
                cursorColor: palette.accent,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  filled: false,
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: palette.muted.withValues(alpha: 0.78),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                  ),
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (widget.onToggleObscure != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onToggleObscure,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    widget.obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 19,
                    color: palette.icon,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResetPrimaryButton extends StatelessWidget {
  const _ResetPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.palette,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final bool loading;
  final _ResetPalette palette;
  final VoidCallback onPressed;
  final bool enabled;

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
        height: 54,
        width: double.infinity,
        child: FilledButton(
          onPressed: loading || !enabled ? null : onPressed,
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

class _ResetErrorBanner extends StatelessWidget {
  const _ResetErrorBanner({required this.message});

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

class _ResetPalette {
  const _ResetPalette({
    required this.skyTop,
    required this.skyMid,
    required this.skyBottom,
    required this.sheet,
    required this.field,
    required this.ink,
    required this.muted,
    required this.icon,
    required this.border,
    required this.accent,
  });

  final Color skyTop;
  final Color skyMid;
  final Color skyBottom;
  final Color sheet;
  final Color field;
  final Color ink;
  final Color muted;
  final Color icon;
  final Color border;
  final Color accent;

  static _ResetPalette of(bool isDark) => isDark ? _dark : _light;

  static const _light = _ResetPalette(
    skyTop: Color(0xFFA6DFF7),
    skyMid: Color(0xFFD8F0FC),
    skyBottom: Color(0xFFF4FBFF),
    sheet: Colors.white,
    field: Color(0xFFF4F6F9),
    ink: Color(0xFF0B1736),
    muted: Color(0xFF64748B),
    icon: Color(0xFF7F8B9E),
    border: Color(0xFFE1E7F0),
    accent: Color(0xFF1E2A78),
  );

  static const _dark = _ResetPalette(
    skyTop: Color(0xFF17415F),
    skyMid: Color(0xFF0D2438),
    skyBottom: Color(0xFF081524),
    sheet: Color(0xFF0A1321),
    field: Color(0xFF151F2E),
    ink: Color(0xFFF8FAFC),
    muted: Color(0xFF96A5B9),
    icon: Color(0xFF8494A9),
    border: Color(0xFF26354A),
    accent: Color(0xFF4265E8),
  );
}
