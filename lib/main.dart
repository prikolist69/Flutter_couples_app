import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'core/storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://velkzcxoajxpnfxdhokh.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZlbGt6Y3hvYWp4cG5meGRob2toIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwNzQ2NTgsImV4cCI6MjEwODY1MDY1OH0.akZKYq2vEDummmjIhY0hvAUJgOftgKcFp5t6v45qY1E',
  );

  // Считываем сохраненные данные из памяти телефона
  final savedPairId = await StorageService.getPairId();
  final savedUserName = await StorageService.getUserName();

  runApp(
    CouplesApp(initialPairId: savedPairId, initialUserName: savedUserName),
  );
}

class CouplesApp extends StatelessWidget {
  final String? initialPairId;
  final String? initialUserName;

  const CouplesApp({super.key, this.initialPairId, this.initialUserName});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Our Space',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Если сессия есть — сразу пускаем на главную, если нет — на онбординг
      home: (initialPairId != null && initialUserName != null)
          ? HomeScreen(pairId: initialPairId!, userName: initialUserName!)
          : const OnboardingScreen(),
    );
  }
}
