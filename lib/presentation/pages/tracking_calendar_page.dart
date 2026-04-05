import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    HapticFeedback.lightImpact();
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    });
  }

  void _onPrevMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 32).copyWith(
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Custom Month Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left_rounded, color: primary),
                      onPressed: _onPrevMonth,
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase(),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 1.5,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right_rounded, color: primary),
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
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = selectedDay; 
                    });
                    _showUnifiedSheet(selectedDay);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _showUnifiedSheet(_selectedDay ?? DateTime.now(), type: LoggingType.cycle);
                    },
                    icon: const Icon(Icons.water_drop_rounded, size: 20),
                    label: const Text("PERIOD", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: isDark ? [AppTheme.primaryDarkColor, AppTheme.accentDarkColor] : [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _showUnifiedSheet(_selectedDay ?? DateTime.now());
                    },
                    icon: const Icon(Icons.add_rounded, size: 22),
                    label: const Text("DAILY LOG", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: isDark ? AppTheme.backgroundDarkColor : Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
