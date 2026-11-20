import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_widgets.dart';
import 'main_menu_screen.dart';

/// How the user chose to enter the demo.
enum _SignInMethod { email, google, apple, guest }

/// Demo sign-in UI for the app shell.
///
/// Credentials and SSO buttons are **not** verified against a backend. They
/// only gate entry into the demo experience so flows can be exercised
/// end-to-end. Prefer "Continue as guest" when no form fill is needed.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  /// Minimum password length accepted by the demo form.
  static const minPasswordLength = 6;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _continue({required _SignInMethod method}) async {
    if (_busy) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final isGuest = method == _SignInMethod.guest;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isGuest ? l10n.guestSnack : l10n.demoSignInSnack),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainMenuScreen()),
    );
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _continue(method: _SignInMethod.email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.colors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_football,
                    color: AppColors.orange,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.appTitle,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.loginTagline,
                style: TextStyle(color: context.colors.muted, fontSize: 15),
              ),
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: StatCard(
                  key: const Key('demo_auth_banner'),
                  color: context.colors.gold.withValues(alpha: 0.16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: context.colors.gold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.loginDemoBanner,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.colors.text,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              StatCard(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: l10n.emailLabel,
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return l10n.emailRequired;
                          if (!text.contains('@') || !text.contains('.')) {
                            return l10n.emailInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        // Keep passwords out of keyboard suggestions and
                        // autocorrect dictionaries.
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: l10n.passwordLabel,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? l10n.showPassword
                                : l10n.hidePassword,
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final text = value ?? '';
                          const min = LoginScreen.minPasswordLength;
                          if (text.length < min) {
                            return l10n.passwordTooShort(min);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _busy ? null : _submitEmail,
                        child: _busy
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.colors.onInk,
                                ),
                              )
                            : Text(l10n.signInDemo),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.orContinueWith,
                      style: TextStyle(color: context.colors.muted),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              _SsoButton(
                icon: Icons.g_mobiledata,
                label: l10n.continueWithGoogle,
                onPressed: _busy
                    ? null
                    : () => _continue(method: _SignInMethod.google),
              ),
              const SizedBox(height: 10),
              _SsoButton(
                icon: Icons.apple,
                label: l10n.continueWithApple,
                onPressed: _busy
                    ? null
                    : () => _continue(method: _SignInMethod.apple),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _continue(method: _SignInMethod.guest),
                child: Text(l10n.continueAsGuest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SsoButton extends StatelessWidget {
  const _SsoButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }
}
