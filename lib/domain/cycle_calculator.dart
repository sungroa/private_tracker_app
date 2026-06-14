import 'dart:developer' as developer;
import 'models/cycle_log.dart';
import 'calculators/cycle_length_forecaster.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';
import '../core/services/clock.dart';
import '../core/utils/date_time_extensions.dart';

/// Core domain logic for menstruation cycle analysis and predictions.
/// 
/// 💼 **Domain Context**: This calculator is the brain of the prediction engine.
/// It uses a hybrid approach:
/// 1. **Sympto-Thermal Method (STM)**: If BBT data is available, it uses the 
/// 3-over-6 rule for mathematical confirmation of ovulation.
/// 2. **Statistical Fallback**: For users without BBT tracking, it uses 
/// weighted historical averages with outlier removal.
class CycleCalculator {
  // Average cycle length (default 28 days)
  static const int defaultCycleLength = 28;

  final IClock _clock;

  CycleCalculator(this._clock);

  /// Predicts the next period start date based on previous logs.
  ///
  /// Delegates to [predictFuturePeriods] with a count of 1. Kept for backwards
  /// compatibility with any callers that only need the nearest prediction.
  DateTime? predictNextPeriod(
    List<CycleLog> cycleLogs, [
    List<SymptomLog>? symptomLogs,
    double threshold = 0.2,
  ]) {
    final results = predictFuturePeriods(cycleLogs, symptomLogs: symptomLogs, threshold: threshold, count: 1);
    return results.isEmpty ? null : results.first;
  }

