import 'package:flutter/material.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'data/storage/encrypted_storage_service.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/authentication_overlay.dart';
import 'package:provider/provider.dart';
import 'data/repositories/cycle_log_repository_impl.dart';
import 'data/repositories/symptom_log_repository_impl.dart';
import 'domain/repositories/cycle_log_repository.dart';
import 'domain/repositories/symptom_log_repository.dart';
import 'presentation/providers/cycle_provider.dart';
import 'presentation/providers/symptom_provider.dart';
import 'data/repositories/tag_repository_impl.dart';
import 'domain/repositories/tag_repository.dart';
import 'presentation/providers/tag_provider.dart';
import 'package:app_links/app_links.dart';
import 'domain/services/partner_sharing_service.dart';
import 'presentation/pages/partner_mode_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const PrivacyTrackerApp());
}

class PrivacyTrackerApp extends StatefulWidget {
  const PrivacyTrackerApp({super.key});

  @override
  State<PrivacyTrackerApp> createState() => _PrivacyTrackerAppState();
}

class _PrivacyTrackerAppState extends State<PrivacyTrackerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen((uri) {
      if (!mounted) return;
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    final params = PartnerSharingService.parseDeepLink(uri);
    if (params != null) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => PartnerModePage(
            initialPayload: params['data'],
            initialKey: params['key'],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CycleLogRepository>(
            create: (_) => CycleLogRepositoryImpl(EncryptedStorageService.instance)),
        Provider<SymptomLogRepository>(
            create: (_) => SymptomLogRepositoryImpl(EncryptedStorageService.instance)),
        Provider<TagRepository>(
            create: (_) => TagRepositoryImpl(EncryptedStorageService.instance)),
        ChangeNotifierProvider(
          create: (context) => CycleProvider(
            context.read<CycleLogRepository>(),
            context.read<SymptomLogRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SymptomProvider(context.read<SymptomLogRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => TagProvider(context.read<TagRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Women\'s Health Tracker',
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppLockWrapper(child: HomePage()),
      ),
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
        // Refresh providers now that storage is ready
        context.read<CycleProvider>().refresh();
        context.read<SymptomProvider>().refresh();
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
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundColor,
                AppTheme.accentColor.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security_rounded,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_useBiometric && !_isAuthenticated) {
      return AuthenticationOverlay(
        onUnlockSuccess: () async {
          await _initializeStorage();
          if (!context.mounted) return;
          context.read<CycleProvider>().refresh();
          context.read<SymptomProvider>().refresh();
          setState(() => _isAuthenticated = true);
        },
      );
    }

    return widget.child;
  }
}
