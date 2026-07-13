import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../routes/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(Duration(milliseconds: AppConstants.splashDurationMs));
    if (!mounted) return;
    final storage = StorageService();
    if (storage.isLoggedIn) {
      context.go(AppRoutes.dashboard);
    } else if (storage.isFirstLaunch) {
      await storage.setFirstLaunchDone();
      context.go(AppRoutes.intro);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo circle
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: _FleetCheckLogo(),
                  ),
                ),
                const SizedBox(height: 24),
                // App Name
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Fleet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text: 'Check',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FleetCheckLogo extends StatelessWidget {
  const _FleetCheckLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LogoPainter());
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final greenPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Truck silhouette (simplified)
    final truckPath = Path()
      ..moveTo(cx - 25, cy + 10)
      ..lineTo(cx - 25, cy - 5)
      ..lineTo(cx - 10, cy - 15)
      ..lineTo(cx + 5, cy - 15)
      ..lineTo(cx + 5, cy - 8)
      ..lineTo(cx + 25, cy - 8)
      ..lineTo(cx + 25, cy + 10)
      ..close();

    canvas.drawPath(truckPath, paint);

    // Wheels
    canvas.drawCircle(Offset(cx - 16, cy + 12), 5, paint);
    canvas.drawCircle(Offset(cx + 16, cy + 12), 5, paint);

    // Checkmark on cab
    final checkPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(cx - 5, cy - 10)
      ..lineTo(cx - 1, cy - 6)
      ..lineTo(cx + 6, cy - 14);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
