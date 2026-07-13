import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/create_password/create_password_bloc.dart';
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
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  static const _ctaGradient = LinearGradient(
    colors: [AppColors.green, Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CreatePasswordBloc>().add(ResetPasswordSubmitted(
          resetToken: widget.resetToken,
          password: _newPassCtrl.text.trim(),
          confirmPassword: _confirmCtrl.text.trim(),
        ));
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value.length < 6) return AppStrings.passwordMinLength;
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value != _newPassCtrl.text) return AppStrings.passwordMismatch;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreatePasswordBloc, CreatePasswordState>(
      listener: (context, state) {
        if (state is CreatePasswordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.passwordCreatedSuccess),
              backgroundColor: AppColors.secondary,
            ),
          );
          context.go(AppRoutes.login);
        }
      },
      builder: (context, state) {
        final isLoading = state is CreatePasswordLoading;
        final error = state is CreatePasswordFailure ? state.message : null;
        return Scaffold(
          backgroundColor: AppColors.appbg,
          body: Column(
            children: [
              const _Header(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppResponsive.padding(context, 24)),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info banner
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
                                  AppStrings.changePasswordWarning,
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

                        _UpperLabel(AppStrings.labelNewPassword.toUpperCase()),
                        SizedBox(height: AppResponsive.spacing(context, 8)),
                        _PillField(
                          controller: _newPassCtrl,
                          hintText: AppStrings.enterNewPassword,
                          obscureText: _obscureNew,
                          textInputAction: TextInputAction.next,
                          validator: _validateNewPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textLight, size: 20),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 18)),

                        _UpperLabel(AppStrings.labelConfirmPassword.toUpperCase()),
                        SizedBox(height: AppResponsive.spacing(context, 8)),
                        _PillField(
                          controller: _confirmCtrl,
                          hintText: AppStrings.confirmPassword,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          validator: _validateConfirm,
                          onSubmitted: (_) => _submit(),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textLight, size: 20),
                            onPressed: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 28)),

                        // Set New Password
                        SizedBox(
                          width: double.infinity,
                          height: AppResponsive.scale(context, 54),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submit,
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
                                          const Icon(Icons.check_circle_outline_rounded,
                                              color: Colors.white, size: 20),
                                          SizedBox(width: AppResponsive.spacing(context, 8)),
                                          Text(AppStrings.setNewPassword,
                                              style: AppTextStyles.button(context,
                                                  color: Colors.white)),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

// ─── Header: wave-bottomed navy panel with icon + copy ─────────────────────
class _Header extends StatelessWidget {
  const _Header();

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
                SizedBox(height: AppResponsive.spacing(context, 32)),
                Center(
                  child: Container(
                    width: AppResponsive.scale(context, 72),
                    height: AppResponsive.scale(context, 72),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.lock_person_rounded,
                        color: AppColors.amber, size: AppResponsive.scale(context, 36)),
                  ),
                ),
                SizedBox(height: AppResponsive.spacing(context, 20)),
                Text(AppStrings.createPassword,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading1(context, color: Colors.white)),
                SizedBox(height: AppResponsive.spacing(context, 8)),
                Text(
                  AppStrings.createPasswordSubtitle,
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
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _PillField({
    required this.controller,
    required this.hintText,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
    this.validator,
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
          obscureText: obscureText,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: AppTextStyles.body(context, color: AppColors.primary),
          decoration: InputDecoration(
            filled: false,
            hintText: hintText,
            hintStyle: AppTextStyles.body(context, color: AppColors.textLight),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.amber),
            suffixIcon: suffixIcon,
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
