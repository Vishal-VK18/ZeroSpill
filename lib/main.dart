import 'package:flutter/material.dart';
import 'app.dart';
import 'shared/services/app_settings_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ListenableBuilder(
      listenable: AppSettingsService(),
      builder: (context, child) => const ZerospillApp(),
    ),
  );
}
