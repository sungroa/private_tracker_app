import 'package:flutter/material.dart';
import 'calendar_day_cell.dart';
import '../../../domain/models/cycle_log.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';

/// A custom grid-based calendar visualization.
/// 
/// [CustomCalendarGrid] renders a monthly view of days, including weekday headers.
/// it is responsible for calculating the grid layout (offsets, total cells) and
/// mapping domain data ([calendarEventMap], [symptomMap]) to individual [CalendarDayCell]s.
class CustomCalendarGrid extends StatelessWidget {
  /// The month/year currently focused by the calendar.
  final DateTime focusedDay;

  /// The day currently selected by the user.
  final DateTime? selectedDay;

  /// Pre-indexed map of bleeding events for O(1) cell lookups.
  final Map<String, CycleLog> calendarEventMap;

  /// Pre-indexed map of health/symptom logs for O(1) cell lookups.
  final Map<String, SymptomLog> symptomMap;

  /// Estimated start date of the next period.
  final DateTime? predictedNextPeriod;

  /// Projected fertile days for the current cycle.
  final List<DateTime> predictedFertilityDates;

  /// Callback triggered when a user taps a specific day cell.
  final Function(DateTime) onDaySelected;

  const CustomCalendarGrid({
    super.key,
    required this.focusedDay,
    this.selectedDay,
    required this.calendarEventMap,
    required this.symptomMap,
    this.predictedNextPeriod,
    this.predictedFertilityDates = const [],
    required this.onDaySelected,
  });

  /// Standardizes date keys for map lookups.
  String _formatKey(DateTime date) => 
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  /// Local check if a day is within the predicted bleeding window.
  bool _isPredictedBleeding(DateTime day) {
    if (predictedNextPeriod == null) return false;
    final dateOnly = DateTime(day.year, day.month, day.day);
    final start = DateTime(predictedNextPeriod!.year, predictedNextPeriod!.month, predictedNextPeriod!.day);
    final end = start.add(const Duration(days: 4));
    return (dateOnly.isAtSameMomentAs(start) || (dateOnly.isAfter(start) && dateOnly.isBefore(end.add(const Duration(days: 1)))));
  }

  /// Local check if a day is within the predicted fertility dates.
  bool _isPredictedFertility(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return predictedFertilityDates.any((d) => 
      d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day);
  }

  /// Checks if there is an active menstruation log recorded for this day.
  bool _isBleeding(DateTime day) {
    return calendarEventMap.containsKey(_formatKey(day));
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate grid dimensions
    final daysInMonth = DateUtils.getDaysInMonth(focusedDay.year, focusedDay.month);
    
    // Determine the weekday offset for the 1st of the month.
    final firstDayOffset = DateUtils.firstDayOffset(focusedDay.year, focusedDay.month, MaterialLocalizations.of(context));
    
    // Ensure the grid is always 5 or 6 full rows (35 or 42 cells) to prevent jitter during month transitions.
    final totalCells = (daysInMonth + firstDayOffset <= 35) ? 35 : 42;

    return Column(
      children: [
        // Weekday Headers (S M T W T F S)
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _WeekdayHeader('S'),
            _WeekdayHeader('M'),
            _WeekdayHeader('T'),
            _WeekdayHeader('W'),
            _WeekdayHeader('T'),
            _WeekdayHeader('F'),
            _WeekdayHeader('S'),
          ],
        ),
        const SizedBox(height: 8),
        
        // The Calendar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Handled by parent ListView
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNumber = index - firstDayOffset + 1;
            final isInside = dayNumber > 0 && dayNumber <= daysInMonth;
            
            if (!isInside) {
              // Days belonging to the previous or next month (rendered in a subtle grey)
              final date = DateTime(focusedDay.year, focusedDay.month, dayNumber);
              return CalendarDayCell(
                date: date,
                isOutsideMonth: true,
                onTap: () => onDaySelected(date),
              );
            }

            final currentDay = DateTime(focusedDay.year, focusedDay.month, dayNumber);
            
            // 2. Resolve visualization states
            final bleeding = _isBleeding(currentDay);
            final predictedBleeding = _isPredictedBleeding(currentDay);
            final predictedFertility = _isPredictedFertility(currentDay);
            
            // Calculate span boundaries for the "pill-shaped" multi-day bleeding indicator.
            final prevBleeding = _isBleeding(currentDay.subtract(const Duration(days: 1)));
            final nextBleeding = _isBleeding(currentDay.add(const Duration(days: 1)));

            return CalendarDayCell(
              date: currentDay,
              isBleeding: bleeding,
              isPredictedBleeding: predictedBleeding,
              isPredictedFertility: predictedFertility,
              isStartOfSpan: bleeding && !prevBleeding,
              isEndOfSpan: bleeding && !nextBleeding,
              isSelected: selectedDay != null && 
                  selectedDay!.year == currentDay.year &&
                  selectedDay!.month == currentDay.month &&
                  selectedDay!.day == currentDay.day,
              isToday: DateUtils.isSameDay(DateTime.now(), currentDay),
              symptomLog: symptomMap[_formatKey(currentDay)],
              onTap: () => onDaySelected(currentDay),
            );
          },
        ),
      ],
    );
  }
}

/// A simple header widget for a single weekday initial.
class _WeekdayHeader extends StatelessWidget {
  final String label;
  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
