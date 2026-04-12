import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_calendar/calendar_grid.dart';
import '../sheets/unified_logging_sheet.dart';
import '../sheets/day_summary_sheet.dart';
import '../sheets/calendar_legend_sheet.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/symptom_provider.dart';

/// The primary view for the application, featuring an interactive health calendar.
/// 
/// [TrackingCalendarPage] manages the high-level state of the calendar view,
/// including month navigation, day selection, and the triggering of logging sheets.
class TrackingCalendarPage extends StatefulWidget {
  const TrackingCalendarPage({super.key});

  @override
  State<TrackingCalendarPage> createState() => _TrackingCalendarPageState();
}

class _TrackingCalendarPageState extends State<TrackingCalendarPage> {
  /// The month currently being viewed in the calendar.
  DateTime _focusedDay = DateTime.now();

  /// The day currently selected by the user.
  DateTime? _selectedDay;

  /// Prevents multiple sheets from opening simultaneously.
  bool _isSheetOpen = false;

  /// Guards against overlapping "return to today" animations.
  bool _isAnimatingToToday = false;

  /// Whether the calendar is currently showing the current month.
  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _focusedDay.year == now.year && _focusedDay.month == now.month;
  }

  /// Opens the [UnifiedLoggingSheet] for a specific [day].
  /// 
  /// [type] determines whether to default to Daily symptoms or Cycle logging.
  /// This method performs O(1) lookups to pass existing logs to the sheet,
  /// ensuring a smooth transition without redundant loading states.
  void _showUnifiedSheet(DateTime day, {LoggingType type = LoggingType.daily}) async {
    if (_isSheetOpen) return;
    
    final symptomProvider = context.read<SymptomProvider>();
    final cycleProvider = context.read<CycleProvider>();

    // O(1) Lookups using pre-indexed maps from providers.
    final existingSymptom = symptomProvider.getSymptomByDate(day);
    final existingCycle = cycleProvider.getEventByDate(day);

    _isSheetOpen = true;
    try {
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => UnifiedLoggingSheet(
          selectedDay: day,
          symptomLog: existingSymptom,
          cycleLog: existingCycle,
          initialType: type,
        ),
      );
    } finally {
      // Ensure the guard is reset even if the sheet is dismissed via gesture.
      _isSheetOpen = false;
    }
  }

  /// Navigates to the next month with haptic feedback.
  void _onNextMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    });
  }

  /// Navigates to the previous month with haptic feedback.
  void _onPrevMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    });
  }

  /// Animates the calendar back to the current month with a "flip through months" effect.
  ///
  /// Steps one month at a time toward the current date with a 120ms interval 
  /// per step, providing satisfying visual and haptic feedback. If the user 
  /// is more than 3 months away, it skips directly to avoid a tedious wait.
  void _returnToToday() {
    if (_isCurrentMonth || _isAnimatingToToday) return;

    final now = DateTime.now();
    final targetMonth = DateTime(now.year, now.month);
    
    // Calculate total months to traverse.
    final monthDiff = (now.year - _focusedDay.year) * 12 + (now.month - _focusedDay.month);
    
    // If more than 3 months away, skip directly with a single smooth setState.
    if (monthDiff.abs() > 3) {
      HapticFeedback.mediumImpact();
      setState(() => _focusedDay = targetMonth);
      return;
    }

    // Animated step-through for nearby months.
    _isAnimatingToToday = true;
    final direction = monthDiff > 0 ? 1 : -1;
    
    Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + direction);
      });
      HapticFeedback.selectionClick();

      // Check if we've arrived.
      if (_focusedDay.year == targetMonth.year && _focusedDay.month == targetMonth.month) {
        timer.cancel();
        _isAnimatingToToday = false;
      }
    });
  }

  /// Displays the calendar legend sheet to explain icons and colors.
  void _showLegend() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CalendarLegendSheet(),
    );
  }

  /// Displays a summary of data for the selected [day].
  /// 
  /// This summary acts as a mid-level navigation point between the calendar
  /// and the detailed logging sheets.
  void _showDaySummary(DateTime day) async {
    final symptomProvider = context.read<SymptomProvider>();
    final cycleProvider = context.read<CycleProvider>();

    final existingSymptom = symptomProvider.getSymptomByDate(day);
    final existingCycle = cycleProvider.getEventByDate(day);
    
    // Predictions are retrieved directly from the Provider's centralized logic.
    final isPredBleeding = cycleProvider.isPredictedBleeding(day);
    final isPredFertility = cycleProvider.isPredictedFertility(day);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DaySummarySheet(
        selectedDay: day,
        isPredictedBleeding: isPredBleeding,
        isPredictedFertility: isPredFertility,
        symptomLog: existingSymptom,
        cycleLog: existingCycle,
        onEditDailyLog: () => _showUnifiedSheet(day, type: LoggingType.daily),
        onEditPeriodLog: () => _showUnifiedSheet(day, type: LoggingType.cycle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600), // Clean on tablets too
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center vertically on tall screens
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                      // Stack allows overlaying the "Today" FAB on the calendar card.
                      child: Stack(
                        children: [
                          AnimatedContainer(
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
                                // Custom Month Header with Navigation Controls
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.chevron_left_rounded, color: primary),
                                      onPressed: _onPrevMonth,
                                    ),
                                    Row(
                                      children: [
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
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: Icon(Icons.info_outline_rounded, color: primary.withValues(alpha: 0.5), size: 18),
                                          onPressed: _showLegend,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.chevron_right_rounded, color: primary),
                                      onPressed: _onNextMonth,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // PERFORMANCE OPTIMIZATION: Consumer2 ensures that only the grid 
                                // rebuilds when health or cycle data changes, keeping the rest of 
                                // the page static and snappy.
                                Consumer2<CycleProvider, SymptomProvider>(
                                  builder: (context, cycleProvider, symptomProvider, _) {
                                    return CustomCalendarGrid(
                                      focusedDay: _focusedDay,
                                      selectedDay: _selectedDay,
                                      calendarEventMap: cycleProvider.calendarEventMap,
                                      symptomMap: symptomProvider.symptomMap,
                                      predictedNextPeriod: cycleProvider.predictedNextPeriod,
                                      predictedFertilityDates: cycleProvider.predictedFertilityDates,
                                      onDaySelected: (selectedDay) {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _selectedDay = selectedDay;
                                          _focusedDay = selectedDay; 
                                        });
                                        _showDaySummary(selectedDay);
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // "Return to Today" Glassmorphic Mini-FAB
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: IgnorePointer(
                              ignoring: _isCurrentMonth,
                              child: AnimatedOpacity(
                                opacity: _isCurrentMonth ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: AppTheme.glassFabDecoration(isDark: isDark),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: _returnToToday,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.today_rounded, color: primary, size: 18),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'TODAY',
                                                  style: TextStyle(
                                                    color: primary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 1,
                                                    fontFamily: AppTheme.fontFamily,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Primary Quick-Action Logging Buttons
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
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  }
}
