import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../../domain/models/cycle_log.dart';
import '../theme/app_theme.dart';

class CycleLoggingSheet extends StatefulWidget {
  final DateTime selectedDay;
  final CycleEvent? existingEvent;

  final bool isEmbedded;

  const CycleLoggingSheet({
    super.key,
    required this.selectedDay,
    this.existingEvent,
    this.isEmbedded = false,
  });

  @override
  State<CycleLoggingSheet> createState() => _CycleLoggingSheetState();
}

class _CycleLoggingSheetState extends State<CycleLoggingSheet> {
  late DateTime _startDate;
  DateTime? _endDate;
  late int _flowIntensity;
  late final TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.existingEvent?.startDate ?? widget.selectedDay;
    _endDate = widget.existingEvent?.endDate;
    _flowIntensity = widget.existingEvent?.flowIntensity ?? 3;
    _notesController = TextEditingController(text: widget.existingEvent?.notes ?? "");
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark 
              ? ColorScheme.dark(primary: primary, onPrimary: AppTheme.backgroundDarkColor, surface: AppTheme.backgroundDarkColor)
              : ColorScheme.light(primary: primary, onPrimary: Colors.white, onSurface: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectEndDate() async {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 5)),
      firstDate: _startDate,
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark 
              ? ColorScheme.dark(primary: primary, onPrimary: AppTheme.backgroundDarkColor, surface: AppTheme.backgroundDarkColor)
              : ColorScheme.light(primary: primary, onPrimary: Colors.white, onSurface: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }
  void _onSave() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();
    final navigator = Navigator.of(context);
    setState(() => _isSaving = true);
    try {
      final event = CycleEvent(
        id: widget.existingEvent?.id,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        flowIntensity: _flowIntensity,
      );
      final provider = context.read<CycleProvider>();
      if (widget.existingEvent != null) {
        await provider.updateEvent(event);
      } else {
        await provider.addEvent(event);
      }
      if (mounted) navigator.pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onDelete() async {
    if (widget.existingEvent == null) return;
    HapticFeedback.heavyImpact();
    
    final navigator = Navigator.of(context);
    final provider = context.read<CycleProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Cycle Log?", style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold)),
        content: const Text("This action cannot be undone and will remove this cycle entry from your history.", style: TextStyle(fontFamily: AppTheme.fontFamily)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await provider.deleteEvent(widget.existingEvent!.id);
      if (mounted) navigator.pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getFlowLabel(int value) {
    switch (value) {
      case 1: return "Spotting";
      case 2: return "Light";
      case 3: return "Moderate";
      case 4: return "Heavy";
      case 5: return "Very Heavy";
      default: return "Moderate";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isEmbedded) ...[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
            Text(
              widget.existingEvent != null ? "Edit Cycle Log" : "Log Your Cycle",
              style: TextStyle(
                color: primary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 16),
            // Date Selection
            Row(
              children: [
                Expanded(
                  child: _DateCard(
                    label: "Started On",
                    date: _startDate,
                    onTap: _selectStartDate,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateCard(
                    label: "Ended On",
                    date: _endDate,
                    onTap: _selectEndDate,
                    isOptional: true,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Flow Intensity Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Flow Intensity",
                  style: TextStyle(
                    color: primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                Text(
                  _getFlowLabel(_flowIntensity),
                  style: TextStyle(
                    color: primary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: primary,
                inactiveTrackColor: primary.withValues(alpha: 0.1),
                thumbColor: primary,
                overlayColor: primary.withValues(alpha: 0.2),
                valueIndicatorColor: primary,
                valueIndicatorTextStyle: TextStyle(color: isDark ? AppTheme.backgroundDarkColor : Colors.white, fontWeight: FontWeight.bold),
              ),
              child: Slider(
                value: _flowIntensity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _getFlowLabel(_flowIntensity),
                onChanged: (value) {
                  if (value.toInt() != _flowIntensity) {
                    HapticFeedback.selectionClick();
                  }
                  setState(() => _flowIntensity = value.toInt());
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Notes",
              style: TextStyle(
                color: primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: TextStyle(fontSize: 14, fontFamily: AppTheme.fontFamily, color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "Add notes about your cycle...",
                hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: isDark 
                        ? [AppTheme.primaryDarkColor, AppTheme.accentDarkColor] 
                        : [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    foregroundColor: isDark ? AppTheme.backgroundDarkColor : Colors.white,
                    shadowColor: Colors.transparent,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.existingEvent != null ? "Save Changes" : "Add Cycle Log",
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, fontFamily: AppTheme.fontFamily),
                        ),
                ),
              ),
            ),
            if (_endDate != null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _endDate = null);
                  },
                  child: const Text("Still in progress? Clear end date", style: TextStyle(color: Colors.redAccent, fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
            if (widget.existingEvent != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _onDelete,
                  child: const Text("Delete Cycle Log", style: TextStyle(color: Colors.redAccent, fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
        ],
      ),
    );

    if (widget.isEmbedded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: content,
      );
    }

    return AbsorbPointer(
      absorbing: _isSaving,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: AppTheme.glassDecoration(isDark: isDark).copyWith(
          borderRadius: BorderRadius.circular(32),
        ),
        child: content,
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isOptional;
  final bool isDark;

  const _DateCard({
    required this.label,
    required this.date,
    required this.onTap,
    this.isOptional = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              date != null ? DateFormat('MMM d, y').format(date!) : "Not set",
              style: TextStyle(
                fontSize: 15,
                color: date != null ? primary : (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey[400]),
                fontWeight: FontWeight.w700,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
