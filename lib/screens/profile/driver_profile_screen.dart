import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/driver_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/inspection_repository.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _authRepo  = AuthRepository();
  final _inspRepo  = InspectionRepository();

  DriverModel? _driver;
  bool _isLoading  = true;

  @override
  void initState() {
    super.initState();
    _loadDriver();
  }

  Future<void> _loadDriver() async {
    // Try cached first for instant display
    final cached = _authRepo.getCachedDriver();
    if (cached != null) setState(() { _driver = cached; _isLoading = false; });
  }

  // ─── Edit Profile ─────────────────────────────────────
  void _showEditProfile() {
    final phoneCtrl = TextEditingController(text: _driver?.phone ?? '');
    final emailCtrl = TextEditingController(text: _driver?.email ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) {
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
              const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 4),
              const Text('You can update your phone number and email address.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              _FormField(label: 'Phone Number', controller: phoneCtrl, keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined),
              const SizedBox(height: 14),
              _FormField(label: 'Email Address', controller: emailCtrl, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    setBS(() => saving = true);
                    final result = await _inspRepo.updateProfile(
                      phone: phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    if (result.success && result.data != null) {
                      setState(() => _driver = result.data);
                    }
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(result.success ? 'Profile updated successfully.' : (result.error ?? 'Update failed.')),
                      backgroundColor: result.success ? AppColors.secondary : AppColors.danger,
                    ));
                  },
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ─── Change Password ──────────────────────────────────
  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey     = GlobalKey<FormState>();
    bool saving       = false;
    bool obscureCurr  = true;
    bool obscureNew   = true;
    bool obscureConf  = true;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) {
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
                if (error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],
                _PasswordField(label: AppStrings.currentPassword, controller: currentCtrl, obscure: obscureCurr, onToggle: () => setBS(() => obscureCurr = !obscureCurr),
                    validator: (v) => (v?.isEmpty ?? true) ? AppStrings.fieldRequired : null),
                const SizedBox(height: 12),
                _PasswordField(label: 'New Password', controller: newCtrl, obscure: obscureNew, onToggle: () => setBS(() => obscureNew = !obscureNew),
                    validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null),
                const SizedBox(height: 12),
                _PasswordField(label: 'Confirm New Password', controller: confirmCtrl, obscure: obscureConf, onToggle: () => setBS(() => obscureConf = !obscureConf),
                    validator: (v) => v != newCtrl.text ? AppStrings.passwordMismatch : null),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (!formKey.currentState!.validate()) return;
                      setBS(() { saving = true; error = null; });
                      final result = await _authRepo.changePassword(
                        currentPassword: currentCtrl.text,
                        newPassword:     newCtrl.text,
                        confirmPassword: confirmCtrl.text,
                      );
                      if (!mounted) return;
                      if (result.success) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password changed successfully.'), backgroundColor: AppColors.secondary),
                        );
                      } else {
                        setBS(() { saving = false; error = result.error ?? 'Failed to change password.'; });
                      }
                    },
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = _driver;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.driverProfile)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : driver == null
              ? const Center(child: Text('Failed to load profile.'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // ─── Profile Header ─────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                        child: Column(
                          children: [
                            // Avatar
                            Stack(
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.greenGradient,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: driver.photoUrl != null
                                      ? ClipOval(child: Image.network(driver.photoUrl!, fit: BoxFit.cover))
                                      : const Icon(Icons.person_rounded, size: 48, color: Colors.white),
                                ),
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: GestureDetector(
                                    onTap: _showEditProfile,
                                    child: Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)]),
                                      child: const Icon(Icons.camera_alt_rounded, size: 15, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(driver.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 4),
                            // Verified badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF4CAF50)),
                                const SizedBox(width: 4),
                                Text(
                                  driver.status == 'active' ? 'Active · Verified' : 'Inactive',
                                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),

                      // ─── Info Cards ──────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _InfoSection(
                              title: 'Personal Information',
                              icon: Icons.person_outline_rounded,
                              rows: [
                                _RowData('Employee ID',     driver.employeeId),
                                _RowData('Badge ID',        driver.badgeId),
                                _RowData('Phone Number',    driver.phone),
                                _RowData('Email Address',   driver.email),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _InfoSection(
                              title: 'License Information',
                              icon: Icons.card_membership_rounded,
                              rows: [
                                _RowData('License Number',  driver.licenseNumber),
                                _RowData('License Expiry',  driver.licenseExpiry),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Edit Profile button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _showEditProfile,
                                icon:  const Icon(Icons.edit_rounded, size: 18),
                                label: const Text(AppStrings.editProfile, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Change Password button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: _showChangePassword,
                                icon:  const Icon(Icons.lock_outline_rounded, size: 18),
                                label: const Text(AppStrings.changePassword, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_RowData> rows;

  const _InfoSection({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.04),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(children: [
              Icon(icon, color: AppColors.primary, size: 17),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
            ]),
          ),
          ...rows.map((r) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: rows.last == r ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
            child: Row(children: [
              Expanded(flex: 2, child: Text(r.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              Expanded(flex: 3, child: Text(r.value.isEmpty ? '—' : r.value, textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
            ]),
          )),
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
