import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A premium decorative background that features a linear gradient and 
/// a large translucent circle in the top-right corner.
///
/// This widget is intended to be used as the root background for pages
/// to ensure that decorative elements transition smoothly during navigation.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base Gradient Layer
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? AppGradients.darkBackground
                  : AppGradients.lightBackground,
            ),
          ),
        ),
        
        // Decorative Top-Right Circle
        Positioned(
          top: -150,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  AppTheme.primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        
        // Content Layer
        child,
      ],
    );
  }
}
