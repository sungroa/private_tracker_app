import 'package:flutter/material.dart';
import 'data/storage/encrypted_storage_service.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Privacy-First Local Storage (Encrypted Hive)
  try {
    await EncryptedStorageService.initialize();
  } catch (e) {
    debugPrint("Failed to initialize encrypted storage: $e");
    // Handle initialization failure (e.g., biometric prompt required)
  }

  runApp(const PrivacyTrackerApp());
}

class PrivacyTrackerApp extends StatelessWidget {
  const PrivacyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Women\'s Health Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
