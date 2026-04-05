import 'package:flutter/foundation.dart';
import '../../domain/trends_calculator.dart';
import 'cycle_provider.dart';
import 'symptom_provider.dart';

class TrendsProvider extends ChangeNotifier {
  TrendData? _trendData;

  TrendData? get trendData => _trendData;

  void update(CycleProvider cycleProvider, SymptomProvider symptomProvider) {
    _trendData = TrendsCalculator.calculateTrends(
      cycleProvider.cycleEvents,
      symptomProvider.symptomLogs,
    );
    notifyListeners();
  }
}
