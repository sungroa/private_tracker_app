import 'package:private_tracker_app/domain/models/custom_tag.dart';
import 'package:private_tracker_app/domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';
import 'package:uuid/uuid.dart';

/// Centralized factory for creating domain models in tests.
///
/// Following "Technical Excellence" principles, this ensures that tests
/// don't break every time a new required field is added to a domain model.
class TestModelFactory {
  static const _uuid = Uuid();

  /// Creates a [CycleLog] with sensible defaults for testing.
  static CycleLog createCycleLog({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    int flowIntensity = 3,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return CycleLog(
      id: id ?? _uuid.v4(),
      startDate: startDate ?? now.subtract(const Duration(days: 1)),
      endDate: endDate,
      notes: notes,
      flowIntensity: flowIntensity,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Creates a [SymptomLog] with sensible defaults for testing.
  static SymptomLog createSymptomLog({
    String? id,
    DateTime? date,
    List<String> symptoms = const [],
    String? notes,
    int moodRating = 3,
    double? basalBodyTemperature,
    String? cervicalFluidType,
    bool? lhTestPositive,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return SymptomLog(
      id: id ?? _uuid.v4(),
      date: date ?? now,
      symptoms: symptoms,
      notes: notes,
      moodRating: moodRating,
      basalBodyTemperature: basalBodyTemperature,
      cervicalFluidType: cervicalFluidType,
      lhTestPositive: lhTestPositive,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Creates a [CustomTag] for testing.
  static CustomTag createTag({String? id, String name = 'Test Tag', DateTime? updatedAt}) {
    return CustomTag(id: id ?? _uuid.v4(), name: name, updatedAt: updatedAt ?? DateTime.now());
  }
}
