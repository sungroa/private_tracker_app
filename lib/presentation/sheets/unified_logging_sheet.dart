import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _onToggle(LoggingType type) {
    if (_currentType == type) return;
    HapticFeedback.lightImpact();
    setState(() => _currentType = type);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.8, // Fixed height for consistency
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
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Switcher Bar (Pill design)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SwitcherButton(
                      label: "Daily Log",
                      isSelected: _currentType == LoggingType.daily,
                      onTap: () => _onToggle(LoggingType.daily),
                      icon: Icons.edit_note_rounded,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _SwitcherButton(
                      label: "Log Cycle",
                      isSelected: _currentType == LoggingType.cycle,
                      onTap: () => _onToggle(LoggingType.cycle),
                      icon: Icons.water_drop_outlined,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _currentType == LoggingType.daily
                  ? SymptomLoggingSheet(
                      key: const ValueKey('daily_sheet'),
                      selectedDay: widget.selectedDay,
                      existingLog: widget.existingSymptomLog,
                      isEmbedded: true,
                    )
                  : CycleLoggingSheet(
                      key: const ValueKey('cycle_sheet'),
                      selectedDay: widget.selectedDay,
                      existingEvent: widget.existingCycleLog,
                      isEmbedded: true,
                    ),
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
  final bool isDark;

  const _SwitcherButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected 
                  ? (isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor) 
                  : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey[500]),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected 
                    ? (isDark ? Colors.white : AppTheme.primaryColor) 
                    : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey[600]),
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
