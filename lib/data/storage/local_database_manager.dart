import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/custom_tag.dart';
import 'hive_dtos.dart';

class LocalDatabaseManager {
  static const String cycleLogBox = 'cycle_logs';
  static const String symptomLogBox = 'symptom_logs';
  static const String customTagBox = 'custom_tags';
  static const String metaBox = 'meta';
  static const String partnerDataBox = 'partner_data';
  
  static const String lastLocalModifiedKey = 'last_local_modified';
  static const String lastSyncChecksumKey = 'last_sync_checksum';

  bool _isInitialized = false;
  Future<void>? _initializeFuture;

  bool get isInitialized => _isInitialized;

  /// Initializes Hive and the encrypted boxes.
  Future<void> initialize({String? basePath, required List<int> encryptionKey}) async {
    if (_isInitialized && Hive.isBoxOpen(symptomLogBox)) return;
    
    if (_initializeFuture != null) return _initializeFuture;

    _initializeFuture = _performInitialization(basePath, encryptionKey);
    return _initializeFuture;
  }

  Future<void> _performInitialization(String? basePath, List<int> encryptionKey) async {
    try {
      if (basePath != null) {
      // In tests or custom environments
      Hive.init(basePath);
    } else {
      // Standard mobile initialization
      try {
        await Hive.initFlutter();
      } catch (e) {
        // Fallback for tests if initFlutter fails
        Hive.init('.');
      }
    }

    // Register Adapters
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(CycleLogDtoAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(SymptomLogDtoAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(CustomTagDtoAdapter());

    await Hive.openBox<CycleLogDto>(
      cycleLogBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    ).timeout(const Duration(seconds: 5));
    
    await Hive.openBox<SymptomLogDto>(
      symptomLogBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    ).timeout(const Duration(seconds: 5));
    
    await Hive.openBox<CustomTagDto>(
      customTagBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    ).timeout(const Duration(seconds: 5));

    // Open meta box (unencrypted, stores only flags)
    await Hive.openBox<String>(metaBox).timeout(const Duration(seconds: 5));
    
    // Open partner data box
    try {
      await Hive.openBox(
        partnerDataBox,
        encryptionCipher: HiveAesCipher(encryptionKey),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // If the box exists and is unencrypted, opening with a cipher throws.
      // We'll delete it and reopen encrypted. Partner data is syncable and safe to drop.
      await Hive.deleteBoxFromDisk(partnerDataBox);
      await Hive.openBox(
        partnerDataBox,
        encryptionCipher: HiveAesCipher(encryptionKey),
      ).timeout(const Duration(seconds: 5));
    }

    // Pre-populate defaults if empty
    await _initializeDefaultTags();
    
    _isInitialized = true;
    } catch (e) {
      _initializeFuture = null;
      rethrow;
    }
  }

  Future<void> _initializeDefaultTags() async {
    final box = Hive.box<CustomTagDto>(customTagBox);
    if (box.isEmpty) {
      final defaults = [
        'Cramps',
        'Bloating',
        'Acne',
        'Headache',
        'Mood Swings',
        'Fatigue',
      ];
      for (var name in defaults) {
        final tag = CustomTag(name: name, isDefault: true);
        await box.put(tag.id, CustomTagDto.fromDomain(tag));
      }
    }
  }

  Box<T> getBox<T>(String name) => Hive.box<T>(name);

  /// Updates the global creation/modification timestamp in the meta box.
  Future<void> updateLastModified() async {
    final box = Hive.box<String>(metaBox);
    await box.put(lastLocalModifiedKey, DateTime.now().toIso8601String());
  }
  
  /// Closes all managed boxes and resets the initialization state.
  Future<void> close() async {
    if (!_isInitialized) return;
    
    // Use type-safe box retrieval to avoid "Box already open with different type" errors
    if (Hive.isBoxOpen(cycleLogBox)) await Hive.box<CycleLogDto>(cycleLogBox).close();
    if (Hive.isBoxOpen(symptomLogBox)) await Hive.box<SymptomLogDto>(symptomLogBox).close();
    if (Hive.isBoxOpen(customTagBox)) await Hive.box<CustomTagDto>(customTagBox).close();
    if (Hive.isBoxOpen(metaBox)) await Hive.box<String>(metaBox).close();
    if (Hive.isBoxOpen(partnerDataBox)) await Hive.box(partnerDataBox).close();
    
    _isInitialized = false;
    _initializeFuture = null;
  }
}
