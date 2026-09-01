import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          background: AppColors.background,
          error: AppColors.danger,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme:
            ThemeData.light().textTheme.apply(fontFamily: 'Verdana').copyWith(
                  displayLarge: const TextStyle(
                      fontFamily: 'Verdana',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700),
                  displayMedium: const TextStyle(
                      fontFamily: 'Verdana',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700),
                  headlineLarge: const TextStyle(
                      fontFamily: 'Verdana',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                  headlineMedium: const TextStyle(
                      fontFamily: 'Verdana',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                  titleLarge: const TextStyle(
                      fontFamily: 'Verdana',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                  titleMedium: const TextStyle(
                      fontFamily: 'Verdana',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500),
                  bodyLarge: const TextStyle(
                      fontFamily: 'Verdana', color: AppColors.textPrimary),
                  bodyMedium: const TextStyle(
                      fontFamily: 'Verdana', color: AppColors.textPrimary),
                  bodySmall: const TextStyle(
                      fontFamily: 'Verdana', color: AppColors.textSecondary),
                  labelLarge: const TextStyle(
                      fontFamily: 'Verdana',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light, // White icons for Android
            statusBarBrightness: Brightness.dark, // White icons for iOS
          ),
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          helperStyle: TextStyle(
              fontFamily: 'Verdana', color: AppColors.primary, fontSize: 14),
          fillColor: AppColors.textPrimary,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          labelStyle: const TextStyle(
              fontFamily: 'Verdana',
              color: AppColors.textSecondary,
              fontSize: 14),
          hintStyle: const TextStyle(
              fontFamily: 'Verdana', color: AppColors.textLight, fontSize: 14),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.background,
          labelStyle: const TextStyle(fontFamily: 'Verdana', fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.secondary,
          linearTrackColor: AppColors.border,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: const Color(0xFF4A90D9),
          secondary: AppColors.accent,
          surface: AppColors.darkSurface,
          background: AppColors.darkBackground,
          error: AppColors.danger,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.darkSurface,
          foregroundColor: Colors.white,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.darkBorder),
          ),
          margin: EdgeInsets.zero,
        ),
      );
}
