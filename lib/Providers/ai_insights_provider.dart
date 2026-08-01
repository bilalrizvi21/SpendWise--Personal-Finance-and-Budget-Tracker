import 'package:flutter/foundation.dart';
import '../Models/ai_insights.dart';
import '../Models/transaction.dart';
import '../Services/notification_service.dart';

class AIInsightsProvider extends ChangeNotifier {
  List<AIInsight> _insights = [];
  SpendingPrediction? _prediction;
  FinancialHealthScore? _healthScore;
  List<Anomaly> _anomalies = [];
  List<SavingsRecommendation> _recommendations = [];
  bool _isLoading = false;
  String? _error;

  final Set<String> _notifiedAnomalies = {};

  List<AIInsight> get insights => _insights;
  SpendingPrediction? get prediction => _prediction;
  FinancialHealthScore? get healthScore => _healthScore;
  List<Anomaly> get anomalies => _anomalies;
  List<SavingsRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<AIInsight> get unreadInsights =>
      _insights.where((i) => !i.isRead).toList();

  List<AIInsight> get activeInsights =>
      _insights.where((i) => !i.isDismissed).toList();

  List<AIInsight> getInsightsByType(InsightType type) =>
      _insights.where((i) => i.type == type).toList();

  // ════════════════════════════════════════
  // MAIN — does NOT fire notifications
  // ════════════════════════════════════════

