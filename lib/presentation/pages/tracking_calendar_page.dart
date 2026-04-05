import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_calendar/calendar_grid.dart';
import '../sheets/unified_logging_sheet.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/symptom_provider.dart';
import '../../domain/models/cycle_log.dart';

class TrackingCalendarPage extends StatefulWidget {
  const TrackingCalendarPage({super.key});

  @override
  State<TrackingCalendarPage> createState() => _TrackingCalendarPageState();
}

class _TrackingCalendarPageState extends State<TrackingCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isSheetOpen = false;

   void _showUnifiedSheet(DateTime day, {LoggingType type = LoggingType.daily}) async {
    if (_isSheetOpen) return;
    
    final symptomLogs = context.read<SymptomProvider>().symptomLogs;
    final cycleEvents = context.read<CycleProvider>().cycleEvents;

    // Find SymptomLog
    SymptomLog? existingSymptom;
    existingSymptom = symptomLogs.cast<SymptomLog?>().firstWhere(
      (log) => DateUtils.isSameDay(log!.date, day),
      orElse: () => null,
    );

    // Find CycleEvent
    CycleEvent? existingCycle;
    for (var log in cycleEvents) {
      final start = DateUtils.dateOnly(log.startDate);
      final end = log.endDate != null ? DateUtils.dateOnly(log.endDate!) : start.add(const Duration(days: 4));
      final target = DateUtils.dateOnly(day);

      if ((target.isAtSameMomentAs(start) || target.isAfter(start)) && 
          (target.isAtSameMomentAs(end) || target.isBefore(end))) {
        existingCycle = log;
        break;
      }
    }

    _isSheetOpen = true;
    try {
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => UnifiedLoggingSheet(
          selectedDay: day,
          existingSymptomLog: existingSymptom,
          existingCycleLog: existingCycle,
          initialType: type,
        ),
      );
    } finally {
      _isSheetOpen = false;
    }
  }

  void _onNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    });
  }

  void _onPrevMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cycleProvider = context.watch<CycleProvider>();
    final cycleEvents = cycleProvider.cycleEvents;
    final predictedNextPeriod = cycleProvider.predictedNextPeriod;
    final predictedFertilityDates = cycleProvider.predictedFertilityDates;
    
    final symptomLogs = context.watch<SymptomProvider>().symptomLogs;
    final symptomMap = {
      for (var log in symptomLogs)
        DateTime(log.date.year, log.date.month, log.date.day): log
    };

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: AppTheme.glassDecoration(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Custom Month Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _onPrevMonth,
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_focusedDay),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _onNextMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomCalendarGrid(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  cycleLogs: cycleEvents,
                  symptomMap: symptomMap,
                  predictedNextPeriod: predictedNextPeriod,
                  predictedFertilityDates: predictedFertilityDates,
                  onDaySelected: (selectedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = selectedDay; // Optional: change focus
                    });
                    _showUnifiedSheet(selectedDay);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUnifiedSheet(_selectedDay ?? DateTime.now(), type: LoggingType.cycle),
                  icon: const Icon(Icons.water_drop_outlined),
                  label: const Text("Log Cycle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUnifiedSheet(_selectedDay ?? DateTime.now()),
                  icon: const Icon(Icons.add),
                  label: const Text("Daily Log"),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
