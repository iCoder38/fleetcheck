import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/profile/driver_profile_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_responsive.dart';
import '../../models/driver_model.dart';
import '../../routes/app_router.dart';

const _ctaGradient = LinearGradient(
  colors: [AppColors.green, Color(0xFF43A047)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
const _avatarGradient = LinearGradient(
  colors: [Color(0xFF2E9E5B), Color(0xFF2E7CD6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  // ─── Edit Profile ─────────────────────────────────────
  void _showEditProfile(DriverModel? driver) {
    final phoneCtrl = TextEditingController(text: driver?.phone ?? '');
    final emailCtrl = TextEditingController(text: driver?.email ?? '');
    final bloc = context.read<DriverProfileBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: BlocConsumer<DriverProfileBloc, DriverProfileState>(
          listener: (ctx, state) {
            if (state.profileUpdateSucceeded) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(AppStrings.profileUpdatedSuccess),
                backgroundColor: AppColors.secondary,
              ));
            }
          },
          builder: (ctx, state) {
            final saving = state.isUpdatingProfile;
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24,
                  MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text(AppStrings.editProfile, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  const Text(AppStrings.editProfileSubtitle, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  if (state.updateError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                      child: Text(state.updateError!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _FormField(label: AppStrings.labelPhoneNumber, controller: phoneCtrl, keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined),
                  const SizedBox(height: 14),
                  _FormField(label: AppStrings.labelEmailAddress, controller: emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving ? null : () {
                        bloc.add(ProfileUpdateRequested(
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                        ));
                      },
                      child: saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text(AppStrings.saveChanges, style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Change Password ──────────────────────────────────
  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey     = GlobalKey<FormState>();
    bool obscureCurr  = true;
    bool obscureNew   = true;
    bool obscureConf  = true;
    final bloc = context.read<DriverProfileBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: BlocConsumer<DriverProfileBloc, DriverProfileState>(
          listener: (ctx, state) {
            if (state.passwordChangeSucceeded) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.passwordChangedSuccess), backgroundColor: AppColors.secondary),
              );
            }
          },
          builder: (ctx, state) => StatefulBuilder(builder: (ctx, setBS) {
            final saving = state.isChangingPassword;
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24,
                  MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    const Text(AppStrings.changePassword, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 20),
                    if (state.passwordError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                        child: Text(state.passwordError!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _PasswordField(label: AppStrings.currentPassword, controller: currentCtrl, obscure: obscureCurr, onToggle: () => setBS(() => obscureCurr = !obscureCurr),
                        validator: (v) => (v?.isEmpty ?? true) ? AppStrings.fieldRequired : null),
                    const SizedBox(height: 12),
                    _PasswordField(label: AppStrings.labelNewPassword, controller: newCtrl, obscure: obscureNew, onToggle: () => setBS(() => obscureNew = !obscureNew),
                        validator: (v) => (v?.length ?? 0) < 6 ? AppStrings.minSixChars : null),
                    const SizedBox(height: 12),
                    _PasswordField(label: AppStrings.labelConfirmNewPassword, controller: confirmCtrl, obscure: obscureConf, onToggle: () => setBS(() => obscureConf = !obscureConf),
                        validator: (v) => v != newCtrl.text ? AppStrings.passwordMismatch : null),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: saving ? null : () {
                          if (!formKey.currentState!.validate()) return;
                          bloc.add(PasswordChangeRequested(
                            currentPassword: currentCtrl.text,
                            newPassword:     newCtrl.text,
                            confirmPassword: confirmCtrl.text,
                          ));
                        },
                        child: saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text(AppStrings.changePassword, style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverProfileBloc, DriverProfileState>(
      builder: (context, state) {
        final driver = state.driver;
        return Scaffold(
          backgroundColor: AppColors.appbg,
          body: driver == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // ─── Profile Header ─────────────────────────────
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                AppResponsive.padding(context, 24),
                                AppResponsive.padding(context, 16),
                                AppResponsive.padding(context, 24),
                                AppResponsive.padding(context, 24)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: AppResponsive.scale(context, 84),
                                      height: AppResponsive.scale(context, 84),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: _avatarGradient,
                                      ),
                                      child: driver.photoUrl != null
                                          ? ClipOval(child: Image.network(driver.photoUrl!, fit: BoxFit.cover))
                                          : const Icon(Icons.person_rounded, size: 44, color: Colors.white),
                                    ),
                                    Positioned(
                                      top: -4, right: -4,
                                      child: GestureDetector(
                                        onTap: () => _showEditProfile(driver),
                                        child: Container(
                                          width: AppResponsive.scale(context, 26),
                                          height: AppResponsive.scale(context, 26),
                                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)]),
                                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.primary),
                                        ),
                                      ),
                                    ),
                                    if (driver.status == 'active')
                                      Positioned(
                                        bottom: -6, left: -40, right: -40,
                                        child: Center(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: AppResponsive.padding(context, 10),
                                                vertical: AppResponsive.padding(context, 3)),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3FCB6E),
                                              borderRadius: BorderRadius.circular(99),
                                              border: Border.all(color: AppColors.primary, width: 2),
                                            ),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                              const Icon(Icons.check_rounded, size: 12, color: AppColors.primary),
                                              const SizedBox(width: 2),
                                              Text(AppStrings.activeVerified,
                                                  softWrap: false,
                                                  style: TextStyle(
                                                      fontSize: AppResponsive.text(context, 11),
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.primary)),
                                            ]),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(width: AppResponsive.spacing(context, 18)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(driver.fullName,
                                          style: TextStyle(
                                              fontSize: AppResponsive.text(context, 22),
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white)),
                                      SizedBox(height: AppResponsive.spacing(context, 4)),
                                      Text(AppStrings.empIdLabel(driver.employeeId),
                                          style: TextStyle(
                                              fontSize: AppResponsive.text(context, 14),
                                              color: Colors.white.withValues(alpha: 0.65))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ─── Info Card ───────────────────────────────────
                      Padding(
                        padding: EdgeInsets.all(AppResponsive.padding(context, 20)),
                        child: Column(
                          children: [
                            _InfoCard(rows: [
                              _RowData(AppStrings.labelEmployeeId,   driver.employeeId),
                              _RowData(AppStrings.labelPhoneNumber,  driver.phone),
                              _RowData(AppStrings.labelEmailAddress, driver.email),
                              _RowData(AppStrings.labelBadgeId,      driver.badgeId),
                              _RowData(AppStrings.labelLicenseNumber, driver.licenseNumber),
                              _RowData(AppStrings.labelLicenseExpiry, driver.licenseExpiry),
                            ]),
                            SizedBox(height: AppResponsive.spacing(context, 20)),

                            // Edit Profile / Change Password
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: AppResponsive.scale(context, 54),
                                    child: ElevatedButton(
                                      onPressed: () => _showEditProfile(driver),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: _ctaGradient,
                                          borderRadius: BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                                color: AppColors.green.withValues(alpha: 0.35),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6)),
                                          ],
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Text(AppStrings.editProfile,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: AppResponsive.text(context, 15),
                                                  fontWeight: FontWeight.w800)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: AppResponsive.spacing(context, 12)),
                                Expanded(
                                  child: SizedBox(
                                    height: AppResponsive.scale(context, 54),
                                    child: OutlinedButton(
                                      onPressed: _showChangePassword,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.green,
                                        side: const BorderSide(color: AppColors.green, width: 1.5),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: AppResponsive.padding(context, 4)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(AppStrings.changePassword,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: AppResponsive.text(context, 15),
                                                color: AppColors.green)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppResponsive.spacing(context, 10)),

                            // Help & Support button
                            SizedBox(
                              width: double.infinity,
                              height: AppResponsive.scale(context, 54),
                              child: OutlinedButton.icon(
                                onPressed: () => context.push(AppRoutes.help),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                icon: const Icon(Icons.help_outline_rounded, size: 18),
                                label: Text(AppStrings.helpSupport,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: AppResponsive.text(context, 15))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<_RowData> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: AppResponsive.padding(context, 18),
                  vertical: AppResponsive.padding(context, 14)),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(children: [
                Expanded(
                    child: Text(rows[i].label,
                        style: TextStyle(
                            fontSize: AppResponsive.text(context, 13),
                            color: AppColors.textSecondary))),
                Text(rows[i].value.isEmpty ? '—' : rows[i].value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: AppResponsive.text(context, 14),
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ]),
            ),
        ],
      ),
    );
  }
}

class _RowData { final String label; final String value; const _RowData(this.label, this.value); }

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  const _FormField({required this.label, required this.controller, this.keyboardType, this.prefixIcon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller:   controller,
          keyboardType: keyboardType,
          decoration:   InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({required this.label, required this.controller, required this.obscure, required this.onToggle, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller:  controller,
          obscureText: obscure,
          validator:   validator,
          decoration:  InputDecoration(
            prefixIcon:  const Icon(Icons.lock_outline_rounded),
            suffixIcon:  IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: onToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
