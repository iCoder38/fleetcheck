import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/forgot_password/forgot_password_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/error_banner.dart';
import '../../routes/app_router.dart';

const _pillRadius = 15.0;
final _pillShadow = [
  BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 3)),
];

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierCtrl = TextEditingController();
  String? _localError;

  static const _ctaGradient = LinearGradient(
    colors: [AppColors.green, Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void dispose() {
    _identifierCtrl.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final id = _identifierCtrl.text.trim();
    if (id.isEmpty) {
      setState(() => _localError = AppStrings.fieldRequired);
      return;
    }
    setState(() => _localError = null);
    context.read<ForgotPasswordBloc>().add(ForgotPasswordSubmitted(id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordSuccess) {
          context.push(AppRoutes.verifyOtp, extra: state.identifier);
        }
      },
      builder: (context, state) {
        final isLoading = state is ForgotPasswordLoading;
        final error = _localError ??
            (state is ForgotPasswordFailure ? state.message : null);
        return Scaffold(
          backgroundColor: AppColors.appbg,
          body: Column(
            children: [
              _Header(onBack: () => context.pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppResponsive.padding(context, 24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Warning banner
                      Container(
                        padding: EdgeInsets.all(AppResponsive.padding(context, 14)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF0D5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF0C674)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFB8860B), size: 20),
                            SizedBox(width: AppResponsive.spacing(context, 10)),
                            Expanded(
                              child: Text(
                                AppStrings.forgotPasswordWarning,
                                style: TextStyle(
                                    fontSize: AppResponsive.text(context, 13),
                                    color: const Color(0xFF8A6116),
                                    height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 24)),

                      if (error != null) ...[
                        ErrorBanner(error),
                        SizedBox(height: AppResponsive.spacing(context, 16)),
                      ],

                      _UpperLabel(AppStrings.labelIdentifierFull.toUpperCase()),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      _PillField(
                        controller: _identifierCtrl,
                        hintText: AppStrings.hintIdentifierForgot,
                        prefixIcon: Icons.person_outline_rounded,
                        prefixIconColor: const Color(0xFF4A90D9),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _sendOtp(),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 28)),

                      // Send OTP
                      SizedBox(
                        width: double.infinity,
                        height: AppResponsive.scale(context, 54),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: _ctaGradient,
                              borderRadius: BorderRadius.circular(_pillRadius),
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.green.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6)),
                              ],
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: isLoading
                                  ? SizedBox(
                                      width: AppResponsive.scale(context, 22),
                                      height: AppResponsive.scale(context, 22),
                                      child: const CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.mail_outline_rounded,
                                            color: Colors.white, size: 20),
                                        SizedBox(width: AppResponsive.spacing(context, 8)),
                                        Text(AppStrings.sendOtp,
                                            style: AppTextStyles.button(context,
                                                color: Colors.white)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 18)),

                      Center(
                        child: TextButton(
                          onPressed: () => context.pop(),
                          child: Text(AppStrings.backToLogin,
                              style: TextStyle(
                                  fontSize: AppResponsive.text(context, 13),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textLight)),
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

// ─── Header: wave-bottomed navy panel with back button + icon + copy ───────
class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

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
                    child: Icon(Icons.lock_reset_rounded,
                        color: AppColors.amber, size: AppResponsive.scale(context, 36)),
                  ),
                ),
                SizedBox(height: AppResponsive.spacing(context, 20)),
                Text(AppStrings.forgotPassword,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading1(context, color: Colors.white)),
                SizedBox(height: AppResponsive.spacing(context, 8)),
                Text(
                  AppStrings.forgotPasswordDescription,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(context,
                      color: Colors.white.withValues(alpha: 0.65)),
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

// ─── Uppercase caption label above a field ──────────────────────────────────
class _UpperLabel extends StatelessWidget {
  final String label;
  const _UpperLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          fontSize: AppResponsive.text(context, 11),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      );
}

// ─── Fully-rounded white pill input field ───────────────────────────────────
class _PillField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Color prefixIconColor;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _PillField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.prefixIconColor,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_pillRadius),
          boxShadow: _pillShadow,
        ),
        child: TextFormField(
          controller: controller,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: AppTextStyles.body(context, color: AppColors.primary),
          decoration: InputDecoration(
            filled: false,
            hintText: hintText,
            hintStyle: AppTextStyles.body(context, color: AppColors.textLight),
            prefixIcon: Icon(prefixIcon, color: prefixIconColor),
            contentPadding: EdgeInsets.symmetric(
                horizontal: AppResponsive.padding(context, 16),
                vertical: AppResponsive.padding(context, 16)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_pillRadius),
              borderSide: const BorderSide(color: AppColors.greenPale, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_pillRadius),
              borderSide: const BorderSide(color: AppColors.greenPale, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_pillRadius),
              borderSide: const BorderSide(color: AppColors.green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_pillRadius),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
        ),
      );
}
