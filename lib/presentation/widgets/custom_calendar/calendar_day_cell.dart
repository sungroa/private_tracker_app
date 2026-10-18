import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:private_tracker_app/domain/models/symptom_log.dart';

import '../../theme/app_theme.dart';

/// An individual day cell within the [CustomCalendarGrid].
///
/// Renders a single calendar day with layered visual states:
/// 1. **Span background** — pill-shaped highlight for consecutive bleeding days.
/// 2. **Prediction ring** — dashed-style border for predicted bleeding.
/// 3. **Day circle** — animated glass orb showing Today/Selected state.
/// 4. **Marker dots** — fertility, symptom, LH, and BBT indicators.
///
/// This widget is a [StatefulWidget] to support a tap-scale micro-animation
/// that provides premium tactile feedback when the user selects a day.
class CalendarDayCell extends StatefulWidget {
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

  @override
  State<CalendarDayCell> createState() => _CalendarDayCellState();
}

class _CalendarDayCellState extends State<CalendarDayCell> {
  /// Drives the scale micro-animation on tap.
  bool _isPressed = false;

  String _buildSemanticLabel() {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(widget.date);
    final buffer = StringBuffer(dateStr);
    if (widget.isToday) {
      buffer.write(', Today');
    }
    if (widget.isSelected) {
      buffer.write(', Selected');
    }
    if (widget.isOutsideMonth) {
      buffer.write(', Outside current month');
    }
    if (widget.isBleeding) {
      buffer.write(', Bleeding logged');
    }
    if (widget.isPredictedBleeding) {
      buffer.write(', Predicted period');
    }
    if (widget.isPredictedFertility) {
      buffer.write(', Predicted fertility window');
    }
    if (widget.symptomLog != null) {
      final log = widget.symptomLog!;
      if (log.symptoms.isNotEmpty) {
        buffer.write(', Symptoms: ${log.symptoms.join(", ")}');
      }
      if (log.moodRating != 3) {
        buffer.write(', Mood: ${_getMoodLabel(log.moodRating)}');
      }
      if (log.lhTestPositive == true) {
        buffer.write(', Positive LH test');
      }
      if (log.basalBodyTemperature != null) {
        buffer.write(', Temperature: ${log.basalBodyTemperature}°F');
      }
    }
    return buffer.toString();
  }

  String _getMoodLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Really struggling';
      case 2:
        return 'Feeling down';
      case 3:
        return 'Doing okay';
      case 4:
        return 'Feeling good';
      case 5:
        return 'Excellent mood';
      default:
        return 'Doing okay';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return Semantics(
      button: true,
      selected: widget.isSelected,
      excludeSemantics: true,
      label: _buildSemanticLabel(),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutBack,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Span Background (Actual Bleeding)
              if (widget.isBleeding)
                Container(
                  margin: EdgeInsets.only(
                    top: 4,
                    bottom: 4,
                    left: widget.isStartOfSpan ? 4 : 0,
                    right: widget.isEndOfSpan ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.horizontal(
                      left: widget.isStartOfSpan ? const Radius.circular(20) : Radius.zero,
                      right: widget.isEndOfSpan ? const Radius.circular(20) : Radius.zero,
                    ),
                  ),
                ),

              // Predicted Bleeding Background
              if (widget.isPredictedBleeding && !widget.isBleeding)
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

              // Day Circle/Highlight (Animated Glass Orb)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: widget.isSelected ? 40 : 36,
                height: widget.isSelected ? 40 : 36,
                decoration: widget.isSelected
                    ? AppTheme.calendarSelectionDecoration(isDark: isDark)
                    : BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isToday
                            ? primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        border: widget.isToday
                            ? Border.all(color: primary.withValues(alpha: 0.7), width: 1.5)
                            : null,
                        boxShadow: widget.isToday
                            ? [BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 6)]
                            : null,
                      ),
                child: Center(
                  child: Text(
                    '${widget.date.day}',
                    style: TextStyle(
                      color: widget.isSelected
                          ? (isDark ? Colors.white : AppTheme.primaryColor)
                          : widget.isOutsideMonth
                          ? (isDark ? Colors.white38 : Colors.grey[500])
                          : widget.isBleeding
                          ? Colors.redAccent
                          : (isDark ? Colors.white : Colors.black87),
                      fontWeight: widget.isToday || widget.isSelected || widget.isBleeding
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: widget.isSelected ? 15 : 14,
                      fontFamily: AppTheme.fontFamily,
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
                    if (widget.isPredictedFertility)
                      _buildMarker(
                        Icons.circle,
                        Colors.indigoAccent.withValues(alpha: 0.5),
                        size: 6,
                      ),
                    if (widget.symptomLog != null) ...[
                      if (widget.symptomLog!.symptoms.isNotEmpty ||
                          widget.symptomLog!.moodRating != 3)
                        _buildMarker(Icons.brightness_1, Colors.purpleAccent, size: 4),
                      if (widget.symptomLog!.lhTestPositive == true)
                        _buildMarker(Icons.star_rounded, Colors.pinkAccent, size: 8),
                      if (widget.symptomLog!.basalBodyTemperature != null)
                        _buildMarker(Icons.thermostat_rounded, Colors.orangeAccent, size: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarker(IconData icon, Color color, {double size = 6}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Icon(icon, size: size, color: color),
    );
  }
}
