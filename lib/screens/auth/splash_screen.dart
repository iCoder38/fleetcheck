import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_responsive.dart';
import '../../routes/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(Duration(milliseconds: AppConstants.splashDurationMs));
    if (!mounted) return;
    final storage = StorageService();
    if (storage.isLoggedIn) {
      context.go(AppRoutes.dashboard);
    } else if (storage.isFirstLaunch) {
      // await storage.setFirstLaunchDone();
      context.go(AppRoutes.intro);
    } else {
      context.go(AppRoutes.login);
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.appbg,
      body: Center(
        child: Padding(
          padding: AppResponsive.all(context,value: 55),
          child: Image(
            image: AssetImage(AppAssets.appLogo),
          ),
        ),
      ),
    );
  }
}

