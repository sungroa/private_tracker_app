import 'dart:developer' as developer;
import 'dart:math';

import 'package:collection/collection.dart';

/// Specialized calculator for menstruation cycle length forecasting.
///
/// 💼 **Domain Context**: This forecaster implements a "Cold Start to Hybrid ARIMA"
/// pipeline. It is designed to handle the high variance of early tracking
/// (cold start) while providing sophisticated statistical forecasting once
/// enough historical data is available.
class CycleLengthForecaster {
  static const int defaultCycleLength = 28;
  static const int minBiologicalCycle = 21;
  static const int maxBiologicalCycle = 45;

  /// Predicts the length of the next cycle based on historical data.
  ///
  /// [history] An array of past cycle lengths in chronological order
  /// (oldest to newest).
  static int predictNextLength(List<int> history) {
    final n = history.length;

    if (n == 0) {
      return defaultCycleLength;
    }

    if (n <= 3) {
      return _calculateAverage(history).round();
    }

    if (n <= 7) {
      return _calculateSoftTrimmedMean(history).round();
    }

    // Phase 2: Hybrid Pipeline (n >= 8)
    return _executeHybridPipeline(history);
  }

  /// Phase 1: Soft Trimmed Mean (4 <= n <= 7)
  /// Finds the value furthest from the median (extreme outlier candidate),
  /// removes it, and returns the average of the remaining values.
  static double _calculateSoftTrimmedMean(List<int> history) {
    final median = _calculateMedian(history.map((e) => e.toDouble()).toList());

    double maxDistance = -1;
    int indexToRemove = -1;

    for (int i = 0; i < history.length; i++) {
      final distance = (history[i] - median).abs();
      if (distance > maxDistance) {
        maxDistance = distance;
        indexToRemove = i;
      }
    }

    final remaining = List<int>.from(history)..removeAt(indexToRemove);
    return _calculateAverage(remaining);
  }

  /// Phase 2: Hybrid Pipeline (n >= 8)
  static int _executeHybridPipeline(List<int> history) {
    // 1. Lookback window (most recent 12 cycles)
    final lookback = history.length > 12 ? history.sublist(history.length - 12) : history;

    final lookbackDouble = lookback.map((e) => e.toDouble()).toList();

    // 2. Outlier Detection (IQR + Biological Override)
    final iqr = _calculateIQR(lookbackDouble);
    final q1 = _calculatePercentile(lookbackDouble, 25);
    final q3 = _calculatePercentile(lookbackDouble, 75);

    final lowerBound = q1 - (1.5 * iqr);
    final upperBound = q3 + (1.5 * iqr);

    final List<int> anomalyIndices = [];
    final List<double> nonAnomalousData = [];

    for (int i = 0; i < lookback.length; i++) {
      final val = lookback[i];
      final isAnomaly =
          val < lowerBound ||
          val > upperBound ||
          val < minBiologicalCycle ||
          val > maxBiologicalCycle;

      if (isAnomaly) {
        anomalyIndices.add(i);
      } else {
        nonAnomalousData.add(val.toDouble());
      }
    }

    // 3. Imputation (Do Not Drop Data)
    final medianOfCleanData = _calculateMedian(
      nonAnomalousData.isEmpty ? [defaultCycleLength.toDouble()] : nonAnomalousData,
    );
    final cleanedHistory = List<double>.from(lookbackDouble);
    for (final index in anomalyIndices) {
      cleanedHistory[index] = medianOfCleanData;
    }

    // 4. ARIMA Forecasting
    int prediction;
    try {
      prediction = _arimaForecast(cleanedHistory).round();
    } catch (e) {
      // Fallback: 12.5% Trimmed Mean of the lookback window
      prediction = _calculateTrimmedMean(lookbackDouble, 0.125).round();
    }

    // Safety Clamp: Ensure predictions remain within biological norms
    final clamped = prediction.clamp(minBiologicalCycle, maxBiologicalCycle);

    developer.log(
      'Pipeline: n=${history.length}, Raw Prediction=$prediction, Clamped=$clamped',
      name: 'PrivacyTracker.Prediction',
    );
    return clamped;
  }

