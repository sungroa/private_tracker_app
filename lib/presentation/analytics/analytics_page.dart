import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trends_provider.dart';
import '../theme/app_theme.dart';
import 'widgets/bbt_chart.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends & Insights'),
      ),
      body: Consumer<TrendsProvider>(
        builder: (context, trendsProvider, child) {
          final trendData = trendsProvider.trendData;
          if (trendData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Basal Body Temperature',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                BbtChart(bbtHistory: trendData.bbtHistory),
                const SizedBox(height: 32),
                const Text(
                  'Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'Cycle Length',
                  value: '${trendData.averageCycleLength.toStringAsFixed(1)} days',
                  icon: Icons.calendar_today,
                ),
                const SizedBox(height: 12),
                _InsightCard(
                  title: 'Period Duration',
                  value: '${trendData.averagePeriodDuration.toStringAsFixed(1)} days',
                  icon: Icons.water_drop,
                ),
                const SizedBox(height: 12),
                _SymptomInsight(symptoms: trendData.topSymptoms),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomInsight extends StatelessWidget {
  final List<MapEntry<String, int>> symptoms;

  const _SymptomInsight({required this.symptoms});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: AppTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Symptoms',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (symptoms.isEmpty)
            const Text('No symptoms logged yet', style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: symptoms.map((s) => Chip(
                label: Text('${s.key} (${s.value})'),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                side: BorderSide.none,
                labelStyle: const TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                padding: EdgeInsets.zero,
              )).toList(),
            ),
        ],
      ),
    );
  }
}
