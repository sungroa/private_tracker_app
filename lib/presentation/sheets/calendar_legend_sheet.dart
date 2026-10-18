import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CalendarLegendSheet extends StatelessWidget {
  const CalendarLegendSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Calendar Legend",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.primaryColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  _LegendItem(
                    isDark: isDark,
                    title: "Logged Period",
                    description: "Dates where period flow is explicitly logged.",
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LegendItem(
                    isDark: isDark,
                    title: "Predicted Period",
                    description: "Dates where your period is expected based on your cycle history.",
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LegendItem(
                    isDark: isDark,
                    title: "Predicted Fertile Window",
                    description: "Dates you are most likely to be fertile.",
                    leading: _buildMarker(
                      Icons.circle,
                      Colors.indigoAccent.withValues(alpha: 0.5),
                      size: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LegendItem(
                    isDark: isDark,
                    title: "Daily Log (Symptoms/Mood)",
                    description: "You have logged symptoms or mood for this day.",
                    leading: _buildMarker(Icons.brightness_1, Colors.purpleAccent, size: 10),
                  ),
                  const SizedBox(height: 16),
                  _LegendItem(
                    isDark: isDark,
                    title: "Positive LH Test",
                    description: "A positive ovulation test was logged.",
                    leading: _buildMarker(Icons.star_rounded, Colors.pinkAccent, size: 16),
                  ),
                  const SizedBox(height: 16),
                  _LegendItem(
                    isDark: isDark,
                    title: "BBT Logged",
                    description: "Basal Body Temperature was recorded.",
                    leading: _buildMarker(Icons.thermostat_rounded, Colors.orangeAccent, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMarker(IconData icon, Color color, {double size = 12}) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.isDark,
    required this.title,
    required this.description,
    required this.leading,
  });
  final bool isDark;
  final String title;
  final String description;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
