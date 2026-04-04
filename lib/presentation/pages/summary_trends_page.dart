import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trends_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/summary_trend_card.dart';
import '../widgets/summary_line_chart.dart';

class SummaryTrendsPage extends StatelessWidget {
  const SummaryTrendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _trendData = context.watch<TrendsProvider>().trendData;

    if (_trendData == null) {
      return const Center(child: Text("No data available yet."));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Text(
              "Your Trends",
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Insights from your last cycles",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            
            // Cycle Stats Row
            Row(
              children: [
                Expanded(
                  child: SummaryTrendCard(
                    title: "AVG CYCLE",
                    value: "${_trendData!.averageCycleLength.toStringAsFixed(0)}d",
                    icon: Icons.loop,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SummaryTrendCard(
                    title: "AVG PERIOD",
                    value: "${_trendData!.averagePeriodDuration.toStringAsFixed(1)}d",
                    icon: Icons.water_drop,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Mood Trend Card
            SummaryTrendCard(
              title: "MOOD TREND",
              value: _trendData!.moodHistory.isEmpty 
                  ? "Logged data" 
                  : _getMoodSummaryText(_trendData!.moodHistory.last.rating),
              subtitle: "Last 30 days",
              icon: Icons.show_chart,
              child: SummaryLineChart(data: _trendData!.moodHistory),
            ),
            const SizedBox(height: 24),
            
            // Top Symptoms Card
            SummaryTrendCard(
              title: "TOP SYMPTOMS",
              value: _trendData!.topSymptoms.isEmpty ? "None" : _trendData!.topSymptoms.first.key,
              subtitle: "Frequently logged",
              icon: Icons.list,
              child: _trendData!.topSymptoms.isEmpty 
                  ? null 
                  : Column(
                      children: _trendData!.topSymptoms.skip(1).map((symptom) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(symptom.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text("${symptom.value} times", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 40),
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
