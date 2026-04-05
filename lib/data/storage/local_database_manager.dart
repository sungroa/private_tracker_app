import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/symptom_log.dart';
import '../../domain/models/custom_tag.dart';

class LocalDatabaseManager {
  static const String cycleLogBox = 'cycle_logs';
  static const String symptomLogBox = 'symptom_logs';
  static const String customTagBox = 'custom_tags';
  static const String metaBox = 'meta';
  static const String partnerDataBox = 'partner_data';

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
        print("Hive.initFlutter failed, attempting Hive.init('.'): $e");
        Hive.init('.');
      }
    }

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CycleEventAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SymptomLogAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CustomTagAdapter());

    await Hive.openBox<CycleEvent>(
      cycleLogBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    await Hive.openBox<SymptomLog>(
      symptomLogBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    await Hive.openBox<CustomTag>(
      customTagBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    // Open meta box (unencrypted, stores only flags)
    await Hive.openBox<String>(metaBox);
    
    // Open partner data box
    await Hive.openBox(partnerDataBox);

    // Pre-populate defaults if empty
    await _initializeDefaultTags();
    
    _isInitialized = true;
    } catch (e) {
      _initializeFuture = null;
      rethrow;
    }
  }

  Future<void> _initializeDefaultTags() async {
    final box = Hive.box<CustomTag>(customTagBox);
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
        await box.put(tag.id, tag);
      }
    }
  }

  Box<T> getBox<T>(String name) => Hive.box<T>(name);
}
