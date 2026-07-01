import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../repositories/auth_repository.dart';
import '../../routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _repo           = AuthRepository();

  bool    _obscurePassword = true;
  bool    _isLoading       = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await _repo.login(
      identifier: _identifierCtrl.text.trim(),
      password:   _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      context.go(AppRoutes.dashboard);
    } else {
      setState(() => _errorMessage = result.error ?? AppStrings.invalidCreds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width:  double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),

                // ── Logo ──────────────────────────────────────────
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 38),
                ),
                const SizedBox(height: 14),
                RichText(
                  text: const TextSpan(children: [
                    TextSpan(text: 'Fleet',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic, color: Colors.white)),
                    TextSpan(text: 'Check',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic, color: AppColors.greenLight)),
                  ]),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.tagline,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55),
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 36),

                // ── Login Card ────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color:        Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow:    [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24)],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Driver Login',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        const Text('Sign in with your Employee ID or Phone',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 22),

                        // Error
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:  AppColors.redLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!,
                                  style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                            ]),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Employee ID
                        const _FieldLabel('Employee ID / Badge ID / Phone'),
                        TextFormField(
                          controller:      _identifierCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText:   AppStrings.hintIdentifier,
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.fieldRequired : null,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        const _FieldLabel('Password'),
                        TextFormField(
                          controller:      _passwordCtrl,
                          obscureText:     _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            hintText:   AppStrings.hintPassword,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? AppStrings.fieldRequired : null,
                        ),

                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push(AppRoutes.forgotPassword),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(AppStrings.forgotPassword,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text(AppStrings.login,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Contact Support
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(AppRoutes.help),
                            icon:  const Icon(Icons.headset_mic_outlined, size: 18),
                            label: const Text(AppStrings.contactSupport,
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '© ${DateTime.now().year} FleetCheck. All rights reserved.',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
  );
}
