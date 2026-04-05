import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/symptom_log.dart';
import '../../domain/models/custom_tag.dart';
import 'local_database_manager.dart';

class DatabaseMigrator {
  /// Migrates existing records to UUIDs (skipped if already done)
  Future<void> migrateToUUIDs() async {
    final metaBox = Hive.box<String>(LocalDatabaseManager.metaBox);
    if (metaBox.get('migration_v1') == 'done') return;

    // Migrate Cycle Events
    final cycleBox = Hive.box<CycleEvent>(LocalDatabaseManager.cycleLogBox);
    for (var key in cycleBox.keys.toList()) {
      final log = cycleBox.get(key);
      if (log != null && log.id.isEmpty) {
        final newLog = CycleEvent(
          id: const Uuid().v4(),
          startDate: log.startDate,
          endDate: log.endDate,
          notes: log.notes,
          flowIntensity: 3, // Default for migrated
        );
        await cycleBox.put(newLog.id, newLog);
        if (key != newLog.id) {
          await cycleBox.delete(key);
        }
      } else if (log != null && key != log.id) {
        await cycleBox.put(log.id, log);
        await cycleBox.delete(key);
      }
    }

    // Migrate Symptom Logs
    final symptomBox = Hive.box<SymptomLog>(LocalDatabaseManager.symptomLogBox);
    for (var key in symptomBox.keys.toList()) {
      final log = symptomBox.get(key);
      if (log != null && log.id.isEmpty) {
        final newLog = SymptomLog(
          id: const Uuid().v4(),
          date: log.date,
          symptoms: log.symptoms,
          moodRating: log.moodRating,
          notes: log.notes,
          basalBodyTemperature: log.basalBodyTemperature,
          cervicalFluidType: log.cervicalFluidType,
          lhTestPositive: log.lhTestPositive,
        );
        await symptomBox.put(newLog.id, newLog);
        if (key != newLog.id) {
          await symptomBox.delete(key);
        }
      } else if (log != null && key != log.id) {
        await symptomBox.put(log.id, log);
        await symptomBox.delete(key);
      }
    }

    // Migrate Custom Tags
    final tagBox = Hive.box<CustomTag>(LocalDatabaseManager.customTagBox);
    for (var key in tagBox.keys.toList()) {
      final tag = tagBox.get(key);
      if (tag != null && tag.id.isEmpty) {
        final newTag = CustomTag(
          id: const Uuid().v4(),
          name: tag.name,
          isDefault: tag.isDefault,
        );
        await tagBox.put(newTag.id, newTag);
        if (key != newTag.id) {
          await tagBox.delete(key);
        }
      }
    }
    // Mark migration as complete to avoid redundant scans
    await metaBox.put('migration_v1', 'done');
  }
}