  Future<void> generateInsights({List<Transaction>? transactions}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (transactions == null || transactions.isEmpty) {
        _insights = [];
        _anomalies = [];
        _prediction = null;
        _healthScore = null;
        _recommendations = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      _anomalies = _detectAnomalies(transactions);
      _prediction = _predictNextMonth(transactions);
      _healthScore = _calculateHealthScore(transactions);
      _recommendations = _generateRecommendations(transactions);
      _insights = _buildInsights(transactions);

      print(
        '🧠 AI Insights: ${_anomalies.length} anomalies, '
        '${_insights.length} insights generated',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════
  // PUBLIC: called by MainNavigation after preferences are loaded
  // ════════════════════════════════════════

  Future<void> notifyAnomalies({required bool enabled}) async {
    print(
      '🧠 AIInsightsProvider.notifyAnomalies — enabled=$enabled, anomalies=${_anomalies.length}',
    );

    if (!enabled) {
      print('⏭️ Anomaly warnings disabled — skipping');
      return;
    }

    if (_anomalies.isEmpty) {
      print('ℹ️ No anomalies detected — nothing to notify');
      return;
    }

    for (final anomaly in _anomalies) {
      final key = '${anomaly.category}_${anomaly.severity}';
      print(
        '  🔍 Anomaly: ${anomaly.category} ${anomaly.severity} '
        '(${anomaly.deviation.toInt()}%) — alreadyNotified=${_notifiedAnomalies.contains(key)}',
      );

      if (_notifiedAnomalies.contains(key)) continue;

      _notifiedAnomalies.add(key);
      print('  🔔 Firing ANOMALY notification for ${anomaly.category}');
      await NotificationService.instance.showAnomalyNotification(
        category: anomaly.category,
        deviation: anomaly.deviation,
        severity: anomaly.severity,
        actualAmount: anomaly.actualAmount,
        expectedAmount: anomaly.expectedAmount,
      );
    }
    print('✅ AIInsightsProvider.notifyAnomalies complete');
  }

  // ════════════════════════════════════════
  // 1. ANOMALY DETECTION
  // ════════════════════════════════════════

  List<Anomaly> _detectAnomalies(List<Transaction> transactions) {
    final now = DateTime.now();
    final currentMonth = _getMonthExpenses(transactions, now.year, now.month);
    final month1 = _getMonthExpenses(transactions, now.year, now.month - 1);
    final month2 = _getMonthExpenses(transactions, now.year, now.month - 2);
    final month3 = _getMonthExpenses(transactions, now.year, now.month - 3);

    final anomalies = <Anomaly>[];

    for (final entry in currentMonth.entries) {
      final category = entry.key;
      final currentAmount = entry.value;

      final history = <double>[];
      if (month1.containsKey(category)) history.add(month1[category]!);
      if (month2.containsKey(category)) history.add(month2[category]!);
      if (month3.containsKey(category)) history.add(month3[category]!);

      if (history.isEmpty) continue;

      final avgSpending = history.fold(0.0, (a, b) => a + b) / history.length;
      if (avgSpending == 0) continue;

      final deviation = ((currentAmount - avgSpending) / avgSpending) * 100;

      if (deviation >= 20) {
        final severity = deviation >= 50
            ? 'major'
            : deviation >= 30
            ? 'moderate'
            : 'minor';

        anomalies.add(
          Anomaly(
            category: category,
            expectedAmount: avgSpending,
            actualAmount: currentAmount,
            deviation: deviation,
            severity: severity,
            description:
                '🚨 Your $category spending is ${deviation.toInt()}% higher than usual'
                ' (PKR ${currentAmount.toStringAsFixed(0)} vs avg PKR ${avgSpending.toStringAsFixed(0)})',
            detectedAt: now,
          ),
        );
      }
    }

    anomalies.sort((a, b) => b.deviation.compareTo(a.deviation));
    return anomalies;
  }

  // ════════════════════════════════════════
  // 2. PREDICTION
  // ════════════════════════════════════════

  SpendingPrediction? _predictNextMonth(List<Transaction> transactions) {
    final now = DateTime.now();
    final m1 = _getTotalMonthExpense(transactions, now.year, now.month - 1);
    final m2 = _getTotalMonthExpense(transactions, now.year, now.month - 2);
    final m3 = _getTotalMonthExpense(transactions, now.year, now.month - 3);

    if (m1 == 0 && m2 == 0 && m3 == 0) return null;

    double predicted;
    if (m1 > 0 && m2 > 0 && m3 > 0) {
      predicted = (m1 * 0.5) + (m2 * 0.3) + (m3 * 0.2);
    } else if (m1 > 0 && m2 > 0) {
      predicted = (m1 * 0.6) + (m2 * 0.4);
    } else {
      predicted = m1 > 0 ? m1 : m2;
    }

    final lastMonthCats = _getMonthExpenses(
      transactions,
      now.year,
      now.month - 1,
    );
    final lastTotal = lastMonthCats.values.fold(0.0, (a, b) => a + b);
    final Map<String, double> breakdown = {};
    if (lastTotal > 0) {
      for (final e in lastMonthCats.entries) {
        breakdown[e.key] = (e.value / lastTotal) * predicted;
      }
    }

    return SpendingPrediction(
      predictedAmount: predicted,
      period: 'next_month',
      confidence: m1 > 0 && m2 > 0 && m3 > 0 ? 0.82 : 0.60,
      categoryBreakdown: breakdown,
      generatedAt: now,
    );
  }

  // ════════════════════════════════════════
  // 3. HEALTH SCORE
  // ════════════════════════════════════════

  FinancialHealthScore? _calculateHealthScore(List<Transaction> transactions) {
    final now = DateTime.now();
    final expenses = transactions
        .where(
          (t) =>
              t.isExpense &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    final income = transactions
        .where(
          (t) =>
              t.isIncome &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    if (income == 0) return null;

    final savingsRate = ((income - expenses) / income * 100).clamp(0.0, 100.0);
    final expenseRatio = (expenses / income * 100).clamp(0.0, 100.0);

    double savingsScore = savingsRate >= 30
        ? 100
        : savingsRate >= 20
        ? 80
        : savingsRate >= 10
        ? 60
        : 40;

    double expenseScore = expenseRatio <= 50
        ? 100
        : expenseRatio <= 70
        ? 80
        : expenseRatio <= 85
        ? 60
        : 40;

    int activeMonths = 0;
    for (int i = 1; i <= 3; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      if (transactions.any(
        (t) => t.date.year == d.year && t.date.month == d.month,
      )) {
        activeMonths++;
      }
    }
    final double consistencyScore = (activeMonths / 3 * 100.0).clamp(
      0.0,
      100.0,
    );

    final double overallScore =
        (savingsScore * 0.4 + expenseScore * 0.4 + consistencyScore * 0.2)
            .clamp(0.0, 100.0);

    String rating = overallScore >= 80
        ? 'excellent'
        : overallScore >= 60
        ? 'good'
        : overallScore >= 40
        ? 'fair'
        : 'poor';

    final strengths = <String>[];
    final improvements = <String>[];

    if (savingsRate >= 20) {
      strengths.add('Good savings rate (${savingsRate.toInt()}%)');
    } else {
      improvements.add(
        'Increase savings rate (currently ${savingsRate.toInt()}%)',
      );
    }
    if (expenseRatio <= 70) {
      strengths.add('Controlled spending (${expenseRatio.toInt()}% of income)');
    } else {
      improvements.add(
        'Reduce expenses (${expenseRatio.toInt()}% of income spent)',
      );
    }
    if (activeMonths >= 2) {
      strengths.add('Consistent tracking for $activeMonths months');
    } else {
      improvements.add('Track transactions every month for better insights');
    }

    return FinancialHealthScore(
      score: overallScore,
      rating: rating,
      breakdown: {
        'Savings Rate': savingsScore,
        'Spending Control': expenseScore,
        'Consistency': consistencyScore,
      },
      strengths: strengths,
      improvements: improvements,
      calculatedAt: now,
    );
  }

  // ════════════════════════════════════════
  // 4. RECOMMENDATIONS
  // ════════════════════════════════════════

  List<SavingsRecommendation> _generateRecommendations(
    List<Transaction> transactions,
  ) {
    final now = DateTime.now();
    final currentMonth = _getMonthExpenses(transactions, now.year, now.month);
    final prevMonth = _getMonthExpenses(transactions, now.year, now.month - 1);

    if (currentMonth.isEmpty) return [];

    final sorted = currentMonth.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recommendations = <SavingsRecommendation>[];
    for (final entry in sorted.take(3)) {
      final category = entry.key;
      final current = entry.value;
      final prev = prevMonth[category] ?? current;
      final baseline = current < prev ? current : (current + prev) / 2;
      final recommended = baseline * 0.85;
      final savings = current - recommended;

      if (savings > 100) {
        recommendations.add(
          SavingsRecommendation(
            category: category,
            currentSpending: current,
            recommendedSpending: recommended,
            potentialSavings: savings,
            reason:
                '$category is your ${_rank(sorted.indexOf(entry) + 1)} highest expense this month',
            actionSteps: _getActionSteps(category),
            generatedAt: now,
          ),
        );
      }
    }
    return recommendations;
  }

  // ════════════════════════════════════════
  // 5. BUILD INSIGHT CARDS
  // ════════════════════════════════════════

  List<AIInsight> _buildInsights(List<Transaction> transactions) {
    final insights = <AIInsight>[];
    final now = DateTime.now();
    int id = 1;

    for (final anomaly in _anomalies) {
      insights.add(
        AIInsight(
          id: '${id++}',
          title: 'Unusual ${anomaly.category} Spending',
          description: anomaly.description,
          type: InsightType.anomaly,
          priority: anomaly.severity == 'major'
              ? InsightPriority.high
              : anomaly.severity == 'moderate'
              ? InsightPriority.medium
              : InsightPriority.low,
          createdAt: now,
        ),
      );
    }

    if (_prediction != null) {
      insights.add(
        AIInsight(
          id: '${id++}',
          title: 'Next Month Prediction',
          description:
              'Based on your pattern, you\'ll likely spend PKR ${_prediction!.predictedAmount.toStringAsFixed(0)} next month. '
              '(${(_prediction!.confidence * 100).toInt()}% confidence)',
          type: InsightType.prediction,
          priority: InsightPriority.medium,
          createdAt: now,
        ),
      );
    }

    if (_healthScore != null) {
      insights.add(
        AIInsight(
          id: '${id++}',
          title: 'Financial Health Score',
          description:
              'Your score is ${_healthScore!.score.toInt()}/100 (${_healthScore!.rating.toUpperCase()}). '
              '${_healthScore!.improvements.isNotEmpty ? _healthScore!.improvements.first : "Keep it up!"}',
          type: InsightType.achievement,
          priority: _healthScore!.score < 50
              ? InsightPriority.high
              : InsightPriority.low,
          createdAt: now,
        ),
      );
    }

    for (final rec in _recommendations.take(2)) {
      insights.add(
        AIInsight(
          id: '${id++}',
          title: '${rec.category} Savings Opportunity',
          description:
              'Save PKR ${rec.potentialSavings.toStringAsFixed(0)}/month by reducing '
              '${rec.category} by 15%. ${rec.reason}.',
          type: InsightType.recommendation,
          priority: InsightPriority.medium,
          createdAt: now,
        ),
      );
    }

    final thisExpense = transactions
        .where(
          (t) =>
              t.isExpense &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    final thisIncome = transactions
        .where(
          (t) =>
              t.isIncome &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    if (thisIncome > 0) {
      final savingsRate = ((thisIncome - thisExpense) / thisIncome * 100).clamp(
        0.0,
        100.0,
      );
      insights.add(
        AIInsight(
          id: '${id++}',
          title: 'This Month\'s Savings Rate',
          description: savingsRate >= 20
              ? 'Great job! You\'ve saved ${savingsRate.toInt()}% of income this month!'
              : 'Your savings rate is ${savingsRate.toInt()}%. Aim for at least 20%.',
          type: InsightType.tip,
          priority: savingsRate < 10
              ? InsightPriority.high
              : InsightPriority.low,
          createdAt: now,
        ),
      );
    }

    return insights;
  }

  // ════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════

  Map<String, double> _getMonthExpenses(
    List<Transaction> transactions,
    int year,
    int month,
  ) {
    while (month <= 0) {
      month += 12;
      year -= 1;
    }
    final Map<String, double> result = {};
    for (final t in transactions) {
      if (t.isExpense && t.date.year == year && t.date.month == month) {
        result[t.category] = (result[t.category] ?? 0) + t.amount;
      }
    }
    return result;
  }

  double _getTotalMonthExpense(
    List<Transaction> transactions,
    int year,
    int month,
  ) {
    while (month <= 0) {
      month += 12;
      year -= 1;
    }
    return transactions
        .where(
          (t) => t.isExpense && t.date.year == year && t.date.month == month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  String _rank(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }

  List<String> _getActionSteps(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return ['Plan meals in advance', 'Cook at home more often'];
      case 'transport':
        return ['Use public transport', 'Carpool with colleagues'];
      case 'entertainment':
        return ['Review unused subscriptions', 'Set monthly limit'];
      case 'shopping':
        return ['Wait 48h before buying', 'Compare prices first'];
      default:
        return ['Review your $category spending', 'Set a monthly limit'];
    }
  }

  Future<void> markInsightAsRead(String insightId) async {
    final index = _insights.indexWhere((i) => i.id == insightId);
    if (index != -1) {
      _insights[index] = _insights[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> dismissInsight(String insightId) async {
    final index = _insights.indexWhere((i) => i.id == insightId);
    if (index != -1) {
      _insights[index] = _insights[index].copyWith(isDismissed: true);
      notifyListeners();
    }
  }

  void clearInsights() {
    _insights = [];
    _prediction = null;
    _healthScore = null;
    _anomalies = [];
    _recommendations = [];
    _notifiedAnomalies.clear();
    notifyListeners();
  }
}
