import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/constants/app_strings.dart';
import '../../Core/constants/app_colors.dart';
import '../../Core/widgets/loading_indicator.dart';
import '../../Providers/ai_insights_provider.dart';
import '../../Models/ai_insights.dart';

class AIInsightsPage extends StatelessWidget {
  const AIInsightsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          AppStrings.aiInsights,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<AIInsightsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: LoadingIndicator(size: 48));
          }

          final insights = provider.activeInsights;
          final economic = provider.economicData;

          if (insights.isEmpty && economic == null) {
            return const EmptyState(
              icon: Icons.analytics_outlined,
              title: AppStrings.noInsights,
              description:
                  'AI insights will appear here as you add more transactions',
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),

                // ── AI Header card ──
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6A11CB).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI-Powered Insights',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${insights.length} insights • '
                              '${economic != null ? 'Inflation-adjusted' : 'Local analysis'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 🇵🇰 Pakistan Economic Context Card ──
                if (economic != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.trending_up,
                                color: AppColors.warning,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '🇵🇰 Pakistan Economic Context',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: economic.isLiveData
                                    ? AppColors.success.withOpacity(0.12)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                economic.isLiveData ? '● LIVE' : '● CACHED',
                                style: TextStyle(
                                  color: economic.isLiveData
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _economicStat(
                          label: 'Pakistan Annual Inflation (CPI)',
                          value: economic.inflationLabel,
                          icon: Icons.show_chart,
                          color: economic.inflationRate > 15
                              ? AppColors.error
                              : AppColors.warning,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.warning,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your next-month spending prediction has been '
                                  'adjusted upward by ${(economic.inflationRate / 12).toStringAsFixed(2)}% '
                                  'to account for monthly inflation pressure on prices.',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Insight cards ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: insights.map((insight) {
                      return _buildInsightCard(insight);
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _economicStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(AIInsight insight) {
    final color = _priorityColor(insight.priority);
    final gradient = _gradientForType(insight.type);
    final icon = _iconForType(insight.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  insight.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  insight.priority.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            insight.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.high:
        return AppColors.error;
      case InsightPriority.medium:
        return AppColors.warning;
      case InsightPriority.low:
        return AppColors.info;
    }
  }

  List<Color> _gradientForType(InsightType type) {
    switch (type) {
      case InsightType.anomaly:
        return [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)];
      case InsightType.prediction:
        return [const Color(0xFF667EEA), const Color(0xFF764BA2)];
      case InsightType.recommendation:
        return [const Color(0xFF11998E), const Color(0xFF38EF7D)];
      case InsightType.achievement:
        return [const Color(0xFFFFD89B), const Color(0xFF19547B)];
      case InsightType.warning:
        return [const Color(0xFFF59E0B), const Color(0xFFEF4444)];
      case InsightType.tip:
        return [const Color(0xFFFA8BFF), const Color(0xFF2BD2FF)];
    }
  }

  IconData _iconForType(InsightType type) {
    switch (type) {
      case InsightType.anomaly:
        return Icons.warning_amber;
      case InsightType.prediction:
        return Icons.trending_up;
      case InsightType.recommendation:
        return Icons.lightbulb_outline;
      case InsightType.achievement:
        return Icons.emoji_events;
      case InsightType.warning:
        return Icons.notification_important;
      case InsightType.tip:
        return Icons.insights;
    }
  }
}
