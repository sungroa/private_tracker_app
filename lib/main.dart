import 'dart:async';
import 'package:flutter/material.dart';
import 'core/services/auth_service.dart';
import 'core/services/preferences_service.dart';
import 'core/services/notification_service.dart';
import 'data/storage/encrypted_storage_service.dart';
import 'data/storage/secure_key_storage.dart';
import 'data/storage/local_database_manager.dart';
import 'data/storage/backup_restore_service.dart';
import 'data/storage/data_export_service.dart';
import 'data/storage/backup_orchestrator.dart';
import 'data/storage/partner_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'data/storage/data_sources/cycle_data_source.dart';
import 'data/storage/data_sources/symptom_data_source.dart';
import 'data/storage/data_sources/tag_data_source.dart';
import 'data/storage/google_drive_sync_repository.dart';
import 'data/repositories/sync_metadata_repository_impl.dart';
import 'data/repositories/data_source_repository_impl.dart';
import 'domain/repositories/sync_metadata_repository.dart';
import 'domain/repositories/data_source_repository.dart';
import 'presentation/providers/cloud_sync_provider.dart';
import 'domain/usecases/sync_data_use_case.dart';
import 'domain/services/cloud_sync_interface.dart';

class StorageConfig {
  final String? storageBasePath;
  StorageConfig({this.storageBasePath});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // NotificationService is no longer initialized here globally.
  // It will be initialized once inside a Provider or App state.
  
  runApp(const PrivacyTrackerApp());
}

class PrivacyTrackerApp extends StatefulWidget {
  final SecureKeyStorage? keyStorage;
  final LocalDatabaseManager? dbManager;
  final BackupRestoreService? backupService;
  final DataExportService? exportService;
  final AuthService? authService;
  final PreferencesService? preferencesService;
  final NotificationService? notificationService;
  final AppLinks? appLinks;
  final String? storageBasePath;
  final CycleDataSource? cycleDataSource;
  final SymptomDataSource? symptomDataSource;
  final TagDataSource? tagDataSource;

  const PrivacyTrackerApp({
    super.key,
    this.keyStorage,
    this.dbManager,
    this.backupService,
    this.exportService,
    this.authService,
    this.preferencesService,
    this.notificationService,
    this.appLinks,
    this.storageBasePath,
    this.cycleDataSource,
    this.symptomDataSource,
    this.tagDataSource,
  });

  @override
  State<PrivacyTrackerApp> createState() => _PrivacyTrackerAppState();
}

