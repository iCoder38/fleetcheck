import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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
  // ─── Image Picker ──────────────────────────────────────────
  final _picker = ImagePicker();
  File? _pickedImage;

  /// Request camera or gallery permission and return true if granted.
  Future<bool> _requestPermission(ImageSource source) async {
    Permission permission;

    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
     return true;
    }


    final status = await permission.request();

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied && mounted) {
      // Show dialog directing user to app settings
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Permission Required'),
          content: Text(
            source == ImageSource.camera
                ? 'Camera permission is required to take a photo. Please enable it in App Settings.'
                : 'Storage/Photos permission is required to choose an image. Please enable it in App Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
    return false;
  }

  /// Show bottom sheet to choose Camera or Gallery
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.appbg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Update Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.green),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Use your camera', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.green),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pick an existing photo', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick image from camera or gallery after requesting permission
  Future<void> _pickImage(ImageSource source) async {
    final granted = await _requestPermission(source);
    if (!granted) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _pickedImage = File(picked.path));

      // Dispatch upload event to BLoC
      if (mounted) {
        context.read<DriverProfileBloc>().add(
          ProfilePhotoUpdateRequested(photoFile: File(picked.path)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // ─── Edit Profile ──────────────────────────────────────────
  void _showEditProfile(DriverModel? driver) {
    final phoneCtrl = TextEditingController(text: driver?.phone ?? '');
    final bloc = context.read<DriverProfileBloc>();

    showModalBottomSheet(
      backgroundColor: AppColors.appbg,
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
              padding: EdgeInsets.fromLTRB(
                24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.editProfile,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppStrings.editProfileSubtitle,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  if (state.updateError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.updateError!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Phone — editable
                  _FormField(
                    label: AppStrings.labelPhoneNumber,
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    textColor: AppColors.background,
                  ),
                  const SizedBox(height: 14),
                  // Email — read only, shown for reference only
                  _FormField(
                    label: AppStrings.labelEmailAddress,
                    controller: TextEditingController(text: driver?.email ?? ''),
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    textColor: AppColors.background,
                    readOnly: true,
                    helperText: 'Email address cannot be changed',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () {
                              bloc.add(ProfileUpdateRequested(
                                phone: phoneCtrl.text.trim(),
                              ));
                            },
                      child: saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              AppStrings.saveChanges,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
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

  // ─── Change Password ───────────────────────────────────────
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
      backgroundColor: AppColors.appbg,
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(AppStrings.passwordChangedSuccess),
                backgroundColor: AppColors.secondary,
              ));
            }
          },
          builder: (ctx, state) => StatefulBuilder(
            builder: (ctx, setBS) {
              final saving = state.isChangingPassword;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        AppStrings.changePassword,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      if (state.passwordError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.passwordError!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _PasswordField(
                        label: AppStrings.currentPassword,
                        controller: currentCtrl,
                        obscure: obscureCurr,
                        onToggle: () => setBS(() => obscureCurr = !obscureCurr),
                        validator: (v) => (v?.isEmpty ?? true) ? AppStrings.fieldRequired : null,
                      ),
                      const SizedBox(height: 12),
                      _PasswordField(
                        label: AppStrings.labelNewPassword,
                        controller: newCtrl,
                        obscure: obscureNew,
                        onToggle: () => setBS(() => obscureNew = !obscureNew),
                        validator: (v) => (v?.length ?? 0) < 6 ? AppStrings.minSixChars : null,
                      ),
                      const SizedBox(height: 12),
                      _PasswordField(
                        label: AppStrings.labelConfirmNewPassword,
                        controller: confirmCtrl,
                        obscure: obscureConf,
                        onToggle: () => setBS(() => obscureConf = !obscureConf),
                        validator: (v) => v != newCtrl.text ? AppStrings.passwordMismatch : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () {
                                  if (!formKey.currentState!.validate()) return;
                                  bloc.add(PasswordChangeRequested(
                                    currentPassword: currentCtrl.text,
                                    newPassword:     newCtrl.text,
                                    confirmPassword: confirmCtrl.text,
                                  ));
                                },
                          child: saving
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  AppStrings.changePassword,
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
                      // ─── Profile Header ────────────────────────────
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
                              AppResponsive.padding(context, 24),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // ── Avatar with camera button ──────────
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Profile image circle
                                    Container(
                                      width: AppResponsive.scale(context, 84),
                                      height: AppResponsive.scale(context, 84),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: _avatarGradient,
                                      ),
                                      child: ClipOval(
                                        child: _pickedImage != null
                                            // Show locally picked image immediately
                                            ? Image.file(_pickedImage!, fit: BoxFit.cover)
                                            : driver.photoUrl != null
                                                // Show uploaded photo from server
                                                ? Image.network(
                                                    driver.photoUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(
                                                      Icons.person_rounded,
                                                      size: 44,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                // Default avatar icon
                                                : const Icon(
                                                    Icons.person_rounded,
                                                    size: 44,
                                                    color: Colors.white,
                                                  ),
                                      ),
                                    ),

                                    // Upload indicator overlay
                                    if (state.isUploadingPhoto)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black45,
                                          ),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 24, height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Camera icon button — taps to show Camera/Gallery picker
                                    Positioned(
                                      top: -4, right: -4,
                                      child: GestureDetector(
                                        onTap: state.isUploadingPhoto
                                            ? null
                                            : _showImageSourceSheet,
                                        child: Container(
                                          width: AppResponsive.scale(context, 26),
                                          height: AppResponsive.scale(context, 26),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: const [
                                              BoxShadow(blurRadius: 6, color: Colors.black26),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Active/Verified badge
                                    if (driver.status == 'active')
                                      Positioned(
                                        bottom: -6, left: -40, right: -40,
                                        child: Center(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: AppResponsive.padding(context, 10),
                                              vertical: AppResponsive.padding(context, 3),
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3FCB6E),
                                              borderRadius: BorderRadius.circular(99),
                                              border: Border.all(color: AppColors.primary, width: 2),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_rounded, size: 12, color: AppColors.primary),
                                                const SizedBox(width: 2),
                                                Text(
                                                  AppStrings.activeVerified,
                                                  softWrap: false,
                                                  style: TextStyle(
                                                    fontSize: AppResponsive.text(context, 11),
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
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
                                      Text(
                                        driver.fullName,
                                        style: TextStyle(
                                          fontSize: AppResponsive.text(context, 22),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: AppResponsive.spacing(context, 4)),
                                      Text(
                                        AppStrings.empIdLabel(driver.employeeId),
                                        style: TextStyle(
                                          fontSize: AppResponsive.text(context, 14),
                                          color: Colors.white.withOpacity(0.65),
                                        ),
                                      ),
                                      // Photo upload success/error feedback
                                      if (state.photoUploadError != null)
                                        Text(
                                          state.photoUploadError!,
                                          style: const TextStyle(
                                            fontSize: 11, color: Colors.redAccent),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ─── Info Card ─────────────────────────────────
                      Padding(
                        padding: EdgeInsets.all(AppResponsive.padding(context, 20)),
                        child: Column(
                          children: [
                            _InfoCard(rows: [
                              _RowData(AppStrings.labelEmployeeId,    driver.employeeId),
                              _RowData(AppStrings.labelPhoneNumber,   driver.phone),
                              _RowData(AppStrings.labelEmailAddress,  driver.email),
                              _RowData(AppStrings.labelBadgeId,       driver.badgeId),
                              _RowData(AppStrings.labelLicenseNumber, driver.licenseNumber),
                              _RowData(AppStrings.labelLicenseExpiry, driver.licenseExpiry),
                            ]),
                            SizedBox(height: AppResponsive.spacing(context, 20)),

                            // Edit Profile / Change Password buttons
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
                                              color: AppColors.green.withOpacity(0.35),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Text(
                                            AppStrings.editProfile,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: AppResponsive.text(context, 15),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
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
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15)),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          AppStrings.changePassword,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: AppResponsive.text(context, 15),
                                            color: AppColors.green,
                                          ),
                                        ),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                ),
                                icon: const Icon(Icons.help_outline_rounded, size: 18),
                                label: Text(
                                  AppStrings.helpSupport,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: AppResponsive.text(context, 15),
                                  ),
                                ),
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

// ─── Reusable Widgets ──────────────────────────────────────────

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
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.padding(context, 18),
                vertical: AppResponsive.padding(context, 14),
              ),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: TextStyle(
                        fontSize: AppResponsive.text(context, 13),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].value.isEmpty ? '—' : rows[i].value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppResponsive.text(context, 14),
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RowData {
  final String label;
  final String value;
  const _RowData(this.label, this.value);
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Color? textColor;
  final bool? readOnly;
  final String? helperText;

  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.textColor,
    this.readOnly,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly ?? false,
          style: TextStyle(
            color: (readOnly ?? false) ? AppColors.textSecondary : AppColors.primary,
          ),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: readOnly ?? false,
            fillColor: (readOnly ?? false) ? AppColors.border.withOpacity(0.2) : null,
            helperText: helperText,
            helperStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(color: AppColors.primary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              ),
              onPressed: onToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
