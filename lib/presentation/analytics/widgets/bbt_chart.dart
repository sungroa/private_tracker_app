import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../domain/trends_calculator.dart';
import '../../theme/app_theme.dart';

class BbtChart extends StatelessWidget {
  final List<BbtPoint> bbtHistory;

  const BbtChart({super.key, required this.bbtHistory});

  String _buildSemanticLabel() {
    if (bbtHistory.isEmpty) {
      return "No Basal Body Temperature data for this cycle";
    }

    final temps = bbtHistory.map((p) => p.temperature).toList();
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final lhSurges = bbtHistory.where((p) => p.hasLhSurge).map((p) => "Day ${p.cycleDay}").toList();

    final buffer = StringBuffer();
    buffer.write("Basal Body Temperature chart showing ${bbtHistory.length} recorded temperatures. ");
    buffer.write("Average temperature is ${avgTemp.toStringAsFixed(1)} degrees. ");
    buffer.write("Lowest temperature is ${minTemp.toStringAsFixed(1)} degrees. ");
    buffer.write("Highest temperature is ${maxTemp.toStringAsFixed(1)} degrees. ");
    if (lhSurges.isNotEmpty) {
      buffer.write("Luteinizing Hormone surge detected on: ${lhSurges.join(', ')}.");
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (bbtHistory.isEmpty) {
      return const Center(
        child: Text('No BBT data for this cycle', style: TextStyle(color: Colors.grey)),
      );
    }

    final double minTemp = bbtHistory.map((p) => p.temperature).reduce((a, b) => a < b ? a : b) - 0.2;
    final double maxTemp = bbtHistory.map((p) => p.temperature).reduce((a, b) => a > b ? a : b) + 0.2;
    final double maxCycleDay = bbtHistory.map((p) => p.cycleDay).reduce((a, b) => a > b ? a : b).toDouble();

    return Semantics(
      label: _buildSemanticLabel(),
      child: Container(
        height: 300,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: AppTheme.glassDecoration(),
      child: LineChart(
        LineChartData(
          minY: minTemp,
          maxY: maxTemp,
          minX: 1,
          maxX: maxCycleDay + 1,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Day ${value.toInt()}',
                      style: TextStyle(
                        color: AppTheme.primaryColor.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // BBT Line
            LineChartBarData(
              spots: bbtHistory.map((p) => FlSpot(p.cycleDay.toDouble(), p.temperature)).toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppTheme.primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppTheme.primaryColor,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.35),
                    AppTheme.primaryColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // LH Surge Markers (Dots on X-axis)
            LineChartBarData(
              spots: bbtHistory
                  .where((p) => p.hasLhSurge)
                  .map((p) => FlSpot(p.cycleDay.toDouble(), minTemp + 0.05))
                  .toList(),
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 6,
                  color: Colors.amber,
                  strokeWidth: 0,
                ),
              ),
            ),
            // Other Symptom Markers (Smaller dots on X-axis)
            LineChartBarData(
              spots: bbtHistory
                  .where((p) => p.symptoms.isNotEmpty && !p.hasLhSurge)
                  .map((p) => FlSpot(p.cycleDay.toDouble(), minTemp + 0.05))
                  .toList(),
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  strokeWidth: 0,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.primaryColor.withValues(alpha: 0.8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final point = bbtHistory.firstWhere((p) => p.cycleDay == spot.x.toInt());
                  return LineTooltipItem(
                    '${point.temperature}°C\nDay ${point.cycleDay}\n${point.symptoms.join(", ")}',
                    const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    ),
  );
}
}
