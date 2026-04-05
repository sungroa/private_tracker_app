import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/symptom_provider.dart';
import '../providers/tag_provider.dart';
import '../../domain/models/cycle_log.dart';
import '../../domain/models/custom_tag.dart';
import '../theme/app_theme.dart';

class SymptomLoggingSheet extends StatefulWidget {
  final DateTime selectedDay;
  final SymptomLog? existingLog;

  final bool isEmbedded;
  
  const SymptomLoggingSheet({
    super.key,
    required this.selectedDay,
    this.existingLog,
    this.isEmbedded = false,
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
  bool _isDeleting = false;

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
    _notesController = TextEditingController(text: widget.existingLog?.notes ?? '');
    _tempController = TextEditingController(
      text: widget.existingLog?.basalBodyTemperature?.toString() ?? "",
    );
    _selectedFluid = widget.existingLog?.cervicalFluidType;
    _lhPositive = widget.existingLog?.lhTestPositive;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TagProvider>().refresh();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tempController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();
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
        await context.read<SymptomProvider>().updateSymptomLog(log);
      } else {
        await context.read<SymptomProvider>().addSymptomLog(log);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onDelete() async {
    if (widget.existingLog == null) return;
    HapticFeedback.heavyImpact();
    final symptomProvider = context.read<SymptomProvider>();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Entry", style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this log? This action cannot be undone.", style: TextStyle(fontFamily: AppTheme.fontFamily)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context, true),
            child: Text(
              _isDeleting ? "Deleting..." : "Delete",
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await symptomProvider.deleteSymptomLog(widget.existingLog!.id);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showAddSymptomDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Symptom', style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontFamily: AppTheme.fontFamily),
          decoration: InputDecoration(
            hintText: 'Symptom name',
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
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
                await context.read<TagProvider>().addTag(controller.text.trim());
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
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
              Navigator.pop(context);
              await context.read<TagProvider>().deleteTag(tag);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _lhChip(bool value, String label, IconData icon, bool isDark) {
    final isSelected = _lhPositive == value;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _lhPositive = isSelected ? null : value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primary : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primary : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? (isDark ? AppTheme.backgroundDarkColor : Colors.white) : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey[600]),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? (isDark ? AppTheme.backgroundDarkColor : Colors.white) : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey[600]),
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
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
              "How are you feeling?",
              style: TextStyle(
                color: primary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: AppTheme.fontFamily,
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
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _moodRating = rating);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? primary : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.2)),
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      _moodIcons[index],
                      color: isSelected ? (isDark ? AppTheme.backgroundDarkColor : Colors.white) : (isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey[600]),
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
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
                        style: TextStyle(
                          color: primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('bbt_field'),
                        controller: _tempController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(fontFamily: AppTheme.fontFamily, color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: "98.6",
                          suffixText: "°F",
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
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
                        style: TextStyle(
                          color: primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _lhChip(true, "Pos", Icons.add_circle_outline, isDark),
                          const SizedBox(width: 8),
                          _lhChip(false, "Neg", Icons.remove_circle_outline, isDark),
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
              style: TextStyle(
                color: primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
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
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFluid = selected ? type : null);
                      },
                      selectedColor: isDark ? AppTheme.accentDarkColor.withValues(alpha: 0.5) : AppTheme.accentColor.withValues(alpha: 0.3),
                      checkmarkColor: primary,
                      labelStyle: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? primary : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54),
                      ),
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Symptoms",
              style: TextStyle(
                color: primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<TagProvider>(
              builder: (context, tagProvider, _) {
                final tags = tagProvider.tags;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...tags.map((tag) {
                      final symptom = tag.name;
                      final isSelected = _selectedSymptoms.contains(symptom);
                      return GestureDetector(
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          _confirmDeleteSymptom(tag);
                        },
                        child: FilterChip(
                          label: Text(symptom),
                          selected: isSelected,
                          onSelected: (selected) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (selected) {
                                _selectedSymptoms.add(symptom);
                              } else {
                                _selectedSymptoms.remove(symptom);
                              }
                            });
                          },
                          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.1),
                          selectedColor: isDark ? AppTheme.accentDarkColor.withValues(alpha: 0.5) : AppTheme.accentColor.withValues(alpha: 0.3),
                          labelStyle: TextStyle(
                            color: isSelected ? primary : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black87),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontFamily: AppTheme.fontFamily,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? primary : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!),
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    }),
                    ActionChip(
                      onPressed: _showAddSymptomDialog,
                      label: Icon(Icons.add, size: 20, color: primary),
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!),
                      ),
                    ),
                  ],
                );
              },
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
                hintText: "Anything else to log?",
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
                  key: const Key('symptom_save_button'),
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
                          widget.existingLog != null ? "Save Changes" : "Add Log",
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, fontFamily: AppTheme.fontFamily),
                        ),
                ),
              ),
            ),
            if (widget.existingLog != null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _onDelete,
                  child: const Text("Delete Daily Log", style: TextStyle(color: Colors.redAccent, fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
        ],
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return AbsorbPointer(
      absorbing: _isSaving,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: AppTheme.glassDecoration(isDark: isDark).copyWith(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: content,
      ),
    );
  }
}

