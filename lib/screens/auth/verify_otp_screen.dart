import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../repositories/auth_repository.dart';
import '../../routes/app_router.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String identifier;
  const VerifyOtpScreen({super.key, required this.identifier});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  // 6 separate controllers for each digit box
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _repo = AuthRepository();

  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;
  int _countdown = AppConstants.otpExpirySeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startCountdown() {
    _countdown = AppConstants.otpExpirySeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _otpValue => _controllers.map((c) => c.text).join();
  bool get _isOtpComplete => _otpValue.length == 6;
  bool get _isExpired => _countdown == 0;

  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      // Move forward
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_isOtpComplete && !_isExpired) _verifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      // Move back on delete
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete) {
      setState(() => _error = 'Please enter all 6 digits.');
      return;
    }
    if (_isExpired) {
      setState(() => _error = AppStrings.otpExpired);
      return;
    }

    setState(() { _isVerifying = true; _error = null; });

    final result = await _repo.verifyOtp(
      identifier: widget.identifier,
      otp: _otpValue,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result.success) {
      context.push(AppRoutes.createPassword, extra: {
        'identifier': widget.identifier,
        'reset_token': result.data ?? '',
      });
    } else {
      setState(() => _error = result.error ?? AppStrings.otpInvalid);
      // Clear all boxes on wrong OTP
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending) return;
    setState(() { _isResending = true; _error = null; });

    final result = await _repo.resendOtp(widget.identifier);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result.success) {
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully.'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } else {
      setState(() => _error = result.error ?? AppStrings.otpMaxAttempts);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
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
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sms_outlined, color: AppColors.primary, size: 34),
              ),

              const Text(
                'Enter Verification Code',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to\n${widget.identifier}',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
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

              // OTP Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _OtpBox(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  onChanged: (v) => _onDigitChanged(i, v),
                  hasError: _error != null,
                )),
              ),
              const SizedBox(height: 24),

              // Countdown
              Center(
                child: _isExpired
                    ? const Text(
                        'OTP has expired.',
                        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
                      )
                    : RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'Expires in '),
                            TextSpan(
                              text: '${_countdown}s',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _countdown <= 10 ? AppColors.danger : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Verify Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isVerifying || _isExpired || !_isOtpComplete) ? null : _verifyOtp,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(AppStrings.verifyOtp, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),

              // Resend OTP
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: (_isExpired || _countdown == 0) ? (_isResending ? null : _resendOtp) : null,
                  child: _isResending
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          AppStrings.resendOtp,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _countdown == 0 ? AppColors.secondary : AppColors.textSecondary,
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

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool hasError;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: hasError
              ? AppColors.danger.withOpacity(0.06)
              : (focusNode.hasFocus ? AppColors.primary.withOpacity(0.05) : AppColors.surface),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : AppColors.primary,
              width: 2,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
