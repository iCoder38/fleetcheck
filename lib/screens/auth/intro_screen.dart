// lib/screens/auth/intro_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../routes/app_router.dart';
import '../../core/theme/app_responsive.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  void _goToPage(int page) {
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  void _skip() => context.go(AppRoutes.login);
  void _getStarted() => context.go(AppRoutes.login);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == 3;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Skip
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppResponsive.padding(context, 20),
                  vertical: AppResponsive.padding(context, 8)),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skip,
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                  child: Text(AppStrings.introSkip,
                      style: TextStyle(
                          fontSize: AppResponsive.text(context, 15),
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),

            // Illustration pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 4,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _IntroIllustration(index: i),
              ),
            ),

            // Dot indicator
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: AppResponsive.spacing(context, 20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    4,
                    (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == i
                                ? AppColors.green
                                : AppColors.border,
                          ),
                        )),
              ),
            ),

            // Bottom card: title, description, nav buttons
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                AppResponsive.padding(context, 28),
                AppResponsive.padding(context, 28),
                AppResponsive.padding(context, 28),
                AppResponsive.padding(context, 24) +
                    MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppResponsive.radius(context, 28))),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, -8)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.introTitles[_currentPage],
                    style: TextStyle(
                      fontSize: AppResponsive.text(context, 25),
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 12)),
                  Text(
                    AppStrings.introDescriptions[_currentPage],
                    style: TextStyle(
                      fontSize: AppResponsive.text(context, 14),
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 26)),
                  Row(
                    mainAxisAlignment: _currentPage > 0
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.end,
                    children: [
                      if (_currentPage > 0)
                        OutlinedButton(
                          onPressed: () => _goToPage(_currentPage - 1),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(
                                color: AppColors.border, width: 1.5),
                            padding: EdgeInsets.symmetric(
                                horizontal: AppResponsive.padding(context, 22),
                                vertical: AppResponsive.padding(context, 15)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('← ${AppStrings.introBack}',
                              style: TextStyle(
                                  fontSize: AppResponsive.text(context, 15),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ElevatedButton(
                        onPressed:
                            isLast ? _getStarted : () => _goToPage(_currentPage + 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                              horizontal: AppResponsive.padding(context, 26),
                              vertical: AppResponsive.padding(context, 15)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                            '${isLast ? AppStrings.introGetStarted : AppStrings.introNext} →',
                            style: TextStyle(
                                fontSize: AppResponsive.text(context, 15),
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
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

// ─── Illustration dispatcher ─────────────────────────────────────────────────

class _IntroIllustration extends StatelessWidget {
  final int index;
  const _IntroIllustration({required this.index});

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return const _WelcomeIllustration();
      case 1:
        return const _InspectIllustration();
      case 2:
        return const _TrackIllustration();
      default:
        return const _ComplianceIllustration();
    }
  }
}

// ─── Page 1: Welcome ──────────────────────────────────────────────────────────

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) {
    final anchor = AppResponsive.scale(context, 300);
    final circle = AppResponsive.scale(context, 240);
    return Center(
      child: SizedBox(
        width: anchor,
        height: anchor,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: circle,
              height: circle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withValues(alpha: 0.10),
              ),
            ),
            Container(
              width: AppResponsive.scale(context, 130),
              height: AppResponsive.scale(context, 130),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.qr_code_2_rounded,
                      size: AppResponsive.scale(context, 56),
                      color: AppColors.green),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.check_circle_rounded,
                          size: AppResponsive.scale(context, 26),
                          color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: AppResponsive.scale(context, 30),
              right: 0,
              child: _Badge(
                icon: Icons.local_shipping_rounded,
                iconColor: AppColors.info,
                bg: AppColors.info.withValues(alpha: 0.12),
                title: 'Fleet',
                titleColor: AppColors.primary,
              ),
            ),
            Positioned(
              top: AppResponsive.scale(context, 115),
              left: 0,
              child: _Badge(
                icon: Icons.assignment_rounded,
                iconColor: AppColors.warning,
                bg: AppColors.warning.withValues(alpha: 0.15),
                title: 'Reports',
                titleColor: AppColors.primary,
              ),
            ),
            Positioned(
              bottom: AppResponsive.scale(context, 30),
              left: AppResponsive.scale(context, 10),
              child: _Badge(
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.green,
                bg: AppColors.green.withValues(alpha: 0.15),
                title: 'Verified',
                titleColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 2: Inspect ──────────────────────────────────────────────────────────

class _InspectIllustration extends StatelessWidget {
  const _InspectIllustration();

  static const _rows = [
    ('Headlights', true),
    ('Brakes', true),
    ('Tires', true),
    ('Mirrors', false),
    ('Engine', false),
  ];

  @override
  Widget build(BuildContext context) {
    final anchor = AppResponsive.scale(context, 300);
    final circle = AppResponsive.scale(context, 240);
    return Center(
      child: SizedBox(
        width: anchor,
        height: anchor,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: circle,
              height: circle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.info.withValues(alpha: 0.10),
              ),
            ),
            Container(
              width: AppResponsive.scale(context, 160),
              padding: EdgeInsets.only(
                  bottom: AppResponsive.padding(context, 12)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        vertical: AppResponsive.padding(context, 10)),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Text('INSPECTION',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: AppResponsive.text(context, 12),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 8)),
                  ..._rows.map((r) => Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppResponsive.padding(context, 14),
                            vertical: AppResponsive.padding(context, 4)),
                        child: Row(
                          children: [
                            Icon(
                              r.$2
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: AppResponsive.scale(context, 16),
                              color: r.$2
                                  ? AppColors.green
                                  : AppColors.border,
                            ),
                            SizedBox(width: AppResponsive.spacing(context, 6)),
                            Text(r.$1,
                                style: TextStyle(
                                    fontSize:
                                        AppResponsive.text(context, 11.5),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            Positioned(
              top: AppResponsive.scale(context, 20),
              right: 0,
              child: _Badge(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.danger,
                bg: Colors.white,
                title: 'GPS Active',
                titleColor: AppColors.primary,
                subtitle: 'Location verified',
                elevated: true,
              ),
            ),
            Positioned(
              bottom: AppResponsive.scale(context, 55),
              right: AppResponsive.scale(context, -10),
              child: _Badge(
                icon: Icons.check_rounded,
                iconColor: Colors.white,
                bg: AppColors.green,
                title: 'Submit',
                titleColor: Colors.white,
                elevated: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 3: Track ────────────────────────────────────────────────────────────

class _TrackIllustration extends StatelessWidget {
  const _TrackIllustration();

  @override
  Widget build(BuildContext context) {
    final anchor = AppResponsive.scale(context, 300);
    final circle = AppResponsive.scale(context, 240);
    return Center(
      child: SizedBox(
        width: anchor,
        height: anchor,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: circle,
              height: circle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warning.withValues(alpha: 0.12),
              ),
            ),
            Icon(Icons.local_shipping_rounded,
                size: AppResponsive.scale(context, 100),
                color: AppColors.primary),
            Positioned(
              top: AppResponsive.scale(context, 15),
              left: 0,
              child: _Badge(
                icon: Icons.error_rounded,
                iconColor: AppColors.danger,
                bg: AppColors.danger.withValues(alpha: 0.10),
                title: 'Defect Found',
                titleColor: AppColors.danger,
                subtitle: 'Brake Lights',
              ),
            ),
            Positioned(
              top: AppResponsive.scale(context, 25),
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: AppResponsive.padding(context, 16),
                    vertical: AppResponsive.padding(context, 10)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Text('98%',
                        style: TextStyle(
                            fontSize: AppResponsive.text(context, 20),
                            fontWeight: FontWeight.w800,
                            color: AppColors.green)),
                    Text('Fleet Health',
                        style: TextStyle(
                            fontSize: AppResponsive.text(context, 10.5),
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: AppResponsive.scale(context, 10),
              left: AppResponsive.scale(context, -10),
              child: Container(
                width: AppResponsive.scale(context, 165),
                padding: EdgeInsets.all(AppResponsive.padding(context, 12)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Maintenance Due',
                        style: TextStyle(
                            fontSize: AppResponsive.text(context, 11.5),
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    SizedBox(height: AppResponsive.spacing(context, 8)),
                    _ProgressRow(
                        label: 'Oil Change',
                        value: 0.85,
                        pct: '85%',
                        color: AppColors.warning),
                    SizedBox(height: AppResponsive.spacing(context, 6)),
                    _ProgressRow(
                        label: 'Tire Rotation',
                        value: 0.60,
                        pct: '60%',
                        color: AppColors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final String pct;
  final Color color;
  const _ProgressRow(
      {required this.label,
      required this.value,
      required this.pct,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: AppResponsive.text(context, 10),
                    color: AppColors.textSecondary)),
            Text(pct,
                style: TextStyle(
                    fontSize: AppResponsive.text(context, 10),
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
        SizedBox(height: AppResponsive.spacing(context, 3)),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 4,
            backgroundColor: AppColors.border.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─── Page 4: Compliance ───────────────────────────────────────────────────────

class _ComplianceIllustration extends StatelessWidget {
  const _ComplianceIllustration();

  @override
  Widget build(BuildContext context) {
    final anchor = AppResponsive.scale(context, 300);
    final circle = AppResponsive.scale(context, 240);
    return Center(
      child: SizedBox(
        width: anchor,
        height: anchor,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: circle,
              height: circle,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withValues(alpha: 0.10),
              ),
            ),
            Icon(Icons.gpp_good_rounded,
                size: AppResponsive.scale(context, 110),
                color: AppColors.green),
            Positioned(
              top: AppResponsive.scale(context, 20),
              left: 0,
              child: _Badge(
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.green,
                bg: AppColors.green.withValues(alpha: 0.12),
                title: 'DOT Compliant',
                titleColor: AppColors.green,
              ),
            ),
            Positioned(
              top: AppResponsive.scale(context, 20),
              right: 0,
              child: _Badge(
                icon: Icons.folder_rounded,
                iconColor: AppColors.info,
                bg: AppColors.info.withValues(alpha: 0.12),
                title: 'Records Kept',
                titleColor: AppColors.info,
              ),
            ),
            Positioned(
              bottom: AppResponsive.scale(context, 40),
              left: AppResponsive.scale(context, 10),
              child: _Badge(
                icon: Icons.alt_route_rounded,
                iconColor: AppColors.warning,
                bg: AppColors.warning.withValues(alpha: 0.15),
                title: 'Road Ready',
                titleColor: AppColors.warning,
              ),
            ),
            Positioned(
              bottom: AppResponsive.scale(context, 40),
              right: 0,
              child: _Badge(
                icon: Icons.health_and_safety_rounded,
                iconColor: AppColors.danger,
                bg: AppColors.danger.withValues(alpha: 0.10),
                title: 'Safety First',
                titleColor: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared badge chip ────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String title;
  final Color titleColor;
  final String? subtitle;
  final bool elevated;

  const _Badge({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.title,
    required this.titleColor,
    this.subtitle,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.padding(context, 13),
          vertical: AppResponsive.padding(context, subtitle != null ? 8 : 9)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        boxShadow: elevated
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppResponsive.scale(context, 15), color: iconColor),
          SizedBox(width: AppResponsive.spacing(context, 6)),
          if (subtitle == null)
            Text(title,
                style: TextStyle(
                    fontSize: AppResponsive.text(context, 12),
                    fontWeight: FontWeight.w800,
                    color: titleColor))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: AppResponsive.text(context, 12),
                        fontWeight: FontWeight.w800,
                        color: titleColor)),
                Text(subtitle!,
                    style: TextStyle(
                        fontSize: AppResponsive.text(context, 10),
                        color: AppColors.textSecondary)),
              ],
            ),
        ],
      ),
    );
  }
}
