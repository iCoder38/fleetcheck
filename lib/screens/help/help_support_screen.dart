import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: AppConstants.supportPhone.replaceAll(RegExp(r'[^\d+]'), ''));
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showError(context, AppStrings.dialerFailed);
      }
    } catch (_) {
      _showError(context, AppStrings.dialerFailed);
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: AppConstants.supportEmail);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showError(context, AppStrings.emailFailed);
      }
    } catch (_) {
      _showError(context, AppStrings.emailFailed);
    }
  }

  Future<void> _launchWebsite(BuildContext context) async {
    final uri = Uri.parse(AppConstants.supportWebsite);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError(context, AppStrings.browserFailed);
      }
    } catch (_) {
      _showError(context, AppStrings.browserFailed);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.helpSupport)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Logo header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Column(
                children: [
                  Container(
                    width: 86, height: 86,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 44),
                  ),
                  const SizedBox(height: 16),
                  RichText(text: const TextSpan(children: [
                    TextSpan(text: 'Fleet', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, color: Colors.white)),
                    TextSpan(text: 'Check', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, color: AppColors.accent)),
                  ])),
                  const SizedBox(height: 6),
                  const Text(
                    AppConstants.appTagline,
                    style: TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
                    child: const Text('Version ${AppConstants.appVersion}', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact Us', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Reach out through any of the options below.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),

                  _ContactCard(icon: Icons.phone_rounded, iconColor: AppColors.secondary, label: 'Phone Number',
                      value: AppConstants.supportPhone, onTap: () => _launchPhone(context)),
                  const SizedBox(height: 12),
                  _ContactCard(icon: Icons.email_rounded, iconColor: AppColors.primary, label: 'Email Address',
                      value: AppConstants.supportEmail, onTap: () => _launchEmail(context)),
                  const SizedBox(height: 12),
                  _ContactCard(icon: Icons.language_rounded, iconColor: AppColors.amber, label: 'Website',
                      value: AppConstants.supportWebsite, onTap: () => _launchWebsite(context)),

                  const SizedBox(height: 36),
                  Center(
                    child: Text(
                      '© ${DateTime.now().year} FleetCheck. All rights reserved.',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;
  final VoidCallback onTap;
  const _ContactCard({required this.icon, required this.iconColor, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(width: 46, height: 46,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: iconColor)),
          ])),
          Icon(Icons.open_in_new_rounded, size: 15, color: AppColors.textSecondary.withOpacity(0.5)),
        ]),
      ),
    );
  }
}
