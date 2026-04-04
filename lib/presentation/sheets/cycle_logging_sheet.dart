import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../../domain/models/cycle_log.dart';
import '../theme/app_theme.dart';

class CycleLoggingSheet extends StatefulWidget {
  final DateTime selectedDay;
  final CycleLog? existingLog;

  const CycleLoggingSheet({
    super.key,
    required this.selectedDay,
    this.existingLog,
  });

  @override
  State<CycleLoggingSheet> createState() => _CycleLoggingSheetState();
}

class _CycleLoggingSheetState extends State<CycleLoggingSheet> {
  late DateTime _startDate;
  DateTime? _endDate;
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.existingLog?.startDate ?? widget.selectedDay;
    _endDate = widget.existingLog?.endDate;
    _notesController.text = widget.existingLog?.notes ?? "";
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
      final log = CycleLog(
        id: widget.existingLog?.id,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      if (widget.existingLog != null) {
        await context.read<CycleProvider>().updateLog(log);
      } else {
        await context.read<CycleProvider>().addLog(log);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onDelete() async {
    if (widget.existingLog == null) return;
    setState(() => _isSaving = true);
    try {
      await context.read<CycleProvider>().deleteLog(widget.existingLog!.id);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isSaving,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: AppTheme.glassDecoration(color: Colors.white).copyWith(
          borderRadius: BorderRadius.circular(32),
        ),
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Text(
              "Log Your Cycle",
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
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                    : const Text(
                        "Save Cycle Info",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            if (widget.existingLog != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _onDelete,
                  child: const Text("Delete Cycle Log", style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
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
