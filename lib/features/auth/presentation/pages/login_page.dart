import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../auth_notifier.dart';

/// Minimalist login / signup page for ClipQ v2.
///
/// Implements a flat near-black vertically centered layout with NO card wrapper.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

enum _AuthMode { signIn, signUp, magicLink }

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final notifier = ref.read(authNotifierProvider.notifier);
    String? error;

    switch (_mode) {
      case _AuthMode.signIn:
        error = await notifier.signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      case _AuthMode.signUp:
        error = await notifier.signUpWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (error == null) {
          setState(() =>
              _successMessage = 'Account created! Check your email to confirm.');
        }
      case _AuthMode.magicLink:
        error = await notifier.sendMagicLink(_emailController.text.trim());
        if (error == null) {
          setState(() => _successMessage = 'Magic link sent! Check your inbox.');
        }
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _errorMessage = error;
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildModeTabs(),
                    const SizedBox(height: 32),
                    _buildFields(),
                    if (_errorMessage != null || _successMessage != null) ...[
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        _buildBanner(_errorMessage!, isError: true),
                      if (_successMessage != null)
                        _buildBanner(_successMessage!, isError: false),
                    ],
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 24),
                    _buildToggleMagicLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'ClipQ',
          style: AppTheme.headingPage.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Cross-device clipboard sync.',
          style: AppTheme.uiBody.copyWith(
            color: AppTheme.textMuted,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ── Mode Tabs ───────────────────────────────────────────────────────────────

  Widget _buildModeTabs() {
    if (_mode == _AuthMode.magicLink) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Magic Link',
            style: AppTheme.uiLabel.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 16,
            height: 2,
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        _buildTab('Sign In', _AuthMode.signIn),
        const SizedBox(width: 24),
        _buildTab('Create Account', _AuthMode.signUp),
      ],
    );
  }

  Widget _buildTab(String label, _AuthMode mode) {
    final isActive = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _mode = mode;
        _errorMessage = null;
        _successMessage = null;
      }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.uiLabel.copyWith(
              color: isActive ? AppTheme.textPrimary : AppTheme.textMuted,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: AppConstants.animQuick,
            curve: Curves.easeOut,
            width: isActive ? 16 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fields ──────────────────────────────────────────────────────────────────

  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          style: AppTheme.uiBody.copyWith(color: AppTheme.textPrimary),
          cursorColor: AppTheme.accent,
          decoration: const InputDecoration(
            labelText: 'Email',
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        if (_mode != _AuthMode.magicLink) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: _mode == _AuthMode.signIn
                ? const [AutofillHints.password]
                : const [AutofillHints.newPassword],
            style: AppTheme.uiBody.copyWith(color: AppTheme.textPrimary),
            cursorColor: AppTheme.accent,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textMuted,
                  size: 16,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Password is required';
              }
              if (_mode == _AuthMode.signUp && v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  // ── Submit button ───────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    final labels = {
      _AuthMode.signIn: 'Sign In',
      _AuthMode.signUp: 'Create Account',
      _AuthMode.magicLink: 'Send Magic Link',
    };

    return SizedBox(
      height: 40,
      width: double.infinity,
      child: TextButton(
        onPressed: _loading ? null : _submit,
        style: TextButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        child: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                labels[_mode]!,
                style: AppTheme.uiStrong.copyWith(color: Colors.white, fontSize: 13),
              ),
      ),
    );
  }

  // ── Toggle Magic Link ───────────────────────────────────────────────────────

  Widget _buildToggleMagicLink() {
    return Center(
      child: InkWell(
        onTap: () => setState(() {
          _mode = _mode == _AuthMode.magicLink
              ? _AuthMode.signIn
              : _AuthMode.magicLink;
          _errorMessage = null;
          _successMessage = null;
        }),
        child: Text(
          _mode == _AuthMode.magicLink
              ? 'Use password instead'
              : 'Use Magic Link instead',
          style: AppTheme.uiLabel.copyWith(
            color: AppTheme.textMuted,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  // ── Banner ──────────────────────────────────────────────────────────────────

  Widget _buildBanner(String message, {required bool isError}) {
    final color = isError ? AppTheme.error : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTheme.uiBody.copyWith(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
