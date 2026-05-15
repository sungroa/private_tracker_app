import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/repositories/cycle_log_repository_impl.dart';
import '../../data/repositories/data_source_repository_impl.dart';
import '../../data/repositories/symptom_log_repository_impl.dart';
import '../../data/repositories/sync_metadata_repository_impl.dart';
import '../../data/repositories/tag_repository_impl.dart';
import '../../data/repositories/play_billing_donation_repository.dart';
import '../../data/storage/backup_orchestrator.dart';
import '../../data/storage/backup_restore_service.dart';
import '../../data/storage/data_export_service.dart';
import '../../data/storage/data_sources/cycle_data_source.dart';
import '../../data/storage/data_sources/data_seeding_service.dart';
import '../../data/storage/data_sources/symptom_data_source.dart';
import '../../data/storage/data_sources/tag_data_source.dart';
import '../../data/storage/encrypted_storage_service.dart';
import '../../data/storage/google_drive_sync_repository.dart';
import '../../data/storage/local_database_manager.dart';
import '../../data/storage/partner_storage_service.dart';
import '../../data/storage/secure_key_storage.dart';
import '../../domain/repositories/cycle_log_repository.dart';
import '../../domain/repositories/data_source_repository.dart';
import '../../domain/repositories/symptom_log_repository.dart';
import '../../domain/repositories/sync_metadata_repository.dart';
import '../../domain/repositories/tag_repository.dart';
import '../../domain/repositories/donation_repository.dart';
import '../../domain/services/cloud_sync_interface.dart';
import '../../domain/services/partner_sharing_service.dart';
import '../../domain/usecases/add_tag_use_case.dart';
import '../../domain/usecases/delete_cycle_log_use_case.dart';
import '../../domain/usecases/delete_symptom_log_use_case.dart';
import '../../domain/usecases/delete_tag_use_case.dart';
import '../../domain/usecases/get_cycle_logs_use_case.dart';
import '../../domain/usecases/get_symptom_logs_use_case.dart';
import '../../domain/usecases/get_tags_use_case.dart';
import '../../domain/usecases/save_cycle_log_use_case.dart';
import '../../domain/usecases/save_symptom_log_use_case.dart';
import '../../domain/usecases/sync_data_use_case.dart';
import 'app_initializer.dart';
import 'auth_service.dart';
import 'notification_orchestrator.dart';
import 'notification_service.dart';
import 'preferences_service.dart';
import 'package:app_links/app_links.dart';
import 'clock.dart';
import '../../domain/cycle_calculator.dart';
import '../../domain/trends_calculator.dart';

