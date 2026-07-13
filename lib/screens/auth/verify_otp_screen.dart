import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/verify_otp/verify_otp_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/error_banner.dart';
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

  int _countdown = AppConstants.otpExpirySeconds;
  Timer? _timer;

  static const _ctaGradient = LinearGradient(
    colors: [AppColors.green, Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
    for (final f in _focusNodes) {
      f.addListener(() => setState(() {}));
    }
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

  void _verifyOtp() {
    if (!_isOtpComplete || _isExpired) return;
    context.read<VerifyOtpBloc>().add(
        OtpSubmitted(identifier: widget.identifier, otp: _otpValue));
  }

  void _resendOtp() {
    context.read<VerifyOtpBloc>().add(OtpResendRequested(widget.identifier));
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
      listener: (context, state) {
        if (state.verifiedResetToken != null) {
          context.push(AppRoutes.createPassword, extra: {
            'identifier': widget.identifier,
            'reset_token': state.verifiedResetToken!,
          });
        }
        if (state.verifyError != null) {
          // Clear all boxes on wrong OTP
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
        }
        if (state.resendSucceeded) {
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
          _startCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.otpResentSuccess),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      },
      builder: (context, state) {
        final error = state.verifyError ?? state.resendError;
        return Scaffold(
          backgroundColor: AppColors.appbg,
          body: Column(
            children: [
              _Header(identifier: widget.identifier, onBack: () => context.pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppResponsive.padding(context, 24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.otpEnterCaption,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(context, color: AppColors.textSecondary),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 24)),

                      if (error != null) ...[
                        ErrorBanner(error),
                        SizedBox(height: AppResponsive.spacing(context, 20)),
                      ],

                      // OTP Boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) => _OtpBox(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          onChanged: (v) => _onDigitChanged(i, v),
                          hasError: error != null,
                        )),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 24)),

                      // Countdown pill
                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppResponsive.padding(context, 16),
                              vertical: AppResponsive.padding(context, 8)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _isExpired
                              ? Text(AppStrings.otpExpiredShort,
                                  style: TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w700,
                                      fontSize: AppResponsive.text(context, 13)))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_outlined,
                                        size: AppResponsive.scale(context, 16),
                                        color: AppColors.textSecondary),
                                    SizedBox(width: AppResponsive.spacing(context, 6)),
                                    Text(AppStrings.otpExpiresInPrefix,
                                        style: TextStyle(
                                            fontSize: AppResponsive.text(context, 13),
                                            color: AppColors.textSecondary)),
                                    Text(
                                      '00:${_countdown.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: AppResponsive.text(context, 13),
                                        fontWeight: FontWeight.w800,
                                        color: _countdown <= 10
                                            ? AppColors.danger
                                            : AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 28)),

                      // Verify OTP
                      SizedBox(
                        width: double.infinity,
                        height: AppResponsive.scale(context, 54),
                        child: ElevatedButton(
                          onPressed: (state.isVerifying || _isExpired || !_isOtpComplete)
                              ? null
                              : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            disabledBackgroundColor: Colors.transparent,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: (_isExpired || !_isOtpComplete)
                                  ? null
                                  : _ctaGradient,
                              color: (_isExpired || !_isOtpComplete)
                                  ? AppColors.border
                                  : null,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: (_isExpired || !_isOtpComplete)
                                  ? null
                                  : [
                                      BoxShadow(
                                          color: AppColors.green.withValues(alpha: 0.35),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6)),
                                    ],
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: state.isVerifying
                                  ? SizedBox(
                                      width: AppResponsive.scale(context, 22),
                                      height: AppResponsive.scale(context, 22),
                                      child: const CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                  : Text(AppStrings.verifyOtp,
                                      style: AppTextStyles.button(context,
                                          color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 20)),

                      // Resend OTP
                      Center(
                        child: state.isResending
                            ? SizedBox(
                                width: AppResponsive.scale(context, 20),
                                height: AppResponsive.scale(context, 20),
                                child: const CircularProgressIndicator(strokeWidth: 2))
                            : GestureDetector(
                                onTap: _countdown == 0 ? _resendOtp : null,
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                        fontSize: AppResponsive.text(context, 13),
                                        color: AppColors.textSecondary),
                                    children: [
                                      const TextSpan(text: AppStrings.otpDidntReceive),
                                      TextSpan(
                                        text: _countdown == 0
                                            ? AppStrings.resendOtp
                                            : '${AppStrings.resendOtp} (00:${_countdown.toString().padLeft(2, '0')})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: _countdown == 0
                                              ? AppColors.green
                                              : AppColors.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Header: wave-bottomed navy panel with icon + copy + identifier pill ───
class _Header extends StatelessWidget {
  final String identifier;
  final VoidCallback onBack;
  const _Header({required this.identifier, required this.onBack});

  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: _WaveClipper(),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          padding: EdgeInsets.fromLTRB(
            AppResponsive.padding(context, 24),
            0,
            AppResponsive.padding(context, 24),
            AppResponsive.padding(context, 48),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppResponsive.spacing(context, 12)),
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: AppResponsive.scale(context, 40),
                    height: AppResponsive.scale(context, 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                  ),
                ),
                SizedBox(height: AppResponsive.spacing(context, 20)),
                Center(
                  child: Container(
                    width: AppResponsive.scale(context, 72),
                    height: AppResponsive.scale(context, 72),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.sms_outlined,
                        color: AppColors.amber, size: AppResponsive.scale(context, 34)),
                  ),
                ),
                SizedBox(height: AppResponsive.spacing(context, 20)),
                Text(AppStrings.verifyOtp,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading1(context, color: Colors.white)),
                SizedBox(height: AppResponsive.spacing(context, 8)),
                Text(
                  AppStrings.otpSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context,
                      color: Colors.white.withValues(alpha: 0.65)),
                ),
                SizedBox(height: AppResponsive.spacing(context, 16)),
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppResponsive.padding(context, 16),
                        vertical: AppResponsive.padding(context, 8)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(identifier,
                        style: TextStyle(
                            fontSize: AppResponsive.text(context, 15),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF6FE39A))),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─── Gentle wave clip for the header's bottom edge ──────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 32);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height - 16);
    path.quadraticBezierTo(
        size.width * 0.75, size.height - 32, size.width, size.height - 6);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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
    final filled = controller.text.isNotEmpty;
    final borderColor = hasError
        ? AppColors.danger
        : (filled || focusNode.hasFocus)
            ? AppColors.green
            : AppColors.border;
    return SizedBox(
      width: AppResponsive.scale(context, 46),
      height: AppResponsive.scale(context, 56),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: AppResponsive.text(context, 22),
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: hasError ? AppColors.redLight : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: filled ? 2 : 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: filled ? 2 : 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : AppColors.green,
              width: 2,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
