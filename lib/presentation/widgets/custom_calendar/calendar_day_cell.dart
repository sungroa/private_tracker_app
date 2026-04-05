import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../../domain/models/cycle_log.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final bool isBleeding;
  final bool isPredictedBleeding;
  final bool isPredictedFertility;
  final bool isStartOfSpan;
  final bool isEndOfSpan;
  final bool isSelected;
  final bool isToday;
  final bool isOutsideMonth;
  final SymptomLog? symptomLog;
  final VoidCallback onTap;

  const CalendarDayCell({
    super.key,
    required this.date,
    this.isBleeding = false,
    this.isPredictedBleeding = false,
    this.isPredictedFertility = false,
    this.isStartOfSpan = false,
    this.isEndOfSpan = false,
    this.isSelected = false,
    this.isToday = false,
    this.isOutsideMonth = false,
    this.symptomLog,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Span Background (Actual Bleeding)
          if (isBleeding)
            Container(
              margin: EdgeInsets.only(
                top: 4,
                bottom: 4,
                left: isStartOfSpan ? 4 : 0,
                right: isEndOfSpan ? 4 : 0,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.horizontal(
                  left: isStartOfSpan ? const Radius.circular(20) : Radius.zero,
                  right: isEndOfSpan ? const Radius.circular(20) : Radius.zero,
                ),
              ),
            ),

          // Predicted Bleeding Background
          if (isPredictedBleeding && !isBleeding)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
            ),

          // Day Circle/Highlight
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday && !isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
              border: isSelected
                  ? Border.all(color: AppTheme.primaryColor, width: 2)
                  : isToday
                      ? Border.all(color: AppTheme.primaryColor, width: 1)
                      : null,
              boxShadow: isSelected 
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : isOutsideMonth
                          ? Colors.grey[400]
                          : isBleeding 
                              ? Colors.redAccent
                              : Colors.black87,
                  fontWeight: isToday || isSelected || isBleeding ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),

          // Prediction & Symptom Markers
          Positioned(
            bottom: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPredictedFertility)
                  _buildMarker(Icons.circle, Colors.indigoAccent.withValues(alpha: 0.5), size: 6),
                if (symptomLog != null) ...[
                  if (symptomLog!.symptoms.isNotEmpty || symptomLog!.moodRating != 3)
                    _buildMarker(Icons.brightness_1, Colors.purpleAccent, size: 4),
                  if (symptomLog!.lhTestPositive == true)
                    _buildMarker(Icons.star_rounded, Colors.pinkAccent, size: 8),
                  if (symptomLog!.basalBodyTemperature != null)
                    _buildMarker(Icons.thermostat_rounded, Colors.orangeAccent, size: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(IconData icon, Color color, {double size = 6}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}
