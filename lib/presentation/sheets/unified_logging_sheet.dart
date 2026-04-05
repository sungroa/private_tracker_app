import 'package:flutter/material.dart';
import 'symptom_logging_sheet.dart';
import 'cycle_logging_sheet.dart';
import '../../domain/models/cycle_log.dart';
import '../theme/app_theme.dart';

enum LoggingType { daily, cycle }

class UnifiedLoggingSheet extends StatefulWidget {
  final DateTime selectedDay;
  final SymptomLog? existingSymptomLog;
  final CycleEvent? existingCycleLog;
  final LoggingType initialType;

  const UnifiedLoggingSheet({
    super.key,
    required this.selectedDay,
    this.existingSymptomLog,
    this.existingCycleLog,
    this.initialType = LoggingType.daily,
  });

  @override
  State<UnifiedLoggingSheet> createState() => _UnifiedLoggingSheetState();
}

class _UnifiedLoggingSheetState extends State<UnifiedLoggingSheet> {
  late LoggingType _currentType;

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassDecoration(color: Colors.white).copyWith(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Switcher Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SwitcherButton(
                      label: "Daily Log",
                      isSelected: _currentType == LoggingType.daily,
                      onTap: () => setState(() => _currentType = LoggingType.daily),
                      icon: Icons.edit_note_rounded,
                    ),
                  ),
                  Expanded(
                    child: _SwitcherButton(
                      label: "Log Cycle",
                      isSelected: _currentType == LoggingType.cycle,
                      onTap: () => setState(() => _currentType = LoggingType.cycle),
                      icon: Icons.water_drop_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Flexible(
            child: _currentType == LoggingType.daily
                ? SymptomLoggingSheet(
                    selectedDay: widget.selectedDay,
                    existingLog: widget.existingSymptomLog,
                    isEmbedded: true,
                  )
                : CycleLoggingSheet(
                    selectedDay: widget.selectedDay,
                    existingEvent: widget.existingCycleLog,
                    isEmbedded: true,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SwitcherButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const _SwitcherButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