  /// Predicts up to [count] future period start dates in chronological order.
  ///
  /// When [count] is omitted the adaptive tier logic is applied:
  /// - 1 recorded cycle  → 1 projection  (cold start, no pattern)
  /// - 2–3 cycles        → 2 projections
  /// - 4–7 cycles        → 3 projections
  /// - ≥8 cycles         → 4 projections (Hybrid ARIMA active)
  ///
  /// Each subsequent cycle is predicted by appending the previously predicted
  /// length to the synthetic history and re-running the forecaster. This means
  /// later projections naturally follow the modelled trajectory rather than
  /// blindly repeating the same cycle length.
  ///
  /// If [symptomLogs] are provided and a BBT-confirmed ovulation is detected
  /// for the current (most recent) cycle, that confirmation overrides the
  /// first projection only; subsequent cycles use the statistical model.
  List<DateTime> predictFuturePeriods(
    List<CycleLog> cycleLogs, {
    List<SymptomLog>? symptomLogs,
    double threshold = 0.2,
    int? count,
  }) {
    if (cycleLogs.isEmpty) return [];

    // Sort newest first
    final sortedCycleEvents = List<CycleLog>.from(cycleLogs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    // --- Build historical cycle-length series (oldest → newest) ---
    final lengths = <int>[];
    for (int i = 0; i < sortedCycleEvents.length - 1; i++) {
      final length = sortedCycleEvents[i].startDate
          .daysDifference(sortedCycleEvents[i + 1].startDate);
      if (length >= 15) {
        lengths.add(length);
      } else {
        developer.log(
          'Ignoring micro-cycle: $length days (spotting or duplicate log)',
          name: 'PrivacyTracker.Prediction',
        );
      }
    }
    // Forecaster expects chronological order (oldest first)
    final chronologicalLengths = lengths.reversed.toList();

    // --- Determine how many cycles to project ---
    final projectionCount = count ?? _adaptiveProjectionCount(chronologicalLengths.length);

    // --- First projection: may be overridden by confirmed ovulation (STM) ---
    final List<DateTime> results = [];
    DateTime anchor = sortedCycleEvents.first.startDate;
    final isUtc = anchor.isUtc;

    // Attempt STM ovulation confirmation for the very first projection only
    DateTime? firstProjection;
    if (symptomLogs != null && symptomLogs.isNotEmpty) {
      final latestCycleStart = sortedCycleEvents.first.startDate;
      final currentCycleEvents = symptomLogs
          .where((log) => !log.date.isBefore(latestCycleStart))
          .toList();
      final confirmedOvulation = confirmOvulation(currentCycleEvents, threshold: threshold);
      if (confirmedOvulation != null) {
        // STM: luteal phase ≈ 14 days
        firstProjection = isUtc
            ? DateTime.utc(
                confirmedOvulation.year,
                confirmedOvulation.month,
                confirmedOvulation.day + 14,
              )
            : DateTime(
                confirmedOvulation.year,
                confirmedOvulation.month,
                confirmedOvulation.day + 14,
              );
      }
    }

    // Synthetic length history that grows as we project further
    final syntheticLengths = List<int>.from(chronologicalLengths);

    for (int i = 0; i < projectionCount; i++) {
      final int predictedLength;
      DateTime nextPeriod;

      if (i == 0 && firstProjection != null) {
        // BBT-confirmed first projection
        nextPeriod = firstProjection;
        // Back-calculate the synthetic length for subsequent forecaster calls
        predictedLength = nextPeriod.daysDifference(anchor).abs();
      } else {
        if (syntheticLengths.isEmpty) {
          predictedLength = defaultCycleLength;
        } else {
          predictedLength = CycleLengthForecaster.predictNextLength(syntheticLengths);
        }
        nextPeriod = isUtc
            ? DateTime.utc(anchor.year, anchor.month, anchor.day + predictedLength)
            : DateTime(anchor.year, anchor.month, anchor.day + predictedLength);
      }

      results.add(nextPeriod);
      developer.log(
        'Projection ${i + 1}/$projectionCount: ${nextPeriod.toIso8601String()} (length: $predictedLength)',
        name: 'PrivacyTracker.Prediction',
      );

      // Feed the prediction back for the next iteration
      syntheticLengths.add(predictedLength);
      anchor = nextPeriod;
    }

    return results;
  }

  /// Returns the number of future cycles to project based on recorded history.
  ///
  /// Mirrors the [CycleLengthForecaster] pipeline tiers so the two stay in sync:
  /// - 0–1 recorded lengths → 1 projection (cold start)
  /// - 2–3 lengths          → 2 projections
  /// - 4–7 lengths          → 3 projections
  /// - ≥8 lengths           → 4 projections (ARIMA active)
  static int _adaptiveProjectionCount(int historyLength) {
    if (historyLength <= 1) return 1;
    if (historyLength <= 3) return 2;
    if (historyLength <= 7) return 3;
    return 4;
  }

  /// Implements the Sympto-Thermal Method "3-over-6 rule" to confirm ovulation.
  /// Scans chronologically for 3 consecutive days where BBT is [threshold] higher
  /// than the maximum of the preceding 6 consecutive days.
  /// Returns the day BEFORE the temperature shift (the confirmed ovulation date).
  DateTime? confirmOvulation(List<SymptomLog> logs, {double threshold = 0.2}) {
    if (logs.length < 9) return null;

    final sorted = List<SymptomLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    DateTime? latestConfirmed;

    // Slide across the logs: i is the first day of the 3-day high-temp shift
    // We need 6 days before i, so starting index is 6.
    for (int i = 6; i <= sorted.length - 3; i++) {
      // 1. Get preceding 6 days
      final preceding6 = sorted.sublist(i - 6, i);
      if (preceding6.any((log) => log.basalBodyTemperature == null)) continue;

      // 2. Get 3 potential shift days
      final shiftDays = sorted.sublist(i, i + 3);
      if (shiftDays.any((log) => log.basalBodyTemperature == null)) continue;

      // Check for continuity in dates (must be consecutive logs)
      bool isConsecutive = true;
      for (int j = i - 6; j < i + 2; j++) {
        if (sorted[j + 1].date.daysDifference(sorted[j].date) != 1) {
          isConsecutive = false;
          break;
        }
      }
      if (!isConsecutive) continue;

      final maxPreceding = preceding6
          .map((l) => l.basalBodyTemperature!)
          .reduce((a, b) => a > b ? a : b);

      final isShiftValidated = shiftDays.every(
        (log) => log.basalBodyTemperature! >= (maxPreceding + threshold),
      );

      if (isShiftValidated) {
        // Ovulation is marked as the day before the first high temp
        latestConfirmed = sorted[i - 1].date;
      }
    }

    return latestConfirmed;
  }

  /// Calculates the current cycle day (1, 2, 3...)
  int currentCycleDay(DateTime lastPeriodStart) {
    return _clock.now().daysDifference(lastPeriodStart) + 1;
  }

  /// Checks if the user is currently in their period.
  bool isCurrentlyInPeriod(List<CycleLog> logs) {
    if (logs.isEmpty) return false;
    final sortedLogs = List<CycleLog>.from(logs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final latest = sortedLogs.first;

    final now = _clock.now();

    // Period usually lasts 3-7 days if not ended yet
    if (latest.endDate == null) {
      final daysSinceStart = now.daysDifference(latest.startDate);
      return daysSinceStart >= 0 && daysSinceStart < 7;
    }

    final end = latest.endDate!;
    return now.isAfter(latest.startDate) && now.isBefore(DateTime(end.year, end.month, end.day + 1));
  }
}
