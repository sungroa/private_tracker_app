import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/symptom_log.dart';
import '../theme/app_theme.dart';

class DaySummarySheet extends StatelessWidget {
  const DaySummarySheet({
    super.key,
    required this.selectedDay,
    this.isPredictedBleeding = false,
    this.isPredictedFertility = false,
    this.symptomLog,
    this.cycleLog,
    required this.onEditDailyLog,
    required this.onEditPeriodLog,
  });
  static final DateFormat _fullDateFormatter = DateFormat('EEEE, MMMM d, yyyy');

  final DateTime selectedDay;
  final bool isPredictedBleeding;
  final bool isPredictedFertility;
  final SymptomLog? symptomLog;
  final CycleLog? cycleLog;
  final VoidCallback onEditDailyLog;
  final VoidCallback onEditPeriodLog;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    final String formattedDate = _fullDateFormatter.format(selectedDay);

    final bool hasAnyData =
        isPredictedBleeding || isPredictedFertility || cycleLog != null || symptomLog != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDarkColor : AppTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.primaryColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 8),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!hasAnyData)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            "No data logged or predicted for this day.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 15,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ),
                      ),

                    if (isPredictedBleeding || isPredictedFertility) ...[
                      _SectionHeader(title: "Predictions", isDark: isDark),
                      if (isPredictedBleeding)
                        _SummaryItem(
                          icon: Icons.water_drop_outlined,
                          color: Colors.redAccent,
                          title: "Predicted Period",
                          isDark: isDark,
                        ),
                      if (isPredictedFertility)
                        _SummaryItem(
                          icon: Icons.filter_vintage_rounded,
                          color: Colors.indigoAccent,
                          title: "Fertile Window",
                          isDark: isDark,
                        ),
                      const SizedBox(height: 16),
                    ],

                    if (cycleLog != null) ...[
                      _SectionHeader(title: "Cycle Data", isDark: isDark),
                      _SummaryItem(
                        icon: Icons.water_drop_rounded,
                        color: Colors.redAccent,
                        title: "Flow Intensity",
                        subtitle: cycleLog!.flowIntensityDisplayName,
                        isDark: isDark,
                      ),
                      if (cycleLog!.notes?.isNotEmpty ?? false)
                        _NotesBox(notes: cycleLog!.notes!, isDark: isDark),
                      const SizedBox(height: 16),
                    ],

                    if (symptomLog != null) ...[
                      _SectionHeader(title: "Daily Log", isDark: isDark),
                      if (symptomLog!.symptoms.isNotEmpty)
                        _SummaryItem(
                          icon: Icons.accessibility_new_rounded,
                          color: Colors.purpleAccent,
                          title: "Symptoms",
                          subtitle: symptomLog!.symptomsSummary,
                          isDark: isDark,
                        ),
                      if (symptomLog!.moodRating != SymptomLog.neutralMood)
                        _SummaryItem(
                          icon: Icons.mood_rounded,
                          color: Colors.teal,
                          title: "Mood",
                          subtitle: symptomLog!.moodDisplayName,
                          isDark: isDark,
                        ),
                      if (symptomLog!.lhTestPositive == true)
                        _SummaryItem(
                          icon: Icons.star_rounded,
                          color: Colors.pinkAccent,
                          title: "Ovulation Test",
                          subtitle: "Positive",
                          isDark: isDark,
                        ),
                      if (symptomLog!.basalBodyTemperature != null)
                        _SummaryItem(
                          icon: Icons.thermostat_rounded,
                          color: Colors.orangeAccent,
                          title: "Temperature",
                          subtitle: "${symptomLog!.basalBodyTemperature}°",
                          isDark: isDark,
                        ),
                      if (symptomLog!.notes?.isNotEmpty ?? false)
                        _NotesBox(notes: symptomLog!.notes!, isDark: isDark),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close summary sheet
                        onEditPeriodLog();
                      },
                      icon: const Icon(Icons.water_drop_outlined, size: 20),
                      label: Text(cycleLog == null ? "ADD PERIOD" : "EDIT PERIOD"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close summary sheet
                        onEditDailyLog();
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: Text(
                        symptomLog == null ? "ADD LOG" : "EDIT LOG",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: isDark ? AppTheme.backgroundDarkColor : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _NotesBox extends StatelessWidget {
  const _NotesBox({required this.notes, required this.isDark});
  final String notes;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notes_rounded, size: 16, color: isDark ? Colors.white38 : Colors.black38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notes,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black87,
                fontFamily: AppTheme.fontFamily,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? Colors.white54 : Colors.black54,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.isDark,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (subtitle == null) const SizedBox(height: 8), // Center vertically if no subtitle
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
