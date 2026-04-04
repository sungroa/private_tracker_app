import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_calendar/calendar_grid.dart';
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
      _symptomLogs = EncryptedStorageService.instance.getSymptomLogs();
      _cycleLogs = EncryptedStorageService.instance.getCycleLogs();
      _symptomMap = {
        for (var log in _symptomLogs)
          DateTime(log.date.year, log.date.month, log.date.day): log
      };
    });
  }

  void _showSymptomSheet(DateTime day) async {
    if (_isSheetOpen) return;
    final existing = _symptomLogs.firstWhere(
      (log) => DateUtils.isSameDay(log.date, day),
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

  void _onNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
      _loadLogs();
    });
  }

  void _onPrevMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
      _loadLogs();
    });
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
                  cycleLogs: _cycleLogs,
                  symptomMap: _symptomMap,
                  onDaySelected: (selectedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = selectedDay; // Optional: change focus
                    });
                    _showSymptomSheet(selectedDay);
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
