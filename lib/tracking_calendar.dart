import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class TrackingCalendar extends StatefulWidget {
  const TrackingCalendar({super.key});

  @override
  TrackingCalendarState createState() => TrackingCalendarState();
}

class TrackingCalendarState extends State<TrackingCalendar> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TableCalendar(
        headerStyle: const HeaderStyle(formatButtonVisible: false,),
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31), focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            // Call `setState()` when updating the selected day
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onPageChanged: (focusedDay) {
          // No need to call `setState()` here
          _focusedDay = focusedDay;
        },
      ),
    );
  }

}
