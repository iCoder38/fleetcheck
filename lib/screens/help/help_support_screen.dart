import 'package:fleetcheck/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/app_info_service.dart';
import '../../core/theme/app_responsive.dart';

const _brightGreen = Color(0xFF2E9E5B);

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _appVersion = AppConstants.appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final version = await AppInfoService.getAppVersion();
    if (mounted) setState(() => _appVersion = version);
  }

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(
        scheme: 'tel',
        path: AppConstants.supportPhone.replaceAll(RegExp(r'[^\d+]'), ''));
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
      SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appbg,
      body: Column(
        children: [
          _HelpAppBar(onBack: () => context.pop()),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppResponsive.padding(context, 24),
                  vertical: AppResponsive.padding(context, 32)),
              child: Column(
                children: [
                Image.asset(AppAssets.appLogo,scale: 5,),
                  SizedBox(height: AppResponsive.spacing(context, 5)),
                  Text(
                    AppConstants.appTagline,
                    style: TextStyle(
                        fontSize: AppResponsive.text(context, 13),
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 5)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppResponsive.padding(context, 16),
                        vertical: AppResponsive.padding(context, 6)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      AppStrings.versionLabel(_appVersion),
                      style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: AppResponsive.text(context, 12),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 5)),
                  Divider(color: AppColors.border.withValues(alpha: 0.2)),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppStrings.contactUs,
                                      style: TextStyle(
                                          fontSize:
                                              AppResponsive.text(context, 12),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: AppColors.textLight)),
                                  SizedBox(
                                      height:
                                          AppResponsive.spacing(context, 14)),
                                  _ContactCard(
                                      icon: Icons.phone_rounded,
                                      iconColor: AppColors.green,
                                      iconBg: AppColors.greenPale,
                                      label: AppStrings.labelPhoneNumber,
                                      value: AppConstants.supportPhone,
                                      onTap: () => _launchPhone(context)),
                                  SizedBox(
                                      height:
                                          AppResponsive.spacing(context, 12)),
                                  _ContactCard(
                                      icon: Icons.email_rounded,
                                      iconColor: AppColors.primary,
                                      iconBg: const Color(0xFFE7E9F7),
                                      label: AppStrings.labelEmailAddress,
                                      value: AppConstants.supportEmail,
                                      onTap: () => _launchEmail(context)),
                                  SizedBox(
                                      height:
                                          AppResponsive.spacing(context, 12)),
                                  _ContactCard(
                                      icon: Icons.language_rounded,
                                      iconColor: const Color(0xFF1A8FA3),
                                      iconBg: const Color(0xFFDCF3F5),
                                      label: AppStrings.labelWebsite,
                                      value: AppConstants.supportWebsite,
                                      onTap: () => _launchWebsite(context)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(color: AppColors.border.withValues(alpha: 0.2)),
                  SizedBox(height: AppResponsive.spacing(context, 5)),
                  Image(
                    image: AssetImage(AppAssets.appLogo),
                    width: AppResponsive.scale(context, 32),
                    height: AppResponsive.scale(context, 32),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 5)),
                  Text(
                    AppStrings.copyright(DateTime.now().year),
                    style: TextStyle(
                        fontSize: AppResponsive.text(context, 11),
                        color: AppColors.textLight),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 4)),
                  Text(
                    AppStrings.designedForFleetOps,
                    style: TextStyle(
                        fontSize: AppResponsive.text(context, 11),
                        color: AppColors.textLight.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom dark-navy app bar matching the reference design ────────────────
class _HelpAppBar extends StatelessWidget {
  final VoidCallback onBack;
  const _HelpAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              AppResponsive.padding(context, 16),
              AppResponsive.padding(context, 12),
              AppResponsive.padding(context, 16),
              AppResponsive.padding(context, 20)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: AppResponsive.scale(context, 40),
                  height: AppResponsive.scale(context, 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              SizedBox(width: AppResponsive.spacing(context, 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.helpSupport,
                        style: TextStyle(
                            fontSize: AppResponsive.text(context, 21),
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    SizedBox(height: AppResponsive.spacing(context, 3)),
                    Text(AppStrings.helpSupportSubtitle,
                        style: TextStyle(
                            fontSize: AppResponsive.text(context, 13),
                            color: Colors.white.withValues(alpha: 0.65))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label, value;
  final VoidCallback onTap;
  const _ContactCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppResponsive.padding(context, 12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: AppResponsive.scale(context, 36),
            height: AppResponsive.scale(context, 36),
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          SizedBox(width: AppResponsive.spacing(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: TextStyle(
                        fontSize: AppResponsive.text(context, 9),
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.4)),
                SizedBox(height: AppResponsive.spacing(context, 3)),
                Text(value,
                    style: TextStyle(
                        fontSize: AppResponsive.text(context, 12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ],
            ),
          ),
          Icon(Icons.open_in_new_rounded,
              size: 15, color: AppColors.textLight.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }
}
