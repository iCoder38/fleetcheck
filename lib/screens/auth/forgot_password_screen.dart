import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../repositories/auth_repository.dart';
import '../../routes/app_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierCtrl = TextEditingController();
  final _repo           = AuthRepository();
  bool   _isLoading     = false;
  String? _error;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final id = _identifierCtrl.text.trim();
    if (id.isEmpty) {
      setState(() => _error = AppStrings.fieldRequired);
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    final result = await _repo.forgotPassword(id);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      context.push(AppRoutes.verifyOtp, extra: id);
    } else {
      setState(() => _error = result.error ?? AppStrings.invalidIdentifier);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 72, height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_open_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 24),

              const Text('Forgot Password?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text(
                'Enter your Employee ID / Badge ID / Phone number and we\'ll send a verification code.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 28),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 16),
              ],

              // Field
              const _Label('Employee ID / Badge ID / Phone Number'),
              TextField(
                controller: _identifierCtrl,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendOtp(),
                decoration: const InputDecoration(
                  hintText: 'Enter your ID or phone number',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 28),

              // Send OTP
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text(AppStrings.sendOtp, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 14),

              // Back to Login
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
  );
}
