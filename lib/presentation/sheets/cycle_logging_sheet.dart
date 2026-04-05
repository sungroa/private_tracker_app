import 'package:flutter/material.dart';
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
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.existingEvent?.startDate ?? widget.selectedDay;
    _endDate = widget.existingEvent?.endDate;
    _flowIntensity = widget.existingEvent?.flowIntensity ?? 3;
    _notesController.text = widget.existingEvent?.notes ?? "";
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryColor,
            onPrimary: Colors.white,
            onSurface: AppTheme.primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 5)),
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _onSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final event = CycleEvent(
        id: widget.existingEvent?.id,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        flowIntensity: _flowIntensity,
      );
      if (widget.existingEvent != null) {
        await context.read<CycleProvider>().updateEvent(event);
      } else {
        await context.read<CycleProvider>().addEvent(event);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onDelete() async {
    if (widget.existingEvent == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Cycle Log?"),
        content: const Text("This action cannot be undone and will remove this cycle entry from your history."),
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
      await context.read<CycleProvider>().deleteEvent(widget.existingEvent!.id);
      if (mounted) Navigator.pop(context, true);
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
    final content = SingleChildScrollView(
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
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
            Text(
              widget.existingEvent != null ? "Edit Cycle Log" : "Log Your Cycle",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            // Date Selection
            Row(
              children: [
                Expanded(
                  child: _DateCard(
                    label: "Started On",
                    date: _startDate,
                    onTap: _selectStartDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateCard(
                    label: "Ended On",
                    date: _endDate,
                    onTap: _selectEndDate,
                    isOptional: true,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  _getFlowLabel(_flowIntensity),
                  style: TextStyle(
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.primaryColor,
                inactiveTrackColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                thumbColor: AppTheme.primaryColor,
                overlayColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                valueIndicatorColor: AppTheme.primaryColor,
                valueIndicatorTextStyle: const TextStyle(color: Colors.white),
              ),
              child: Slider(
                value: _flowIntensity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _getFlowLabel(_flowIntensity),
                onChanged: (value) {
                  setState(() => _flowIntensity = value.toInt());
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Notes",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Add notes about your cycle...",
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            if (_endDate != null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _endDate = null),
                  child: const Text("Still in progress? Clear end date", style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            ],
            if (widget.existingEvent != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _onDelete,
                  child: const Text("Delete Cycle Log", style: TextStyle(color: Colors.redAccent)),
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
        decoration: AppTheme.glassDecoration(color: Colors.white).copyWith(
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

  const _DateCard({
    required this.label,
    required this.date,
    required this.onTap,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              date != null ? DateFormat('MMM d, y').format(date!) : "Not set",
              style: TextStyle(
                fontSize: 15,
                color: date != null ? AppTheme.primaryColor : Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
