import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// A premium glassmorphic bottom sheet for selecting a specific month and year.
class MonthYearPickerSheet extends StatefulWidget {
  final DateTime initialDate;

  const MonthYearPickerSheet({
    super.key,
    required this.initialDate,
  });

  @override
  State<MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<MonthYearPickerSheet> {
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  late int _selectedMonth;
  late int _selectedYear;

  final List<String> _months = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
  ];

  late List<int> _years;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialDate.month;
    _selectedYear = widget.initialDate.year;

    // Generate a range of years: Current Year - 10 to Current Year + 10
    final currentYear = DateTime.now().year;
    _years = List.generate(21, (index) => (currentYear - 10) + index);

    // If initial year is outside this range, expand it
    if (_selectedYear < _years.first) {
      _years = List.generate(_years.length + (_years.first - _selectedYear), 
          (index) => _selectedYear + index);
    } else if (_selectedYear > _years.last) {
      _years = List.generate(_selectedYear - _years.first + 1, 
          (index) => _years.first + index);
    }

    _monthController = FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _yearController = FixedExtentScrollController(initialItem: _years.indexOf(_selectedYear));
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(DateTime(_selectedYear, _selectedMonth));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;
    final viewPadding = MediaQuery.of(context).padding;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      padding: EdgeInsets.only(
        bottom: viewInsets.bottom + viewPadding.bottom + 32,
        top: 16,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDarkColor.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'SELECT DATE',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 2,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    // Month Picker
                    Expanded(
                      flex: 2,
                      child: ListWheelScrollView.useDelegate(
                        controller: _monthController,
                        itemExtent: 45,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedMonth = index + 1);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: _months.length,
                          builder: (context, index) {
                            final isSelected = _selectedMonth == index + 1;
                            return Center(
                              child: Text(
                                _months[index],
                                style: TextStyle(
                                  color: isSelected ? primary : primary.withValues(alpha: 0.3),
                                  fontSize: isSelected ? 18 : 16,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Separator
                    Container(
                      width: 1,
                      height: 100,
                      color: primary.withValues(alpha: 0.1),
                    ),

                    // Year Picker
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: _yearController,
                        itemExtent: 45,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedYear = _years[index]);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: _years.length,
                          builder: (context, index) {
                            final isSelected = _selectedYear == _years[index];
                            return Center(
                              child: Text(
                                _years[index].toString(),
                                style: TextStyle(
                                  color: isSelected ? primary : primary.withValues(alpha: 0.3),
                                  fontSize: isSelected ? 18 : 16,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // Selection Highlight (Visual guide)
              // Actually, I'll put the highlight behind the pickers for a better look
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: isDark ? AppTheme.backgroundDarkColor : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text(
                    "CONFIRM",
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
