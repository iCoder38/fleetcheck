import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/logger_service.dart';
import 'core/services/session_manager.dart';
import 'repositories/auth_repository.dart';
import 'repositories/inspection_repository.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar icons white
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  // Initialize Firebase
  await Firebase.initializeApp();

  // Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Init services — order matters:
  //   1. StorageService first (ApiService reads the token from it)
  //   2. LoggerService second (ApiService writes to it)
  //   3. ApiService last (depends on both above)
  await StorageService().init();
  await LoggerService().init();
  ApiService().init();

  // Let the API layer force a redirect to login on an expired session
  // without needing a BuildContext (see SessionManager for why this is a
  // callback rather than a direct import of app_router.dart).
  SessionManager.onSessionExpired = () => appRouter.go(AppRoutes.login);

  debugPrint('API Log file: ${LoggerService().logFilePath}');

  runApp(MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>(create: (_) => AuthRepository()),
      RepositoryProvider<InspectionRepository>(
          create: (_) => InspectionRepository()),
    ],
    child: const FleetCheckApp(),
  ));
}

class FleetCheckApp extends StatelessWidget {
  const FleetCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Forces white status bar icons on every screen, including ones
      // without a Scaffold AppBar (whose theme.systemOverlayStyle would
      // otherwise be the only thing setting this) — without this wrapper
      // Android can fall back to dark icons on those screens.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: SessionManager.messengerKey,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
      ),
    );
  }
}