class _PrivacyTrackerAppState extends State<PrivacyTrackerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    try {
      _appLinks = widget.appLinks ?? AppLinks();
      _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
        if (!mounted) return;
        _handleDeepLink(uri);
      });
    } catch (e) {
      debugPrint("AppLinks initialization failed: $e");
    }
  }

  void _handleDeepLink(Uri uri) {
    final partnerService = context.read<PartnerSharingService>();
    final params = partnerService.parseDeepLink(uri);
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
        Provider<PartnerSharingService>(create: (_) => PartnerSharingService()),
        Provider<AuthService>(create: (_) => widget.authService ?? AuthService()),
        Provider<PreferencesService>(create: (_) => widget.preferencesService ?? PreferencesService()),
        Provider<NotificationService>(create: (_) => widget.notificationService ?? (NotificationService()..initialize())),
        Provider<StorageConfig>(create: (_) => StorageConfig(storageBasePath: widget.storageBasePath)),
        Provider<SecureKeyStorage>(create: (_) => widget.keyStorage ?? SecureKeyStorage(const FlutterSecureStorage())),
        Provider<LocalDatabaseManager>(create: (_) => widget.dbManager ?? LocalDatabaseManager()),
        Provider<BackupRestoreService>(create: (_) => widget.backupService ?? BackupRestoreService()),
        Provider<DataExportService>(create: (_) => widget.exportService ?? DataExportService()),
        Provider<PartnerStorageService>(create: (context) => PartnerStorageService(context.read<LocalDatabaseManager>())),
        Provider<CycleDataSource>(create: (context) => widget.cycleDataSource ?? CycleDataSource(context.read<LocalDatabaseManager>())),
        Provider<SymptomDataSource>(create: (context) => widget.symptomDataSource ?? SymptomDataSource(context.read<LocalDatabaseManager>())),
        Provider<TagDataSource>(create: (context) => widget.tagDataSource ?? TagDataSource(context.read<LocalDatabaseManager>())),
        Provider<EncryptedStorageService>(
          create: (context) => EncryptedStorageService(
            keyStorage: context.read<SecureKeyStorage>(),
            dbManager: context.read<LocalDatabaseManager>(),
            exportService: context.read<DataExportService>(),
            cycleDataSource: context.read<CycleDataSource>(),
            symptomDataSource: context.read<SymptomDataSource>(),
            tagDataSource: context.read<TagDataSource>(),
          ),
        ),
        Provider<BackupOrchestrator>(
          create: (context) => BackupOrchestrator(
            backupService: context.read<BackupRestoreService>(),
            dbManager: context.read<LocalDatabaseManager>(),
            cycleDataSource: context.read<CycleDataSource>(),
            symptomDataSource: context.read<SymptomDataSource>(),
            tagDataSource: context.read<TagDataSource>(),
          ),
        ),
        Provider<CycleLogRepository>(
            create: (context) => CycleLogRepositoryImpl(context.read<CycleDataSource>())),
        Provider<SymptomLogRepository>(
            create: (context) => SymptomLogRepositoryImpl(context.read<SymptomDataSource>())),
        Provider<TagRepository>(
            create: (context) => TagRepositoryImpl(context.read<TagDataSource>())),
        Provider<ISyncMetadataRepository>(
            create: (context) => SyncMetadataRepositoryImpl(context.read<LocalDatabaseManager>())),
        Provider<IDataSourceRepository>(
            create: (context) => DataSourceRepositoryImpl(
              context.read<EncryptedStorageService>(),
              context.read<BackupOrchestrator>(),
            )),
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
        Provider<CloudSyncInterface>(
          create: (_) => GoogleDriveSyncRepository(),
        ),
        Provider<SyncDataUseCase>(
          create: (context) => SyncDataUseCase(
            cloudSync: context.read<CloudSyncInterface>(),
            dataSource: context.read<IDataSourceRepository>(),
            metadata: context.read<ISyncMetadataRepository>(),
            keyProvider: () => context.read<SecureKeyStorage>().getOrCreateCloudSyncKey(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CloudSyncProvider(
            syncUseCase: context.read<SyncDataUseCase>(),
            prefs: context.read<PreferencesService>(),
          )..init(),
        ),
      ],
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
              // Premium Mesh Gradient Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark ? PremiumGradients.darkBackground : PremiumGradients.lightBackground,
                  ),
                ),
              ),
              // Subtle Ambient Glows
              Positioned(
                top: -150,
                right: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
                  ),
                ),
              ),
              if (child != null) child,
            ],
          );
        },
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
    if (state == AppLifecycleState.paused) {
      if (_useBiometric) {
        setState(() => _isAuthenticated = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_useBiometric && !_isAuthenticated) {
        _triggerAuth();
      } else if (_isAuthenticated) {
        // Trigger background sync on resume
        _triggerAutoSync();
      }
    }
  }

  void _triggerAutoSync() {
    if (mounted) {
      final syncProvider = context.read<CloudSyncProvider>();
      if (syncProvider.isCloudEnabled) {
        syncProvider.sync();
      }
    }
  }

  Future<void> _checkInitialAuth() async {
    final prefs = context.read<PreferencesService>();
    _useBiometric = await prefs.isBiometricEnabled();
    
    if (!_useBiometric) {
      try {
        await _initializeStorage();
      } finally {
        if (mounted) {
          setState(() {
            // Only authenticate if storage initialized successfully
            _isAuthenticated = _storageInitialized;
            _isInitializing = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      _triggerAuth();
    }
  }

  Future<void> _triggerAuth() async {
    final authService = context.read<AuthService>();
    final success = await authService.authenticate();
    if (success) {
      await _initializeStorage();
      if (mounted && _storageInitialized) {
        context.read<CycleProvider>().refresh();
        context.read<SymptomProvider>().refresh();
        setState(() => _isAuthenticated = true);
      }
    }
  }

  Future<void> _initializeStorage() async {
    if (_storageInitialized) return;
    try {
      final config = context.read<StorageConfig>();
      final basePath = config.storageBasePath;
      
      await context.read<EncryptedStorageService>()
          .initialize(basePath: basePath);
          
      _storageInitialized = true;

      // Trigger auto-sync if enabled
      if (mounted) {
        _triggerAutoSync();
      }
    } catch (e) {
      debugPrint("Failed to initialize encrypted storage: $e");
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    if (_isInitializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? PremiumGradients.darkBackground : PremiumGradients.lightBackground,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    size: 64,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "SECURE ENVIRONMENT",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: primary,
                    letterSpacing: 2,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: primary,
                    strokeWidth: 3,
                  ),
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
