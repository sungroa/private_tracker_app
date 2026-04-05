import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/summary_trend_card.dart';
import '../widgets/summary_line_chart.dart';
import '../analytics/widgets/bbt_chart.dart';

class SummaryTrendsPage extends StatelessWidget {
  const SummaryTrendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;
    
    final cycleProvider = context.watch<CycleProvider>();
    final trendData = cycleProvider.trends;

    if (trendData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats, size: 64, color: primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              "No data available yet.",
              style: TextStyle(
                color: primary.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              "Your Trends",
              style: TextStyle(
                color: primary,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                fontFamily: AppTheme.fontFamily,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Deep insights from your biology",
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey[600],
                fontSize: 16,
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),

            // BBT Chart Section
            Text(
              "Basal Body Temperature",
              style: TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 20),
            BbtChart(bbtHistory: trendData.bbtHistory),
            const SizedBox(height: 40),
            
            // Cycle Stats Grid
            Row(
              children: [
                Expanded(
                  child: SummaryTrendCard(
                    title: "AVG CYCLE",
                    value: "${trendData.averageCycleLength.toStringAsFixed(0)}d",
                    icon: Icons.loop,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SummaryTrendCard(
                    title: "AVG PERIOD",
                    value: "${trendData.averagePeriodDuration.toStringAsFixed(1)}d",
                    icon: Icons.water_drop,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Mood Trend Card
            SummaryTrendCard(
              title: "MOOD TREND",
              value: trendData.moodHistory.isEmpty 
                  ? "Logged data" 
                  : _getMoodSummaryText(trendData.moodHistory.last.rating),
              subtitle: "Consistency is key",
              icon: Icons.show_chart,
              child: SummaryLineChart(data: trendData.moodHistory),
            ),
            const SizedBox(height: 24),
            
            // Top Symptoms Card
            SummaryTrendCard(
              title: "TOP SYMPTOMS",
              value: trendData.topSymptoms.isEmpty ? "None" : trendData.topSymptoms.first.key,
              subtitle: "Patterns spotted",
              icon: Icons.auto_awesome_mosaic_rounded,
              child: trendData.topSymptoms.isEmpty 
                  ? null 
                  : Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        children: trendData.topSymptoms.skip(1).take(3).map((symptom) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  symptom.key,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                                    fontFamily: AppTheme.fontFamily,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "${symptom.value}x",
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: AppTheme.fontFamily,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  String _getMoodSummaryText(int rating) {
    final Map<int, String> moodMap = {
      1: "Really struggling",
      2: "Feeling down",
      3: "Doing okay",
      4: "Feeling good",
      5: "Excellent mood",
    };
    return moodMap[rating] ?? "Tracking well";
  }
}
