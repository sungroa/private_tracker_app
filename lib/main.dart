import 'package:flutter/material.dart';
import 'core/services/auth_service.dart';
import 'data/storage/encrypted_storage_service.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/authentication_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const AppLockWrapper(child: HomePage()),
    );
  }
}

class AppLockWrapper extends StatefulWidget {
  final Widget child;
  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _isInitializing = true;
  bool _useBiometric = false;
  bool _storageInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock the app when it goes to background and comes back
    if (state == AppLifecycleState.paused) {
      if (_useBiometric) {
        setState(() => _isAuthenticated = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_useBiometric && !_isAuthenticated) {
        _triggerAuth();
      }
    }
  }

  Future<void> _checkInitialAuth() async {
    _useBiometric = await AuthService.instance.isBiometricEnabled();
    
    if (!_useBiometric) {
      await _initializeStorage();
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isInitializing = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      _triggerAuth();
    }
  }

  Future<void> _triggerAuth() async {
    final success = await AuthService.instance.authenticate();
    if (success) {
      await _initializeStorage();
      if (mounted) {
        setState(() => _isAuthenticated = true);
      }
    }
  }

  Future<void> _initializeStorage() async {
    if (_storageInitialized) return;
    try {
      await EncryptedStorageService.instance.initialize();
      _storageInitialized = true;
    } catch (e) {
      debugPrint("Failed to initialize encrypted storage: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_useBiometric && !_isAuthenticated) {
      return AuthenticationOverlay(
        onUnlockSuccess: () async {
          await _initializeStorage();
          if (mounted) {
            setState(() => _isAuthenticated = true);
          }
        },
      );
    }

    return widget.child;
  }
}
