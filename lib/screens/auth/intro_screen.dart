// lib/screens/auth/intro_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../routes/app_router.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _icons = [
    Icons.checklist_rounded,
    Icons.qr_code_scanner_rounded,
    Icons.cloud_upload_rounded,
    Icons.verified_rounded,
  ];

  final _bgColors = [
    const Color(0xFF1B2A4A),
    const Color(0xFF1E3A2E),
    const Color(0xFF1A2A4E),
    const Color(0xFF2E1B4A),
  ];

  void _goToPage(int page) {
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  void _skip() => context.go(AppRoutes.login);
  void _getStarted() => context.go(AppRoutes.login);

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == 3;
    return Scaffold(
      body: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _pageController,
            itemCount: 4,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _IntroPage(
              index:  i,
              icon:   _icons[i],
              bgColor: _bgColors[i],
            ),
          ),

          // Top: Skip button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skip,
                  style: TextButton.styleFrom(foregroundColor: Colors.white.withOpacity(0.7)),
                  child: const Text('Skip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),

          // Bottom: navigation
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width:  _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == i ? AppColors.greenLight : Colors.white.withOpacity(0.3),
                        ),
                      )),
                    ),
                    const SizedBox(height: 28),

                    // Navigation buttons
                    Row(
                      children: [
                        // Back (hidden on first)
                        if (_currentPage > 0) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _goToPage(_currentPage - 1),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side:            const BorderSide(color: Colors.white38, width: 1.5),
                                minimumSize:     const Size(0, 52),
                              ),
                              child: const Text('Back'),
                            ),
                          ),
                          const SizedBox(width: 14),
                        ],

                        // Next / Get Started
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isLast ? _getStarted : () => _goToPage(_currentPage + 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                              minimumSize:     const Size(0, 52),
                              shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(isLast ? 'Get Started' : 'Next',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final int index;
  final IconData icon;
  final Color bgColor;

  const _IntroPage({required this.index, required this.icon, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [bgColor, const Color(0xFF0D1421)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),
              // Illustration
              Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.green.withOpacity(0.15),
                    AppColors.green.withOpacity(0.03),
                  ]),
                ),
                child: Container(
                  margin: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    shape:  BoxShape.circle,
                    color:  AppColors.green.withOpacity(0.12),
                    border: Border.all(color: AppColors.green.withOpacity(0.3), width: 1.5),
                  ),
                  child: Icon(icon, size: 80, color: AppColors.greenLight),
                ),
              ),
              const SizedBox(height: 48),
              // Title
              Text(
                AppStrings.introTitles[index],
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                    color: Colors.white, height: 1.2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                AppStrings.introDescriptions[index],
                style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.65),
                    height: 1.6),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