  /// Simple ARIMA(1, 1, 1) or ARIMA(1, 0, 0) implementation.
  static double _arimaForecast(List<double> series) {
    if (series.length < 3 || _calculateVariance(series) == 0) {
      throw Exception('Insufficient variance or data for ARIMA');
    }

    // ARIMA(1, 1, 1) means we difference once (d=1)
    final differenced = <double>[];
    for (int i = 1; i < series.length; i++) {
      differenced.add(series[i] - series[i - 1]);
    }

    // Try fitting ARIMA(1, 1, 1) on the differenced series
    // AR(1): Y'_t = phi * Y'_{t-1} + error_t + theta * error_{t-1}

    final params = _fitArima111(differenced);
    final phi = params[0];
    final theta = params[1];

    // Last values
    final lastYPrime = differenced.last;
    final lastError = params[2]; // estimated error of the last point

    // Predict next differenced value
    final nextYPrime = phi * lastYPrime + theta * lastError;

    // Undo differencing
    return series.last + nextYPrime;
  }

  /// Simplified parameter estimation for ARIMA(1, 1, 1) using grid search.
  /// Returns [phi, theta, lastError].
  static List<double> _fitArima111(List<double> series) {
    double bestPhi = 0;
    double bestTheta = 0;
    double minSse = double.infinity;
    double finalLastError = 0;

    // Grid search for Phi and Theta in range [-0.9, 0.9]
    for (double phi = -0.9; phi <= 0.9; phi += 0.2) {
      for (double theta = -0.9; theta <= 0.9; theta += 0.2) {
        double sse = 0;
        double prevError = 0;
        double currentError = 0;

        for (int i = 1; i < series.length; i++) {
          final prediction = phi * series[i - 1] + theta * prevError;
          currentError = series[i] - prediction;
          sse += currentError * currentError;
          prevError = currentError;
        }

        if (sse < minSse) {
          minSse = sse;
          bestPhi = phi;
          bestTheta = theta;
          finalLastError = currentError;
        }
      }
    }

    // Refinement step for best params (optional, but good for accuracy)
    // For brevity and "lightweight" requirement, this 10x10 grid is usually enough for cycle data.

    return [bestPhi, bestTheta, finalLastError];
  }

  // --- Utility Methods ---

  static double _calculateAverage(List<num> data) {
    if (data.isEmpty) return defaultCycleLength.toDouble();
    return data.sum / data.length;
  }

  static double _calculateMedian(List<double> data) {
    if (data.isEmpty) return defaultCycleLength.toDouble();
    final sorted = List<double>.from(data)..sort();
    final n = sorted.length;
    if (n % 2 == 1) {
      return sorted[n ~/ 2];
    } else {
      return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
    }
  }

  static double _calculateIQR(List<double> data) {
    if (data.length < 4) return 0;
    final q1 = _calculatePercentile(data, 25);
    final q3 = _calculatePercentile(data, 75);
    return q3 - q1;
  }

  static double _calculatePercentile(List<double> data, double percentile) {
    if (data.isEmpty) return 0;
    final sorted = List<double>.from(data)..sort();
    final index = (percentile / 100) * (sorted.length - 1);
    final lower = index.floor();
    final upper = index.ceil();
    if (lower == upper) return sorted[lower];
    final weight = index - lower;
    return sorted[lower] * (1 - weight) + sorted[upper] * weight;
  }

  static double _calculateTrimmedMean(List<double> data, double trimPercentage) {
    if (data.isEmpty) return defaultCycleLength.toDouble();
    final sorted = List<double>.from(data)..sort();
    final trimCount = (data.length * trimPercentage).round();
    if (trimCount * 2 >= data.length) return _calculateMedian(data);

    final trimmed = sorted.sublist(trimCount, data.length - trimCount);
    return _calculateAverage(trimmed);
  }

  static double _calculateVariance(List<double> data) {
    if (data.length < 2) return 0;
    final avg = _calculateAverage(data);
    final sumSquaredDiffs = data.map((x) => pow(x - avg, 2)).sum;
    return sumSquaredDiffs / (data.length - 1);
  }
}
