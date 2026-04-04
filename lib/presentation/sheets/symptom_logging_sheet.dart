import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/symptom_provider.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/custom_tag.dart';
import '../../data/storage/encrypted_storage_service.dart';
import '../theme/app_theme.dart';

class SymptomLoggingSheet extends StatefulWidget {
  final DateTime selectedDay;
  final SymptomLog? existingLog;

  const SymptomLoggingSheet({
    super.key,
    required this.selectedDay,
    this.existingLog,
  });

  @override
  State<SymptomLoggingSheet> createState() => _SymptomLoggingSheetState();
}

class _SymptomLoggingSheetState extends State<SymptomLoggingSheet> {
  late int _moodRating;
  late List<String> _selectedSymptoms;
  late TextEditingController _notesController;
  late TextEditingController _tempController;
  String? _selectedFluid;
  bool? _lhPositive;
  bool _isSaving = false;

  final List<IconData> _moodIcons = [
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];

  final List<String> _fluidTypes = [
    'Dry',
    'Sticky',
    'Creamy',
    'Watery',
    'Eggwhite',
  ];

  @override
  void initState() {
    super.initState();
    _moodRating = widget.existingLog?.moodRating ?? 3;
    _selectedSymptoms = List.from(widget.existingLog?.symptoms ?? []);
    _notesController = TextEditingController(text: widget.existingLog?.notes);
    _tempController = TextEditingController(
      text: widget.existingLog?.basalBodyTemperature?.toString() ?? "",
    );
    _selectedFluid = widget.existingLog?.cervicalFluidType;
    _lhPositive = widget.existingLog?.lhTestPositive;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tempController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final bbt = double.tryParse(_tempController.text);
      final log = SymptomLog(
        id: widget.existingLog?.id,
        date: widget.selectedDay,
        symptoms: _selectedSymptoms,
        moodRating: _moodRating,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        basalBodyTemperature: bbt,
        cervicalFluidType: _selectedFluid,
        lhTestPositive: _lhPositive,
      );
      if (widget.existingLog != null) {
        await context.read<SymptomProvider>().updateLog(log);
      } else {
        await context.read<SymptomProvider>().addLog(log);
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
      await context.read<SymptomProvider>().deleteLog(widget.existingLog!.id);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddSymptomDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Symptom'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Symptom name'),
          maxLength: 24,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await EncryptedStorageService.instance.addCustomTag(controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSymptom(CustomTag tag) {
    if (tag.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default symptoms cannot be deleted')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Symptom?'),
        content: Text('Are you sure you want to delete "${tag.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await EncryptedStorageService.instance.deleteCustomTag(tag);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _lhChip(bool value, String label, IconData icon) {
    final isSelected = _lhPositive == value;
    return GestureDetector(
      onTap: () => setState(() => _lhPositive = isSelected ? null : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isSaving,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: AppTheme.glassDecoration(color: Colors.white).copyWith(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
              "How are you feeling?",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Mood Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = _moodRating == rating;
                return GestureDetector(
                  onTap: () => setState(() => _moodRating = rating),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      _moodIcons[index],
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            const SizedBox(height: 32),
            // FAM Metrics
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Temperature",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tempController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: "98.6",
                          suffixText: "°F",
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "LH Test",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _lhChip(true, "Pos", Icons.add_circle_outline),
                          const SizedBox(width: 8),
                          _lhChip(false, "Neg", Icons.remove_circle_outline),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              "Cervical Fluid",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _fluidTypes.map((type) {
                  final isSelected = _selectedFluid == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFluid = selected ? type : null);
                      },
                      selectedColor: AppTheme.accentColor.withValues(alpha: 0.3),
                      checkmarkColor: AppTheme.primaryColor,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Symptoms",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: EncryptedStorageService.instance.getCustomTagsBox().listenable(),
              builder: (context, Box<CustomTag> box, _) {
                final tags = box.values.toList();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...tags.map((tag) {
                      final symptom = tag.name;
                      final isSelected = _selectedSymptoms.contains(symptom);
                      return GestureDetector(
                        onLongPress: () => _confirmDeleteSymptom(tag),
                        child: FilterChip(
                          label: Text(symptom),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSymptoms.add(symptom);
                              } else {
                                _selectedSymptoms.remove(symptom);
                              }
                            });
                          },
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          selectedColor: AppTheme.accentColor.withValues(alpha: 0.3),
                          labelStyle: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    }),
                    ActionChip(
                      onPressed: _showAddSymptomDialog,
                      label: const Icon(Icons.add, size: 20),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ],
                );
              },
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
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Anything else to log?",
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
                key: const Key('symptom_save_button'),
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
                    : const Text(
                        "Save Log",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            if (widget.existingLog != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _onDelete,
                  child: const Text("Delete Daily Log", style: TextStyle(color: Colors.redAccent)),
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
