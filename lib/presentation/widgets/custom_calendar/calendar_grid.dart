import 'package:flutter/material.dart';
import 'calendar_day_cell.dart';
import '../../../domain/models/cycle_log.dart';

class CustomCalendarGrid extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<CycleEvent> cycleLogs;
  final Map<DateTime, SymptomLog> symptomMap;
  final DateTime? predictedNextPeriod;
  final List<DateTime> predictedFertilityDates;
  final Function(DateTime) onDaySelected;

  const CustomCalendarGrid({
    super.key,
    required this.focusedDay,
    this.selectedDay,
    required this.cycleLogs,
    required this.symptomMap,
    this.predictedNextPeriod,
    this.predictedFertilityDates = const [],
    required this.onDaySelected,
  });

  bool _isPredictedBleeding(DateTime day) {
    if (predictedNextPeriod == null) return false;
    final dateOnly = DateUtils.dateOnly(day);
    final start = DateUtils.dateOnly(predictedNextPeriod!);
    // Assume 4 days of predicted bleeding if not specified
    final end = start.add(const Duration(days: 4));
    return (dateOnly.isAtSameMomentAs(start) || (dateOnly.isAfter(start) && dateOnly.isBefore(end.add(const Duration(days: 1)))));
  }

  bool _isPredictedFertility(DateTime day) {
    final dateOnly = DateUtils.dateOnly(day);
    return predictedFertilityDates.any((d) => DateUtils.isSameDay(d, dateOnly));
  }

  bool _isBleeding(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    for (var log in cycleLogs) {
      final start = DateTime(log.startDate.year, log.startDate.month, log.startDate.day);
      DateTime end;
      if (log.endDate != null) {
        end = DateTime(log.endDate!.year, log.endDate!.month, log.endDate!.day);
      } else {
        end = start.add(const Duration(days: 4));
      }
      if (dateOnly.isAtSameMomentAs(start) || (dateOnly.isAfter(start) && dateOnly.isBefore(end.add(const Duration(days: 1))))) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(focusedDay.year, focusedDay.month);
    final firstDayOffset = DateUtils.firstDayOffset(focusedDay.year, focusedDay.month, MaterialLocalizations.of(context));
    
    // Total cells to show (padding to full weeks)
    final totalCells = (daysInMonth + firstDayOffset <= 35) ? 35 : 42;

    return Column(
      children: [
        // Weekday Headers
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
              // Optionally show days from prev/next month in grey
              final date = DateTime(focusedDay.year, focusedDay.month, dayNumber);
              return CalendarDayCell(
                date: date,
                isOutsideMonth: true,
                onTap: () => onDaySelected(date),
              );
            }

            final currentDay = DateTime(focusedDay.year, focusedDay.month, dayNumber);
            final bleeding = _isBleeding(currentDay);
            final predictedBleeding = _isPredictedBleeding(currentDay);
            final predictedFertility = _isPredictedFertility(currentDay);
            
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
              symptomLog: symptomMap[currentDay],
              onTap: () => onDaySelected(currentDay),
            );
          },
        ),
      ],
    );
  }
}

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
