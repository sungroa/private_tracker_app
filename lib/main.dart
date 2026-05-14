import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'core/services/auth_service.dart';
import 'core/services/preferences_service.dart';
import 'core/services/app_initializer.dart';
import 'core/services/service_locator.dart';
import 'core/services/app_lifecycle_manager.dart';
import 'core/services/notification_orchestrator.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/authentication_overlay.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/cycle_provider.dart';
import 'presentation/providers/symptom_provider.dart';
import 'presentation/providers/tag_provider.dart';
import 'presentation/providers/cloud_sync_provider.dart';
import 'presentation/providers/donation_provider.dart';
import 'domain/repositories/donation_repository.dart';
import 'domain/usecases/get_cycle_logs_use_case.dart';
import 'domain/usecases/save_cycle_log_use_case.dart';
import 'domain/usecases/delete_cycle_log_use_case.dart';
import 'domain/usecases/sync_data_use_case.dart';
import 'domain/usecases/get_symptom_logs_use_case.dart';
import 'domain/usecases/save_symptom_log_use_case.dart';
import 'domain/usecases/delete_symptom_log_use_case.dart';
import 'domain/usecases/get_tags_use_case.dart';
import 'domain/usecases/add_tag_use_case.dart';
import 'domain/usecases/delete_tag_use_case.dart';
import 'data/storage/secure_key_storage.dart';
import 'domain/services/cloud_sync_interface.dart';

class StorageConfig {
  final String? storageBasePath;
  StorageConfig({this.storageBasePath});
}

/// The OAuth2 server/web client ID for Google Sign-In.
/// Required by both [GoogleSignIn.instance.initialize] and [ServiceLocator.setup].
const _kGoogleServerClientId =
    'REDACTED_OAUTH_CLIENT_ID';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // google_sign_in v7 mandates initialize() be awaited ONCE before any
  // API calls and before runApp().
  await GoogleSignIn.instance.initialize(
    serverClientId: _kGoogleServerClientId,
  );

  // Initialize Service Locator with default implementations
  ServiceLocator().setup(
    serverClientId: _kGoogleServerClientId,
  );

  runApp(const PrivacyTrackerApp());
}

class PrivacyTrackerApp extends StatefulWidget {
  final ServiceLocator? serviceLocator;
  const PrivacyTrackerApp({super.key, this.serviceLocator});

  @override
  State<PrivacyTrackerApp> createState() => _PrivacyTrackerAppState();
}

