import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/navigation/main_navigation_screen.dart';
import '../../ui/onboarding/onboarding_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return const MainNavigationScreen();
    } else {
      return const StitchOnboardingScreen();
    }
  }
}
