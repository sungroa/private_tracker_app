import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SummaryTrendCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Widget? child;

  const SummaryTrendCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(isDark: Theme.of(context).brightness == Brightness.dark).copyWith(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: themeColor.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  color: themeColor.withValues(alpha: 0.6),
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600]!.withValues(alpha: 0.7),
                  ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 20),
            child!,
          ],
        ],
      ),
    );
  }
}
