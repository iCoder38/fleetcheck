import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/login/login_bloc.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../routes/app_router.dart';
import '../../core/theme/app_responsive.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/error_banner.dart';

// Bright accent green used for this screen's branding (matches the
// FleetCheck logo/wordmark), independent of the app's amber CTA color.
const _brightGreen = Color(0xFF4CAF50);

// Shared pill radius/shadow so input fields and buttons stay visually
// consistent with each other.
const _pillRadius = 15.0;
final _pillShadow = [
  BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 3)),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  static const _loginGradient = LinearGradient(
    colors: [AppColors.green, Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    context.read<LoginBloc>().add(LoginSubmitted(
          identifier: _identifierCtrl.text.trim(),
          password: _passwordCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) context.go(AppRoutes.dashboard);
      },
      builder: (context, state) {
        final isLoading = state is LoginLoading;
        final errorMessage = state is LoginFailure ? state.message : null;
        return Scaffold(
          backgroundColor: AppColors.appbg,
          body: Column(
            children: [
              _Header(),
              Expanded(
                child: SingleChildScrollView(
                  padding: AppResponsive.horizontal(context, value: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppResponsive.spacing(context, 24)),

                        // Error
                        if (errorMessage != null) ...[
                          ErrorBanner(errorMessage),
                          SizedBox(height: AppResponsive.spacing(context, 16)),
                        ],

                        // Employee ID
                        _UpperLabel(AppStrings.labelIdentifier.toUpperCase()),
                        SizedBox(height: AppResponsive.spacing(context, 8)),
                        _PillField(
                          controller: _identifierCtrl,
                          textInputAction: TextInputAction.next,
                          hintText: AppStrings.hintIdentifier,
                          prefixIcon: Icons.person_rounded,
                          prefixIconColor: const Color(0xFF4A90D9),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? AppStrings.fieldRequired
                              : null,
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 18)),

                        // Password
                        _UpperLabel(AppStrings.labelPassword.toUpperCase()),
                        SizedBox(height: AppResponsive.spacing(context, 8)),
                        _PillField(
                          controller: _passwordCtrl,
                          textInputAction: TextInputAction.done,
                          hintText: AppStrings.hintPassword,
                          prefixIcon: Icons.lock_rounded,
                          prefixIconColor: AppColors.amber,
                          obscureText: _obscurePassword,
                          onSubmitted: (_) => _login(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? AppStrings.fieldRequired
                              : null,
                        ),

                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                context.push(AppRoutes.forgotPassword),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.green,
                              padding: EdgeInsets.symmetric(
                                  vertical: AppResponsive.padding(context, 8)),
                            ),
                            child: Text(AppStrings.forgotPassword,
                                style: AppTextStyles.label(context,
                                    color: AppColors.green)),
                          ),
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 8)),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: AppResponsive.scale(context, 54),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: _loginGradient,
                                borderRadius:
                                    BorderRadius.circular(_pillRadius),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.green
                                          .withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6)),
                                ],
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: isLoading
                                    ? SizedBox(
                                        width: AppResponsive.scale(context, 22),
                                        height:
                                            AppResponsive.scale(context, 22),
                                        child: const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5))
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 20),
                                          SizedBox(
                                              width: AppResponsive.spacing(
                                                  context, 8)),
                                          Text(AppStrings.login,
                                              style: AppTextStyles.button(
                                                  context,
                                                  color: Colors.white)),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 14)),

                        // Contact Support
                        // Container(
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(_pillRadius),
                        //     boxShadow: _pillShadow,
                        //   ),
                        //   child: SizedBox(
                        //     width: double.infinity,
                        //     height: AppResponsive.scale(context, 52),
                        //     child: OutlinedButton.icon(
                        //       onPressed: () => context.push(AppRoutes.help),
                        //       style: OutlinedButton.styleFrom(
                        //         backgroundColor: Colors.white,
                        //         side: const BorderSide(color: AppColors.border),
                        //         shape: RoundedRectangleBorder(
                        //             borderRadius:
                        //                 BorderRadius.circular(_pillRadius)),
                        //       ),
                        //       icon: Icon(Icons.chat_bubble_outline_rounded,
                        //           size: AppResponsive.scale(context, 18),
                        //           color: AppColors.textPrimary),
                        //       label: RichText(
                        //         text: TextSpan(
                        //           style: AppTextStyles.label(context,
                        //               color: AppColors.textSecondary),
                        //           children: [
                        //             const TextSpan(
                        //                 text: AppStrings.needHelpPrefix),
                        //             TextSpan(
                        //                 text: AppStrings.contactSupport,
                        //                 style: AppTextStyles.label(context,
                        //                         color: AppColors.green)
                        //                     .copyWith(
                        //                         fontWeight: FontWeight.w700)),
                        //           ],
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        // SizedBox(height: AppResponsive.spacing(context, 20)),
                        Center(
                          child: Text(
                            AppStrings.copyright(DateTime.now().year),
                            style: AppTextStyles.bodySmall(context,
                                color: AppColors.textLight),
                          ),
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 20)),
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

// ─── Header: logo + wordmark + welcome copy, wave-bottomed navy panel ──────
class _Header extends StatelessWidget {
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
                SizedBox(height: AppResponsive.spacing(context, 20)),
                Image.asset(AppAssets.appLogoWhite,scale: 5,),
                SizedBox(height: AppResponsive.spacing(context, 20)),
                Text(AppStrings.welcomeBackTitle,
                    style:
                        AppTextStyles.heading1(context, color: Colors.white)),
                SizedBox(height: AppResponsive.spacing(context, 4)),
                Text(AppStrings.pleaseLoginToContinue,
                    style: AppTextStyles.body(context,
                        color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ),
      );
}

// ─── Logo mark: QR-in-frame icon with a check badge ─────────────────────────

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
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _PillField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.prefixIconColor,
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
            prefixIcon: Icon(prefixIcon, color: prefixIconColor),
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(
                horizontal: AppResponsive.padding(context, 16),
                vertical: AppResponsive.padding(context, 16)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_pillRadius),
              borderSide:
                  const BorderSide(color: AppColors.greenPale, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_pillRadius),
              borderSide:
                  const BorderSide(color: AppColors.greenPale, width: 1),
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