class _PrivacyTrackerAppState extends State<PrivacyTrackerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final sl = widget.serviceLocator ?? ServiceLocator();

    return MultiProvider(
      providers: [
        Provider.value(value: sl.appInitializer),
        Provider.value(value: sl.partnerSharingService),
        Provider.value(value: sl.authService),
        Provider.value(value: sl.preferencesService),
        Provider.value(value: sl.notificationService),
        Provider.value(value: sl.appLinks),
        Provider.value(value: sl.keyStorage),
        Provider.value(value: sl.dbManager),
        Provider.value(value: sl.backupService),
        Provider.value(value: sl.exportService),
        Provider.value(value: sl.seedingService),
        Provider.value(value: sl.partnerStorage),
        Provider.value(value: sl.cycleDataSource),
        Provider.value(value: sl.symptomDataSource),
        Provider.value(value: sl.tagDataSource),
        Provider.value(value: sl.encryptedStorage),
        Provider.value(value: sl.backupOrchestrator),
        Provider.value(value: sl.cycleRepository),
        Provider.value(value: sl.symptomRepository),
        Provider.value(value: sl.tagRepository),
        Provider.value(value: sl.syncMetadataRepository),
        Provider.value(value: sl.dataSourceRepository),
        Provider.value(value: sl.getSymptomLogsUseCase),
        Provider.value(value: sl.saveSymptomLogUseCase),
        Provider.value(value: sl.deleteSymptomLogUseCase),
        Provider.value(value: sl.getTagsUseCase),
        Provider.value(value: sl.addTagUseCase),
        Provider.value(value: sl.deleteTagUseCase),
        Provider.value(value: sl.getCycleLogsUseCase),
        Provider.value(value: sl.saveCycleLogUseCase),
        Provider.value(value: sl.deleteCycleLogUseCase),
        Provider.value(value: sl.cloudSync),
        Provider.value(value: sl.syncUseCase),
        Provider.value(value: sl.notificationOrchestrator),
        Provider.value(value: sl.donationRepository),
        ChangeNotifierProvider(
          create: (context) => DonationProvider(
            context.read<IDonationRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CloudSyncProvider(
            syncUseCase: context.read<SyncDataUseCase>(),
            prefs: context.read<PreferencesService>(),
            keyStorage: context.read<SecureKeyStorage>(),
            cloudSync: context.read<CloudSyncInterface>(),
          ),
        ),
        ChangeNotifierProxyProvider2<CloudSyncProvider,
            NotificationOrchestrator, CycleProvider>(
          create: (context) => CycleProvider(
            context.read<GetCycleLogsUseCase>(),
            context.read<SaveCycleLogUseCase>(),
            context.read<DeleteCycleLogUseCase>(),
          ),
          update:
              (context, cloudSync, notificationOrchestrator, cycleProvider) =>
                  cycleProvider!
                    ..attachSyncProvider(cloudSync)
                    ..attachNotificationOrchestrator(notificationOrchestrator),
        ),
        ChangeNotifierProxyProvider<CloudSyncProvider, SymptomProvider>(
          create: (context) => SymptomProvider(
            context.read<GetSymptomLogsUseCase>(),
            context.read<SaveSymptomLogUseCase>(),
            context.read<DeleteSymptomLogUseCase>(),
          ),
          update: (context, cloudSync, symptomProvider) =>
              symptomProvider!..attachSyncProvider(cloudSync),
        ),
        ChangeNotifierProxyProvider<CloudSyncProvider, TagProvider>(
          create: (context) => TagProvider(
            context.read<GetTagsUseCase>(),
            context.read<AddTagUseCase>(),
            context.read<DeleteTagUseCase>(),
          ),
          update: (context, cloudSync, tagProvider) =>
              tagProvider!..attachSyncProvider(cloudSync),
        ),
      ],
      child: AppLifecycleManager(
        navigatorKey: _navigatorKey,
        child: MaterialApp(
          title: 'Private Tracker',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? PremiumGradients.darkBackground
                          : PremiumGradients.lightBackground,
                    ),
                  ),
                ),
                Positioned(
                  top: -150,
                  right: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor
                          .withValues(alpha: isDark ? 0.08 : 0.04),
                    ),
                  ),
                ),
                if (child != null) child,
              ],
            );
          },
          home: const AppLockWrapper(child: HomePage()),
        ),
      ),
    );
  }
}

/// A dedicated security wrapper that handles biometric authentication.
///
/// Initialization [AppInitializer] is triggered only after successful
/// authentication to ensure data remains locked until verified.
class AppLockWrapper extends StatefulWidget {
  final Widget child;
  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> {
  bool _isAuthenticated = false;
  bool _isInitializing = true;
  bool _useBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final prefs = context.read<PreferencesService>();
    _useBiometric = await prefs.isBiometricEnabled();

    if (!_useBiometric) {
      await _completeSequence();
    } else {
      setState(() => _isInitializing = false);
      _triggerAuth();
    }
  }

  Future<void> _triggerAuth() async {
    final authService = context.read<AuthService>();
    final success = await authService.authenticate();
    if (success) {
      await _completeSequence();
    }
  }

  Future<void> _completeSequence() async {
    try {
      final initializer = context.read<AppInitializer>();
      await initializer.initialize(context);
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) return const _LoadingScreen();

    if (_useBiometric && !_isAuthenticated) {
      return AuthenticationOverlay(
        onUnlockSuccess: () => _completeSequence(),
      );
    }

    return widget.child;
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? PremiumGradients.darkBackground
                : PremiumGradients.lightBackground,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroIcon(primary: primary),
              const SizedBox(height: 32),
              _BrandingText(primary: primary),
              const SizedBox(height: 32),
              SizedBox(
                width: 40,
                height: 40,
                child:
                    CircularProgressIndicator(color: primary, strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final Color primary;
  const _HeroIcon({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.security_rounded, size: 64, color: primary),
    );
  }
}

class _BrandingText extends StatelessWidget {
  final Color primary;
  const _BrandingText({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Text(
      "SECURE ENVIRONMENT",
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: primary,
        letterSpacing: 2,
        fontFamily: AppTheme.fontFamily,
      ),
    );
  }
}
