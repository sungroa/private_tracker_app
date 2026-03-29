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

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LineChartPainter(data),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<MoodPoint> data;

  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) {
      // Draw a single point or a dummy line if needed
      return;
    }

    final paint = Paint()
      ..color = AppTheme.primaryColor
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
          AppTheme.primaryColor.withValues(alpha: 0.3),
          AppTheme.primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots at points
    final dotPaint = Paint()..color = AppTheme.primaryColor;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
