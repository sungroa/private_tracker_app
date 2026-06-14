import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../domain/trends_calculator.dart';

class SummaryLineChart extends StatelessWidget {
  final List<MoodPoint> data;
  final double height;

  const SummaryLineChart({
    super.key,
    required this.data,
    this.height = 100,
  });

  String _buildSemanticLabel() {
    if (data.isEmpty) {
      return "No mood data yet";
    }
    final ratings = data.map((p) => p.rating).toList();
    final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
    final lastRating = ratings.last;
    
    return "Mood trend chart showing ${data.length} logs. Average mood rating is ${_getMoodLabel(avgRating.round())}. Latest logged mood is ${_getMoodLabel(lastRating.round())}.";
  }

  String _getMoodLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Really struggling';
      case 2:
        return 'Feeling down';
      case 3:
        return 'Doing okay';
      case 4:
        return 'Feeling good';
      case 5:
        return 'Excellent mood';
      default:
        return 'Doing okay';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        child: Text(
          "No mood data yet",
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return Semantics(
      label: _buildSemanticLabel(),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _LineChartPainter(data, themeColor),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<MoodPoint> data;
  final Color themeColor;

  _LineChartPainter(this.data, this.themeColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) {
      // Draw a single point or a dummy line if needed
      return;
    }

    final paint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double stepX = size.width / (data.length - 1);
    const double maxY = 5.0; // Max mood rating

    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      // Flip Y because 0,0 is top-left
      final double y = size.height - (data[i].rating / maxY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Simple cubic bezier for smoothness
        final double prevX = (i - 1) * stepX;
        final double prevY = size.height - (data[i - 1].rating / maxY * size.height);
        
        path.cubicTo(
          prevX + stepX / 2, prevY, 
          x - stepX / 2, y, 
          x, y
        );
      }
    }

    // Draw area gradient under the line
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          themeColor.withValues(alpha: 0.3),
          themeColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots at points
    final dotPaint = Paint()..color = themeColor;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y = size.height - (data[i].rating / maxY * size.height);
      
      canvas.drawCircle(Offset(x, y), 5, dotBorderPaint);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    if (oldDelegate.themeColor != themeColor) return true;
    if (oldDelegate.data.length != data.length) return true;
    for (int i = 0; i < data.length; i++) {
      if (oldDelegate.data[i].rating != data[i].rating || oldDelegate.data[i].date != data[i].date) {
        return true;
      }
    }
    return false;
  }
}
