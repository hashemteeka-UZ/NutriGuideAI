import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/app_failure.dart';
import '../../../core/network/failure_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/emoji.dart';
import '../../../core/ui/rise_in.dart';
import '../domain/auth_validation.dart';
import '../domain/session.dart';
import 'session_controller.dart';

enum AuthMode { login, register }

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthFormScreen(mode: AuthMode.login);
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthFormScreen(mode: AuthMode.register);
  }
}

class AuthFormScreen extends ConsumerStatefulWidget {
  const AuthFormScreen({required this.mode, super.key});

  final AuthMode mode;

  @override
  ConsumerState<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends ConsumerState<AuthFormScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  var _obscure = true;
  var _showExpired = false;
  var _checkedReason = false;
  var _secondsLeft = 0;
  Timer? _countdown;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _countdown?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _captureExpiredReason();
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final theme = Theme.of(context);
    final register = widget.mode == AuthMode.register;
    final title = register ? l10n.registerTitle : l10n.loginTitle;
    final subtitle = register ? l10n.registerSubtitle : l10n.loginSubtitle;
    final submitLabel = register ? l10n.registerSubmit : l10n.loginSubmit;
    final hintMet = _password.text.length >= authPasswordMinLength;
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: IconButton(
                              tooltip: l10n.authBack,
                              onPressed: _busy
                                  ? null
                                  : () => context.go('/welcome'),
                              icon: const BackButtonIcon(),
                            ),
                          ),
                          if (_showExpired) ...<Widget>[
                            const SizedBox(height: 8),
                            DecoratedBox(
                              key: const Key('session-expired-banner'),
                              decoration: BoxDecoration(
                                color: colors.signalSoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Text(
                                  l10n.failureTokenInvalid,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.fg,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          RiseIn(
                            index: 0,
                            child: Column(
                              children: <Widget>[
                                const Emoji('waving-hand', size: 64),
                                const SizedBox(height: 10),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: colors.fg,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colors.fg2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          RiseIn(
                            index: 1,
                            child: _LabeledField(
                              label: l10n.authEmailLabel,
                              child: TextFormField(
                                key: const Key('auth-email'),
                                controller: _email,
                                enabled: !_busy,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: const <String>[
                                  AutofillHints.email,
                                ],
                                textDirection: TextDirection.ltr,
                                onChanged: (_) => _clearEmailError(),
                                decoration: _decoration(
                                  colors,
                                  errorText: _emailError,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          RiseIn(
                            index: 2,
                            child: _LabeledField(
                              label: l10n.authPasswordLabel,
                              child: TextFormField(
                                key: const Key('auth-password'),
                                controller: _password,
                                enabled: !_busy,
                                obscureText: _obscure,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: <String>[
                                  register
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                textDirection: TextDirection.ltr,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) => setState(() {
                                  _passwordError = null;
                                }),
                                onFieldSubmitted: (_) => unawaited(_submit()),
                                decoration: _decoration(
                                  colors,
                                  errorText: _passwordError,
                                  helper: register
                                      ? l10n.authPasswordHint
                                      : null,
                                  helperColor: hintMet ? colors.ok : colors.fg3,
                                  helperIcon: register && hintMet
                                      ? Icon(
                                          Icons.check_rounded,
                                          color: colors.ok,
                                          size: 18,
                                        )
                                      : null,
                                  suffix: IconButton(
                                    tooltip: _obscure
                                        ? l10n.authShowPassword
                                        : l10n.authHidePassword,
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_formError != null) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(
                              _formError!,
                              key: const Key('auth-form-error'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.danger,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          RiseIn(
                            index: 3,
                            child: FilledButton(
                              key: const Key('auth-submit'),
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.brand,
                                foregroundColor: colors.onBrand,
                                disabledBackgroundColor: colors.brand
                                    .withValues(alpha: 0.55),
                                disabledForegroundColor: colors.onBrand,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _busy || _secondsLeft > 0
                                  ? null
                                  : () => unawaited(_submit()),
                              child: _busy
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: colors.onBrand,
                                      ),
                                    )
                                  : Text(
                                      _secondsLeft > 0
                                          ? l10n.failureRateLimitedSeconds(
                                              _secondsLeft,
                                            )
                                          : submitLabel,
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          RiseIn(
                            index: 4,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                Text(
                                  register
                                      ? l10n.registerFooterPrompt
                                      : l10n.loginFooterPrompt,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.fg2,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => context.go(
                                          register ? '/login' : '/register',
                                        ),
                                  child: Text(
                                    register
                                        ? l10n.registerFooterAction
                                        : l10n.loginFooterAction,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _captureExpiredReason() {
    if (_checkedReason || widget.mode != AuthMode.login) {
      return;
    }
    _checkedReason = true;
    final session = ref.read(sessionControllerProvider);
    _showExpired =
        session is SignedOut && session.reason == SignOutReason.sessionExpired;
    if (_showExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(sessionControllerProvider.notifier).consumeExpiredReason();
        }
      });
    }
  }

  void _clearEmailError() {
    if (_emailError != null) {
      setState(() => _emailError = null);
    }
  }

  Future<void> _submit() async {
    if (_busy || _secondsLeft > 0) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final emailError = _emailMessage(validateEmail(_email.text), l10n);
    final passwordError = _passwordMessage(
      widget.mode == AuthMode.register
          ? validateRegisterPassword(_password.text)
          : validateLoginPassword(_password.text),
      l10n,
    );
    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
        _formError = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _emailError = null;
      _passwordError = null;
      _formError = null;
    });
    final session = ref.read(sessionControllerProvider.notifier);
    try {
      if (widget.mode == AuthMode.register) {
        await session.register(email: _email.text, password: _password.text);
      } else {
        await session.login(email: _email.text, password: _password.text);
      }
      TextInput.finishAutofillContext();
    } on AppFailure catch (failure) {
      if (!mounted) {
        return;
      }
      _applyFailure(failure, l10n);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _applyFailure(AppFailure failure, AppLocalizations l10n) {
    String? emailError;
    String? passwordError;
    String? formError;
    if (failure is ApiProblem && failure.code == 'VALIDATION_ERROR') {
      var other = failure.errors.isEmpty;
      for (final issue in failure.errors) {
        final field = issue.loc.isEmpty ? null : issue.loc.last;
        if (field == 'email') {
          emailError ??= l10n.authEmailInvalid;
        } else if (field == 'password') {
          passwordError ??= l10n.authPasswordInvalid;
        } else {
          other = true;
        }
      }
      if (emailError == null && passwordError == null) {
        other = true;
      }
      formError = other ? l10n.failureValidation : null;
    } else {
      formError = failureMessage(l10n, failure);
      if (failure is ApiProblem && failure.code == 'INVALID_CREDENTIALS') {
        _password.clear();
      }
      final retryAfter = failure is ApiProblem ? failure.retryAfter : null;
      if (failure is ApiProblem &&
          failure.code == 'RATE_LIMITED' &&
          retryAfter != null &&
          retryAfter > 0) {
        _startCountdown(retryAfter);
      }
    }
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _formError = formError;
    });
  }

  void _startCountdown(int seconds) {
    _countdown?.cancel();
    _secondsLeft = seconds;
    _countdown = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft -= 1;
        if (_secondsLeft <= 0) {
          _secondsLeft = 0;
          timer.cancel();
        }
      });
    });
  }

  String? _emailMessage(String? code, AppLocalizations l10n) {
    return switch (code) {
      null => null,
      'required' => l10n.authEmailRequired,
      _ => l10n.authEmailInvalid,
    };
  }

  String? _passwordMessage(String? code, AppLocalizations l10n) {
    return switch (code) {
      null => null,
      'required' => l10n.authPasswordRequired,
      'long' => l10n.authPasswordTooLong,
      _ => l10n.authPasswordTooShort,
    };
  }

  InputDecoration _decoration(
    AppColors colors, {
    String? errorText,
    String? helper,
    Color? helperColor,
    Widget? helperIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: colors.surface,
      errorText: errorText,
      helper: helper == null
          ? null
          : Row(
              children: <Widget>[
                if (helperIcon != null) ...<Widget>[
                  helperIcon,
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    helper,
                    style: TextStyle(color: helperColor, fontSize: 13),
                  ),
                ),
              ],
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      suffixIcon: suffix,
      enabledBorder: _border(colors.line),
      focusedBorder: _border(colors.brand, width: 1.6),
      disabledBorder: _border(colors.line),
      errorBorder: _border(colors.danger),
      focusedErrorBorder: _border(colors.danger, width: 1.6),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: colors.fg, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
