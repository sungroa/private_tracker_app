import 'package:hive_flutter/hive_flutter.dart';
import '../../core/registry/hive_registry.dart';
import '../../core/utils/security_logger.dart';
import 'hive_dtos.dart';

class LocalDatabaseManager {
  /// Default timeout for database operations.
  static const Duration _dbTimeout = Duration(seconds: 5);

  bool _isInitialized = false;
  Future<void>? _initializeFuture;

  // Cached box references for performance
  Box<CycleLogDto>? _cycleBox;
  Box<SymptomLogDto>? _symptomBox;
  Box<CustomTagDto>? _tagBox;
  Box<String>? _metaBox;

  bool get isInitialized => _isInitialized;

  /// Initializes Hive and the encrypted boxes.
  Future<void> initialize({String? basePath, required List<int> encryptionKey}) async {
    if (_isInitialized && _cycleBox != null && Hive.isBoxOpen(HiveRegistry.cycleLogBox)) return;

    if (_initializeFuture != null) return _initializeFuture;

    _initializeFuture = _performInitialization(basePath, encryptionKey);
    return _initializeFuture;
  }

  Future<void> _performInitialization(String? basePath, List<int> encryptionKey) async {
    try {
      if (basePath != null) {
        Hive.init(basePath);
      } else {
        try {
          await Hive.initFlutter();
        } catch (e) {
          SecurityLogger.logError(
            "Hive.initFlutter failed, falling back to Hive.init('.')",
            error: e,
          );
          Hive.init('.');
        }
      }

      // Register Adapters
      _registerAdapters();

      final cipher = HiveAesCipher(encryptionKey);

      // (P1) Parallelize box opening for improved startup performance
      final boxes = await Future.wait([
        Hive.openBox<CycleLogDto>(
          HiveRegistry.cycleLogBox,
          encryptionCipher: cipher,
        ).timeout(_dbTimeout),
        Hive.openBox<SymptomLogDto>(
          HiveRegistry.symptomLogBox,
          encryptionCipher: cipher,
        ).timeout(_dbTimeout),
        Hive.openBox<CustomTagDto>(
          HiveRegistry.customTagBox,
          encryptionCipher: cipher,
        ).timeout(_dbTimeout),
        Hive.openBox<String>(HiveRegistry.metaBox).timeout(_dbTimeout),
      ]);

      _cycleBox = boxes[0] as Box<CycleLogDto>;
      _symptomBox = boxes[1] as Box<SymptomLogDto>;
      _tagBox = boxes[2] as Box<CustomTagDto>;
      _metaBox = boxes[3] as Box<String>;

      // Open partner data box with non-destructive error handling
      await _openPartnerBox(cipher);

      _isInitialized = true;
      SecurityLogger.logEvent("LocalDatabaseManager initialized successfully");
    } catch (e, stack) {
      _initializeFuture = null;
      SecurityLogger.logError(
        "LocalDatabaseManager initialization failed",
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(HiveRegistry.cycleLogTypeId)) {
      Hive.registerAdapter(CycleLogDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveRegistry.symptomLogTypeId)) {
      Hive.registerAdapter(SymptomLogDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveRegistry.customTagTypeId)) {
      Hive.registerAdapter(CustomTagDtoAdapter());
    }
  }

  Future<void> _openPartnerBox(HiveAesCipher cipher) async {
    try {
      await Hive.openBox(HiveRegistry.partnerDataBox, encryptionCipher: cipher).timeout(_dbTimeout);
    } catch (e) {
      // (S2) If encryption fails, we don't silently delete.
      // We log it and let the calling orchestration decide (e.g., re-link partner).
      SecurityLogger.logError(
        "Failed to open partner data box. This may require re-pairing with partner.",
        error: e,
      );

      // Re-throwing so the application knows initialization wasn't 100% clean
      rethrow;
    }
  }

  /// Low-level access to a specific Hive box. Internal to data layer.
  Box<T> getBox<T>(String name) {
    if (!_isInitialized) {
      throw StateError('Attempted to access box "$name" before database initialization.');
    }

    // Use cached references when possible to avoid Map lookups in Hive.
    if (name == HiveRegistry.cycleLogBox && _cycleBox is Box<T>) return _cycleBox as Box<T>;
    if (name == HiveRegistry.symptomLogBox && _symptomBox is Box<T>) return _symptomBox as Box<T>;
    if (name == HiveRegistry.customTagBox && _tagBox is Box<T>) return _tagBox as Box<T>;
    if (name == HiveRegistry.metaBox && _metaBox is Box<T>) return _metaBox as Box<T>;

    return Hive.box<T>(name);
  }

  /// Updates the global creation/modification timestamp in the meta box.
  Future<void> updateLastModified() async {
    try {
      final box = getBox<String>(HiveRegistry.metaBox);
      await box.put(HiveRegistry.lastLocalModifiedKey, DateTime.now().toIso8601String());
    } catch (e) {
      SecurityLogger.logError("Failed to update last modified timestamp", error: e);
    }
  }

  /// Closes all managed boxes and resets the initialization state.
  Future<void> close() async {
    if (!_isInitialized) return;

    _isInitialized = false;
    _initializeFuture = null;

    // Specifying types is required by Hive when boxes were opened with explicit types
    final boxesToClose = [
      if (_cycleBox != null) _cycleBox!.close(),
      if (_symptomBox != null) _symptomBox!.close(),
      if (_tagBox != null) _tagBox!.close(),
      if (_metaBox != null) _metaBox!.close(),
      if (Hive.isBoxOpen(HiveRegistry.partnerDataBox))
        Hive.box(HiveRegistry.partnerDataBox).close(),
    ];

    _cycleBox = null;
    _symptomBox = null;
    _tagBox = null;
    _metaBox = null;

    await Future.wait(boxesToClose);
  }
}
