import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import 'ai_home_screen.dart'; // Launch Screen
import 'ai_chat_screen.dart';

class AiMainScreen extends StatelessWidget {
  const AiMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, provider, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: provider.hasStartedChat 
              ? const AiChatScreen() 
              : const AiHomeScreen(), // Conceptual "Launch Screen"
        );
      },
    );
  }
}
