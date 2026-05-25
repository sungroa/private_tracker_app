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
  /// If [symptomLogs] are provided, it attempts to mathematically confirm ovulation
  /// using the 3-over-6 rule and overrides the average prediction.
  DateTime? predictNextPeriod(
    List<CycleLog> cycleLogs, [
    List<SymptomLog>? symptomLogs,
    double threshold = 0.2,
  ]) {
    if (cycleLogs.isEmpty) {
      return null;
    }

    // Sort newest first
    final sortedCycleEvents = List<CycleLog>.from(cycleLogs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    // 1. Try to confirm ovulation for the current cycle if symptom logs are available
    if (symptomLogs != null && symptomLogs.isNotEmpty) {
      final latestCycleStart = sortedCycleEvents.first.startDate;
      final currentCycleEvents = symptomLogs
          .where((log) => !log.date.isBefore(latestCycleStart))
          .toList();

      final confirmedOvulation = confirmOvulation(currentCycleEvents, threshold: threshold);
      if (confirmedOvulation != null) {
        // STM standard: Luteal phase is consistently ~14 days
        return confirmedOvulation.isUtc
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

    if (sortedCycleEvents.length < 2) {
      final start = sortedCycleEvents.first.startDate;
      return start.isUtc
          ? DateTime.utc(start.year, start.month, start.day + defaultCycleLength)
          : DateTime(start.year, start.month, start.day + defaultCycleLength);
    }

    // 2. Fallback to historical Hybrid ARIMA pipeline
    final lengths = <int>[];
    for (int i = 0; i < sortedCycleEvents.length - 1; i++) {
      final length = sortedCycleEvents[i].startDate.daysDifference(sortedCycleEvents[i + 1].startDate);
      
      // Data Cleaning: Ignore "micro-cycles" < 15 days which are likely logging errors 
      // or mid-cycle spotting, as they aggressively skew ARIMA/Average models.
      if (length >= 15) {
        lengths.add(length);
      } else {
        developer.log('Ignoring micro-cycle length: $length days (likely spotting or duplicate log)', name: 'PrivacyTracker.Prediction');
      }
    }

    if (lengths.isEmpty) {
      developer.log('No valid cycle history after filtering, using default 28.', name: 'PrivacyTracker.Prediction');
      final start = sortedCycleEvents.first.startDate;
      return start.isUtc
          ? DateTime.utc(start.year, start.month, start.day + defaultCycleLength)
          : DateTime(start.year, start.month, start.day + defaultCycleLength);
    }

    // Forecaster expects oldest to newest
    final chronologicalLengths = lengths.reversed.toList();
    final predictedLength = CycleLengthForecaster.predictNextLength(chronologicalLengths);

    final start = sortedCycleEvents.first.startDate;
    final nextPeriod = start.isUtc
        ? DateTime.utc(start.year, start.month, start.day + predictedLength)
        : DateTime(start.year, start.month, start.day + predictedLength);
    developer.log('Calculated Next Period: ${nextPeriod.toIso8601String()} (Length: $predictedLength)', name: 'PrivacyTracker.Prediction');

    return nextPeriod;
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
