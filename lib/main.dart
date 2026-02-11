import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'services/push_notification_service.dart';
import 'firebase_options.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/auth_gate.dart';
import 'features/ai/providers/ai_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await PushNotificationService.initialize();
  
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDark') ?? false;
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme(isDark)),
        ChangeNotifierProvider(create: (_) => AiProvider()),
      ],
      child: const ZeroSpillApp(),
    ),
  );
}

class ZeroSpillApp extends StatelessWidget {
  const ZeroSpillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ZeroSpill',
          themeMode: themeProvider.themeMode,
          themeAnimationDuration: Duration.zero,
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.surface,
              background: AppColors.background,
            ),
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.darkPrimary,
              brightness: Brightness.dark,
              primary: AppColors.darkPrimary,
              secondary: AppColors.darkSecondary,
              surface: AppColors.darkSurface,
              background: AppColors.darkBackground,
            ),
            scaffoldBackgroundColor: AppColors.darkBackground,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.darkSurface,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

