import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/navigation/main_navigation_screen.dart';
import 'core/theme/app_colors.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'shared/services/app_settings_service.dart';

class ZerospillApp extends StatelessWidget {
  const ZerospillApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService();
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    
    return MaterialApp(
      title: 'Zerospill',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          primaryContainer: AppColors.primaryLight,
          secondary: AppColors.secondary,
          secondaryContainer: AppColors.secondaryLight,
          tertiary: AppColors.accent,
          tertiaryContainer: AppColors.accentLight,
          surface: AppColors.surface,
          surfaceContainerHighest: AppColors.background,
          onPrimary: Colors.white,
          onSecondary: AppColors.textPrimary,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          error: AppColors.error,
          outline: AppColors.textTertiary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: AppColors.textPrimary),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          elevation: 0,
        ),
        fontFamily: 'Roboto',
      ),
      home: settings.onboardingCompleted ? const MainNavigationScreen() : const OnboardingScreen(),
    );
  }
}
