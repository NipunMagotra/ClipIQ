import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../auth_notifier.dart';

/// Clean, flat login / signup page for ClipQ.
///
/// Modes:
///  - Sign In (email + password)
///  - Create Account (email + password)
///  - Magic Link (email only)
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
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildForm(),
                ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.content_paste, color: AppTheme.primary, size: 28),
            SizedBox(width: 10),
            Text(
              'ClipQ',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Your clipboard, everywhere.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  // ── Form ────────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border.fromBorderSide(BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode tabs
            if (_mode != _AuthMode.magicLink) _buildModeTabs(),
            if (_mode == _AuthMode.magicLink)
              const Text(
                'Magic Link',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 20),

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined,
                    color: AppTheme.textMuted, size: 18),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),

            // Password field (hidden for magic link)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _mode != _AuthMode.magicLink
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: _mode == _AuthMode.signIn
                            ? const [AutofillHints.password]
                            : const [AutofillHints.newPassword],
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppTheme.textMuted, size: 18),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textMuted,
                              size: 18,
                            ),
                          ),
                        ),
                        validator: _mode != _AuthMode.magicLink
                            ? (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                if (_mode == _AuthMode.signUp && v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              }
                            : null,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // Error / success banners
            if (_errorMessage != null) ...[
              _buildBanner(_errorMessage!, isError: true),
              const SizedBox(height: 14),
            ],
            if (_successMessage != null) ...[
              _buildBanner(_successMessage!, isError: false),
              const SizedBox(height: 14),
            ],

            // Submit button
            _buildSubmitButton(),

            const SizedBox(height: 12),

            // Toggle magic link
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _mode = _mode == _AuthMode.magicLink
                      ? _AuthMode.signIn
                      : _AuthMode.magicLink;
                  _errorMessage = null;
                  _successMessage = null;
                }),
                child: Text(
                  _mode == _AuthMode.magicLink
                      ? 'Use password instead'
                      : 'Sign in with Magic Link',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mode tabs ───────────────────────────────────────────────────────────────

  Widget _buildModeTabs() {
    return Row(
      children: [
        _ModeTab(
          label: 'Sign In',
          isActive: _mode == _AuthMode.signIn,
          onTap: () => setState(() {
            _mode = _AuthMode.signIn;
            _errorMessage = null;
          }),
        ),
        const SizedBox(width: 8),
        _ModeTab(
          label: 'Create Account',
          isActive: _mode == _AuthMode.signUp,
          onTap: () => setState(() {
            _mode = _AuthMode.signUp;
            _errorMessage = null;
          }),
        ),
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
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white70),
                ),
              )
            : Text(
                labels[_mode]!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ── Message banner ──────────────────────────────────────────────────────────

  Widget _buildBanner(String message, {required bool isError}) {
    final color = isError ? AppTheme.error : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mode Tab ─────────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withAlpha(25) : Colors.transparent,
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
