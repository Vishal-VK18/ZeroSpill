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
    
    return ListenableBuilder(
      listenable: settings,
      builder: (context, child) {
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final isDark = brightness == Brightness.dark;
        
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? AppColors.darkBackground : AppColors.background,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
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
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.dark(
              primary: AppColors.darkPrimary,
              primaryContainer: AppColors.darkPrimaryLight,
              secondary: AppColors.darkSecondary,
              secondaryContainer: AppColors.darkSecondaryLight,
              tertiary: AppColors.darkAccent,
              tertiaryContainer: AppColors.darkAccentLight,
              surface: AppColors.darkSurface,
              surfaceContainerHighest: AppColors.darkBackground,
              onPrimary: Colors.black,
              onSecondary: AppColors.darkTextPrimary,
              onSurface: AppColors.darkTextPrimary,
              onSurfaceVariant: AppColors.darkTextSecondary,
              error: AppColors.error,
              outline: AppColors.darkTextTertiary,
            ),
            scaffoldBackgroundColor: AppColors.darkBackground,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.darkSurface,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
              titleTextStyle: TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardThemeData(
              color: AppColors.darkSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: AppColors.darkSurface,
              selectedColor: AppColors.darkPrimary,
              labelStyle: TextStyle(color: AppColors.darkTextPrimary),
              secondaryLabelStyle: const TextStyle(color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: AppColors.darkSurface,
              selectedItemColor: AppColors.darkPrimary,
              unselectedItemColor: AppColors.darkTextTertiary,
              elevation: 0,
            ),
            fontFamily: 'Roboto',
          ),
          themeMode: settings.themeMode,
          home: settings.onboardingCompleted ? const MainNavigationScreen() : const OnboardingScreen(),
        );
      },
    );
  }
}
