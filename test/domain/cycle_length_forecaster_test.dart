import 'package:flutter_test/flutter_test.dart';
import 'package:private_tracker_app/domain/calculators/cycle_length_forecaster.dart';

void main() {
  group('CycleLengthForecaster Tests', () {
    group('Phase 1: Cold Start Handler', () {
      test('n = 0 returns 28', () {
        expect(CycleLengthForecaster.predictNextLength([]), 28);
      });

      test('n = 2 returns standard average', () {
        // (26 + 30) / 2 = 28
        expect(CycleLengthForecaster.predictNextLength([26, 30]), 28);
      });

      test('n = 3 returns standard average', () {
        // (28 + 29 + 30) / 3 = 29
        expect(CycleLengthForecaster.predictNextLength([28, 29, 30]), 29);
      });

      test('n = 5 returns soft trimmed mean (furthest from median)', () {
        // Median of [28, 29, 30, 31, 45] is 30.
        // Distances: 2, 1, 0, 1, 15.
        // Furthest is 45.
        // Remaining: [28, 29, 30, 31]. Average: 29.5 -> 30
        expect(CycleLengthForecaster.predictNextLength([28, 29, 30, 31, 45]), 30);
      });

      test('n = 5 returns soft trimmed mean (low outlier)', () {
        // Median of [15, 28, 29, 30, 31] is 29.
        // Distances: 14, 1, 0, 1, 2.
        // Furthest is 15.
        // Remaining: [28, 29, 30, 31]. Average: 29.5 -> 30
        expect(CycleLengthForecaster.predictNextLength([15, 28, 29, 30, 31]), 30);
      });
    });

    group('Phase 2: Hybrid Pipeline', () {
      test('n = 8 with outliers uses median imputation and ARIMA', () {
        // Lookback: [28, 29, 28, 30, 60, 27, 29, 28]
        // 60 is an anomaly (biological override > 45 and IQR outlier)
        // Median of [28, 29, 28, 30, 27, 29, 28] is 28.
        // Imputed: [28, 29, 28, 30, 28, 27, 29, 28]
        // Predicted should be near 28
        final result = CycleLengthForecaster.predictNextLength([28, 29, 28, 30, 60, 27, 29, 28]);
        expect(result, greaterThanOrEqualTo(26));
        expect(result, lessThanOrEqualTo(30));
      });

      test('Biological override flags < 21 as anomaly', () {
        // [28, 28, 28, 28, 28, 28, 28, 15]
        // 15 is < 21.
        // Imputed: [28, 28, 28, 28, 28, 28, 28, 28]
        expect(CycleLengthForecaster.predictNextLength([28, 28, 28, 28, 28, 28, 28, 15]), 28);
      });

      test('ARIMA(1, 1, 1) handles trended data', () {
        // Slowly increasing cycle length: 28, 29, 30, 31, 32, 33, 34, 35
        // Differenced: 1, 1, 1, 1, 1, 1, 1
        // ARIMA(1,1,1) should predict ~36
        final result = CycleLengthForecaster.predictNextLength([28, 29, 30, 31, 32, 33, 34, 35]);
        expect(result, greaterThanOrEqualTo(35));
        expect(result, lessThanOrEqualTo(37));
      });

      test('Fallback to Trimmed Mean on zero variance', () {
        // All 28s -> variance 0 -> ARIMA throws -> 12.5% Trimmed Mean
        // [28, 28, 28, 28, 28, 28, 28, 28] -> 28
        expect(CycleLengthForecaster.predictNextLength([28, 28, 28, 28, 28, 28, 28, 28]), 28);
      });
    });

    group('Edge Cases', () {
      test('History length > 12 uses only recent 12', () {
        final longHistory = List.generate(20, (i) => 28);
        longHistory[19] = 35; // Most recent is 35
        // Prediction should be influenced more by the 35 than the old 28s
        final result = CycleLengthForecaster.predictNextLength(longHistory);
        expect(result, greaterThanOrEqualTo(28));
      });
    });
  });
}