/// A simple service locator to manage application dependencies.
/// 
/// Following "Technical Excellence" principles, this centralizes dependency 
/// orchestration, removing the burden from the UI layer.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // --- Core Domain Services ---
  
  /// Coordinates the application startup sequence and data warm-up.
  late final AppInitializer appInitializer;
  
  /// Manages high-level partner data sharing logic and permissions.
  late final PartnerSharingService partnerSharingService;
  
  /// Handles user authentication and session persistency.
  late final AuthService authService;
  
  /// Low-level key-value storage for application settings.
  late final PreferencesService preferencesService;
  
  /// Orchestrates local push notifications (period reminders, etc).
  late final NotificationService notificationService;
  
  /// High-level logic for scheduling data-driven notifications.
  late final NotificationOrchestrator notificationOrchestrator;
  
  /// Handles deep links for partner connection and invitations.
  late final AppLinks appLinks;

  /// Provides the current time.
  late final IClock clock;
  
  /// Core engine for menstruation cycle predictions.
  late final CycleCalculator cycleCalculator;

  /// Facade for aggregating cycle trends and statistics.
  late final TrendsCalculator trendsCalculator;
  
  // --- Storage & Data Infrastructure ---
  
  /// Bridge to the platform's Secure Storage (KeyChain/KeyStore).
  late final SecureKeyStorage keyStorage;
  
  /// Singleton manager for the Hive database health and instance lifecycle.
  late final LocalDatabaseManager dbManager;
  
  /// Handles the physical export and import of SQLite/Hive database files.
  late final BackupRestoreService backupService;
  
  /// Serializes application state into shareable JSON/CSV formats.
  late final DataExportService exportService;
  
  /// Responsible for importing initial sample data if requested.
  late final DataSeedingService seedingService;
  
  /// Specialized storage for partner identification and shared metadata.
  late final PartnerStorageService partnerStorage;
  
  /// Low-level Hive data source for [CycleLog] persistent storage.
  late final CycleDataSource cycleDataSource;
  
  /// Low-level Hive data source for [SymptomLog] persistent storage.
  late final SymptomDataSource symptomDataSource;
  
  /// Low-level Hive data source for [CustomTag] persistent storage.
  late final TagDataSource tagDataSource;
  
  /// Orchestrator for all repository-level storage operations including encryption.
  late final EncryptedStorageService encryptedStorage;
  
  /// High-level service for coordinating atomic backups and restores.
  late final BackupOrchestrator backupOrchestrator;

  // --- Domain Repositories ---
  
  /// Repository for managing menstruation cycle records.
  late final CycleLogRepository cycleRepository;
  
  /// Repository for managing symptom and mood logs.
  late final SymptomLogRepository symptomRepository;
  
  /// Repository for managing user-defined custom categories/tags.
  late final TagRepository tagRepository;
  
  /// Internal repository for tracking sync timestamps and checksums.
  late final ISyncMetadataRepository syncMetadataRepository;
  
  /// Unified access point for complex data export/import operations.
  late final IDataSourceRepository dataSourceRepository;

  /// Repository for managing donations and supporter status.
  late final IDonationRepository donationRepository;

  // --- Domain Use Cases ---
  
  /// Core use case for fetching and predicting cycle trends.
  late final GetCycleLogsUseCase getCycleLogsUseCase;
  
  /// Use case for creating or updating a cycle entry.
  late final SaveCycleLogUseCase saveCycleLogUseCase;
  
  /// Use case for removing a specific cycle entry.
  late final DeleteCycleLogUseCase deleteCycleLogUseCase;
  
  /// Use case for retrieving historical symptom logs.
  late final GetSymptomLogsUseCase getSymptomLogsUseCase;
  
  /// Use case for logging symptoms and moods.
  late final SaveSymptomLogUseCase saveSymptomLogUseCase;
  
  /// Use case for deleting symptom records.
  late final DeleteSymptomLogUseCase deleteSymptomLogUseCase;
  
  /// Use case for listing all custom tags.
  late final GetTagsUseCase getTagsUseCase;
  
  /// Use case for adding a new user-defined tag.
  late final AddTagUseCase addTagUseCase;
  
  /// Use case for deleting a custom tag.
  late final DeleteTagUseCase deleteTagUseCase;

  // --- Cloud Infrastructure ---
  
  /// Interface to remote storage providers (Google Drive, iCloud).
  late final CloudSyncInterface cloudSync;
  
  /// Orchestrates the record-level LWW merge process.
  late final SyncDataUseCase syncUseCase;

  /// Initializes all application services.
  /// 
  /// Dependencies are resolved in their natural order of creation.
  void setup({
    AuthService? auth,
    PreferencesService? prefs,
    NotificationService? notifications,
    SecureKeyStorage? keys,
    LocalDatabaseManager? db,
    CycleDataSource? cycleDs,
    SymptomDataSource? symptomDs,
    TagDataSource? tagDs,
    IDonationRepository? donations,
    AppLinks? customAppLinks,
    CloudSyncInterface? cloudSync,
    AppInitializer? initializer,
    String? serverClientId,
  }) {
    // 1. Core independent services
    appInitializer = initializer ?? AppInitializer();
    clock = SystemClock();
    cycleCalculator = CycleCalculator(clock);
    trendsCalculator = TrendsCalculator(cycleCalculator);
    partnerSharingService = PartnerSharingService(cycleCalculator, clock);
    authService = auth ?? AuthService();
    preferencesService = prefs ?? PreferencesService();
    notificationService = notifications ?? NotificationService();
    notificationOrchestrator = NotificationOrchestrator(
      notificationService: notificationService,
      preferencesService: preferencesService,
    );
    appLinks = customAppLinks ?? AppLinks();

    // 2. Data Access Layer
    keyStorage = keys ?? SecureKeyStorage(const FlutterSecureStorage());
    dbManager = db ?? LocalDatabaseManager();
    backupService = BackupRestoreService();
    exportService = DataExportService();
    seedingService = DataSeedingService();
    
    partnerStorage = PartnerStorageService(dbManager);
    cycleDataSource = cycleDs ?? CycleDataSource(dbManager);
    symptomDataSource = symptomDs ?? SymptomDataSource(dbManager);
    tagDataSource = tagDs ?? TagDataSource(dbManager);

    // 3. Orchestration Services
    encryptedStorage = EncryptedStorageService(
      keyStorage: keyStorage,
      dbManager: dbManager,
      exportService: exportService,
      seedingService: seedingService,
      cycleDataSource: cycleDataSource,
      symptomDataSource: symptomDataSource,
      tagDataSource: tagDataSource,
    );

    backupOrchestrator = BackupOrchestrator(
      backupService: backupService,
      dbManager: dbManager,
      cycleDataSource: cycleDataSource,
      symptomDataSource: symptomDataSource,
      tagDataSource: tagDataSource,
    );

    // 4. Repositories
    cycleRepository = CycleLogRepositoryImpl(cycleDataSource);
    symptomRepository = SymptomLogRepositoryImpl(symptomDataSource);
    tagRepository = TagRepositoryImpl(tagDataSource);
    syncMetadataRepository = SyncMetadataRepositoryImpl(dbManager);
    dataSourceRepository = DataSourceRepositoryImpl(encryptedStorage, backupOrchestrator);
    donationRepository = donations ?? PlayBillingDonationRepository(keyStorage);

    // 5. Use Cases
    getCycleLogsUseCase = GetCycleLogsUseCase(
      cycleRepository, 
      symptomRepository, 
      trendsCalculator,
    );
    saveCycleLogUseCase = SaveCycleLogUseCase(cycleRepository);
    deleteCycleLogUseCase = DeleteCycleLogUseCase(cycleRepository);
    
    getSymptomLogsUseCase = GetSymptomLogsUseCase(symptomRepository);
    saveSymptomLogUseCase = SaveSymptomLogUseCase(symptomRepository);
    deleteSymptomLogUseCase = DeleteSymptomLogUseCase(symptomRepository);

    getTagsUseCase = GetTagsUseCase(tagRepository);
    addTagUseCase = AddTagUseCase(tagRepository);
    deleteTagUseCase = DeleteTagUseCase(tagRepository);

    // 6. Cloud Sync Integration
    this.cloudSync = cloudSync ?? GoogleDriveSyncRepository(serverClientId: serverClientId);
    syncUseCase = SyncDataUseCase(
      cloudSync: this.cloudSync,
      dataSource: dataSourceRepository,
      metadata: syncMetadataRepository,
      keyProvider: () => keyStorage.getOrCreateCloudSyncKey(),
    );
  }
}
