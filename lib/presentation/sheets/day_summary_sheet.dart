import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/symptom_log.dart';
import '../theme/app_theme.dart';

class DaySummarySheet extends StatelessWidget {
  final DateTime selectedDay;
  final bool isPredictedBleeding;
  final bool isPredictedFertility;
  final SymptomLog? existingSymptomLog;
  final CycleEvent? existingCycleLog;
  final VoidCallback onEditDailyLog;
  final VoidCallback onEditPeriodLog;

  const DaySummarySheet({
    super.key,
    required this.selectedDay,
    this.isPredictedBleeding = false,
    this.isPredictedFertility = false,
    this.existingSymptomLog,
    this.existingCycleLog,
    required this.onEditDailyLog,
    required this.onEditPeriodLog,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    final String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(selectedDay);

    final bool hasAnyData = isPredictedBleeding || 
                            isPredictedFertility || 
                            existingCycleLog != null || 
                            existingSymptomLog != null;

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
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
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
            
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (!hasAnyData)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
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
                    const SizedBox(height: 24),
                  ],

                  if (existingCycleLog != null) ...[
                    _SectionHeader(title: "Cycle Data", isDark: isDark),
                    _SummaryItem(
                      icon: Icons.water_drop_rounded,
                      color: Colors.redAccent,
                      title: "Flow Intensity",
                      subtitle: "${existingCycleLog!.flowIntensity} / 5",
                      isDark: isDark,
                    ),
                    if (existingCycleLog!.notes?.isNotEmpty ?? false)
                      _SummaryItem(
                        icon: Icons.notes_rounded,
                        color: Colors.grey,
                        title: "Notes",
                        subtitle: existingCycleLog!.notes,
                        isDark: isDark,
                      ),
                    const SizedBox(height: 24),
                  ],

                  if (existingSymptomLog != null) ...[
                    _SectionHeader(title: "Daily Log", isDark: isDark),
                    if (existingSymptomLog!.symptoms.isNotEmpty)
                      _SummaryItem(
                        icon: Icons.accessibility_new_rounded,
                        color: Colors.purpleAccent,
                        title: "Symptoms",
                        subtitle: existingSymptomLog!.symptoms.join(", "),
                        isDark: isDark,
                      ),
                    if (existingSymptomLog!.moodRating != 3) // Assuming 3 is neutral
                      _SummaryItem(
                        icon: Icons.mood_rounded,
                        color: Colors.teal,
                        title: "Mood",
                        subtitle: _moodToString(existingSymptomLog!.moodRating),
                        isDark: isDark,
                      ),
                    if (existingSymptomLog!.lhTestPositive == true)
                      _SummaryItem(
                        icon: Icons.star_rounded,
                        color: Colors.pinkAccent,
                        title: "Ovulation Test",
                        subtitle: "Positive",
                        isDark: isDark,
                      ),
                    if (existingSymptomLog!.basalBodyTemperature != null)
                      _SummaryItem(
                        icon: Icons.thermostat_rounded,
                        color: Colors.orangeAccent,
                        title: "Temperature",
                        subtitle: "${existingSymptomLog!.basalBodyTemperature}°",
                        isDark: isDark,
                      ),
                    const SizedBox(height: 24),
                  ],
                ],
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
                      label: Text(existingCycleLog == null ? "ADD PERIOD" : "EDIT PERIOD"),
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
                      label: Text(existingSymptomLog == null ? "ADD LOG" : "EDIT LOG", style: const TextStyle(fontWeight: FontWeight.w700)),
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

  String _moodToString(int mood) {
    if (mood <= 1) return "Terrible";
    if (mood == 2) return "Bad";
    if (mood == 3) return "Neutral";
    if (mood == 4) return "Good";
    return "Excellent";
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

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
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool isDark;

  const _SummaryItem({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.isDark,
  });

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
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
