import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../repositories/auth_repository.dart';
import '../../routes/app_router.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String identifier;
  final String resetToken;

  const CreatePasswordScreen({
    super.key,
    required this.identifier,
    required this.resetToken,
  });

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassCtrl  = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _repo         = AuthRepository();

  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;
  String? _error;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _error = null; });

    final result = await _repo.resetPassword(
      resetToken:      widget.resetToken,
      password:        _newPassCtrl.text.trim(),
      confirmPassword: _confirmCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password created successfully! Please log in.'),
          backgroundColor: AppColors.secondary,
        ),
      );
      // Clear all auth routes, go to login
      context.go(AppRoutes.login);
    } else {
      setState(() => _error = result.error ?? 'Failed to reset password. Please try again.');
    }
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value != _newPassCtrl.text) return AppStrings.passwordMismatch;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create New Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Icon
              Container(
                width: 72, height: 72,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset_rounded, color: AppColors.secondary, size: 36),
              ),

              const Text(
                'Create New Password',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your new password must be different from your previous password.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),

              // Error banner
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New Password
                    const _FieldLabel(label: 'New Password'),
                    TextFormField(
                      controller:       _newPassCtrl,
                      obscureText:      _obscureNew,
                      textInputAction:  TextInputAction.next,
                      validator:        _validateNewPassword,
                      decoration: InputDecoration(
                        hintText:    AppStrings.enterNewPassword,
                        prefixIcon:  const Icon(Icons.lock_outline),
                        suffixIcon:  IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    const _FieldLabel(label: 'Confirm Password'),
                    TextFormField(
                      controller:       _confirmCtrl,
                      obscureText:      _obscureConfirm,
                      textInputAction:  TextInputAction.done,
                      validator:        _validateConfirm,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText:    AppStrings.confirmPassword,
                        prefixIcon:  const Icon(Icons.lock_outline),
                        suffixIcon:  IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Set New Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }
}
