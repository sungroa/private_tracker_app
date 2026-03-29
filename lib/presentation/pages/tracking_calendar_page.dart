import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_theme.dart';
import '../sheets/symptom_logging_sheet.dart';
import '../sheets/cycle_logging_sheet.dart';
import '../../data/storage/encrypted_storage_service.dart';
import '../../domain/models/cycle_log.dart';

class TrackingCalendarPage extends StatefulWidget {
  const TrackingCalendarPage({super.key});

  @override
  State<TrackingCalendarPage> createState() => _TrackingCalendarPageState();
}

class _TrackingCalendarPageState extends State<TrackingCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<SymptomLog> _symptomLogs = [];
  List<CycleLog> _cycleLogs = [];
  Map<DateTime, SymptomLog> _symptomMap = {};
  bool _isSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _symptomLogs = EncryptedStorageService.getSymptomLogs();
      _cycleLogs = EncryptedStorageService.getCycleLogs();
      _symptomMap = {
        for (var log in _symptomLogs)
          DateTime(log.date.year, log.date.month, log.date.day): log
      };
    });
  }

  void _showSymptomSheet(DateTime day) async {
    if (_isSheetOpen) return;
    final existing = _symptomLogs.firstWhere(
      (log) => isSameDay(log.date, day),
      orElse: () => SymptomLog(date: day, symptoms: [], moodRating: 3),
    );

    _isSheetOpen = true;
    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SymptomLoggingSheet(
          selectedDay: day,
          existingLog: existing.symptoms.isEmpty ? null : existing,
        ),
      );

      if (result == true) _loadLogs();
    } finally {
      _isSheetOpen = false;
    }
  }

  void _showCycleSheet() async {
    if (_isSheetOpen) return;
    _isSheetOpen = true;
    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CycleLoggingSheet(
          selectedDay: _selectedDay ?? DateTime.now(),
        ),
      );

      if (result == true) _loadLogs();
    } finally {
      _isSheetOpen = false;
    }
  }

  bool _isPeriodDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    for (var log in _cycleLogs) {
      final start = DateTime(log.startDate.year, log.startDate.month, log.startDate.day);
      DateTime end;
      if (log.endDate != null) {
        end = DateTime(log.endDate!.year, log.endDate!.month, log.endDate!.day);
      } else {
        // Assume 5 days if no end date yet for visual purposes
        end = start.add(const Duration(days: 4));
      }
      if (dateOnly.compareTo(start) >= 0 && dateOnly.compareTo(end) <= 0) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: AppTheme.glassDecoration(),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _showSymptomSheet(selectedDay);
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                _loadLogs();
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final checkDate = DateTime(date.year, date.month, date.day);
                  final log = _symptomMap[checkDate];
                  final isPeriod = _isPeriodDay(checkDate);

                  return Stack(
                    children: [
                      if (isPeriod)
                        Positioned(
                          bottom: 1,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      if (log != null && (log.symptoms.isNotEmpty || log.moodRating != 3))
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (log != null && log.lhTestPositive == true)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Icon(
                            Icons.star_rounded,
                            size: 10,
                            color: Colors.pinkAccent[400],
                          ),
                        ),
                      if (log != null && log.basalBodyTemperature != null)
                        Positioned(
                          bottom: 6,
                          right: 4,
                          child: Icon(
                            Icons.device_thermostat_rounded,
                            size: 10,
                            color: Colors.orangeAccent[700],
                          ),
                        ),
                    ],
                  );
                },
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 1),
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: const TextStyle(color: Colors.black87),
                weekendTextStyle: const TextStyle(color: Colors.redAccent),
              ),
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
                  onPressed: _showCycleSheet,
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
                  onPressed: () => _showSymptomSheet(_selectedDay ?? DateTime.now()),
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
