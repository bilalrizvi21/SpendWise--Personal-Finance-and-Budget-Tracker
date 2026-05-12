import 'package:flutter/foundation.dart';
import '../Models/ai_insights.dart';
import '../Models/transaction.dart';

class AIInsightsProvider extends ChangeNotifier {
  List<AIInsight> _insights = [];
  SpendingPrediction? _prediction;
  FinancialHealthScore? _healthScore;
  List<Anomaly> _anomalies = [];
  List<SavingsRecommendation> _recommendations = [];
  bool _isLoading = false;
  String? _error;

  List<AIInsight> get insights => _insights;
  SpendingPrediction? get prediction => _prediction;
  FinancialHealthScore? get healthScore => _healthScore;
  List<Anomaly> get anomalies => _anomalies;
  List<SavingsRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<AIInsight> get unreadInsights =>
      _insights.where((i) => !i.isRead).toList();

  List<AIInsight> getInsightsByType(InsightType type) =>
      _insights.where((i) => i.type == type).toList();

  List<AIInsight> getInsightsByPriority(InsightPriority priority) =>
      _insights.where((i) => i.priority == priority).toList();

  List<AIInsight> get activeInsights =>
      _insights.where((i) => !i.isDismissed).toList();

  // ══════════════════════════════════════════════════════
  // MAIN ENTRY POINT — pass real transactions in
  // ══════════════════════════════════════════════════════

  Future<void> generateInsights({List<Transaction>? transactions}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (transactions == null || transactions.isEmpty) {
        // No data yet — clear everything
        _insights = [];
        _anomalies = [];
        _prediction = null;
        _healthScore = null;
        _recommendations = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Run all analyses
      _anomalies = _detectAnomalies(transactions);
      _prediction = _predictNextMonth(transactions);
      _healthScore = _calculateHealthScore(transactions);
      _recommendations = _generateRecommendations(transactions);
      _insights = _buildInsights(transactions);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════
  // 1. ANOMALY DETECTION
  // Logic: Compare current month spending per category
  // against the 3-month rolling average.
  // Threshold: >20% above average = anomaly
  // ══════════════════════════════════════════════════════

  List<Anomaly> _detectAnomalies(List<Transaction> transactions) {
    final now = DateTime.now();

    // Current month expenses per category
    final currentMonth = _getMonthExpenses(transactions, now.year, now.month);

    // Previous 3 months per category
    final month1 = _getMonthExpenses(transactions, now.year, now.month - 1);
    final month2 = _getMonthExpenses(transactions, now.year, now.month - 2);
    final month3 = _getMonthExpenses(transactions, now.year, now.month - 3);

    // Only detect anomalies for categories that have at least
    // 2 months of history — avoids false positives on new categories
    final anomalies = <Anomaly>[];

    for (final entry in currentMonth.entries) {
      final category = entry.key;
      final currentAmount = entry.value;

      // Collect historical data for this category
      final history = <double>[];
      if (month1.containsKey(category)) history.add(month1[category]!);
      if (month2.containsKey(category)) history.add(month2[category]!);
      if (month3.containsKey(category)) history.add(month3[category]!);

      if (history.isEmpty) continue; // No history to compare against

      final avgSpending = history.fold(0.0, (a, b) => a + b) / history.length;

      if (avgSpending == 0) continue;

      final deviation = ((currentAmount - avgSpending) / avgSpending) * 100;

      // Only flag if spending is HIGHER than usual by threshold
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

    // Sort by deviation descending — worst first
    anomalies.sort((a, b) => b.deviation.compareTo(a.deviation));
    return anomalies;
  }

  // ══════════════════════════════════════════════════════
  // 2. NEXT MONTH PREDICTION
  // Logic: Weighted average of last 3 months
  // Most recent month gets highest weight
  // ══════════════════════════════════════════════════════

  SpendingPrediction? _predictNextMonth(List<Transaction> transactions) {
    final now = DateTime.now();

    final m1 = _getTotalMonthExpense(transactions, now.year, now.month - 1);
    final m2 = _getTotalMonthExpense(transactions, now.year, now.month - 2);
    final m3 = _getTotalMonthExpense(transactions, now.year, now.month - 3);

    // Need at least 1 month of data
    if (m1 == 0 && m2 == 0 && m3 == 0) return null;

    // Weighted average: 50% last month, 30% month before, 20% oldest
    double predicted;
    if (m1 > 0 && m2 > 0 && m3 > 0) {
      predicted = (m1 * 0.5) + (m2 * 0.3) + (m3 * 0.2);
    } else if (m1 > 0 && m2 > 0) {
      predicted = (m1 * 0.6) + (m2 * 0.4);
    } else {
      predicted = m1 > 0 ? m1 : m2;
    }

    // Category breakdown for next month (proportional from last month)
    final lastMonthCats = _getMonthExpenses(
      transactions,
      now.year,
      now.month - 1,
    );
    final lastTotal = lastMonthCats.values.fold(0.0, (a, b) => a + b);
    final Map<String, double> breakdown = {};
    if (lastTotal > 0) {
      for (final entry in lastMonthCats.entries) {
        breakdown[entry.key] = (entry.value / lastTotal) * predicted;
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

  // ══════════════════════════════════════════════════════
  // 3. FINANCIAL HEALTH SCORE
  // Savings rate, budget adherence, consistency
  // ══════════════════════════════════════════════════════

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

    final savingsRate = ((income - expenses) / income * 100).clamp(0, 100);
    final expenseRatio = (expenses / income * 100).clamp(0, 100);

    // Savings rate score: 0-100
    double savingsScore;
    if (savingsRate >= 30)
      savingsScore = 100;
    else if (savingsRate >= 20)
      savingsScore = 80;
    else if (savingsRate >= 10)
      savingsScore = 60;
    else if (savingsRate >= 0)
      savingsScore = 40;
    else
      savingsScore = 20;

    // Expense ratio score (lower is better)
    double expenseScore;
    if (expenseRatio <= 50)
      expenseScore = 100;
    else if (expenseRatio <= 70)
      expenseScore = 80;
    else if (expenseRatio <= 85)
      expenseScore = 60;
    else if (expenseRatio <= 100)
      expenseScore = 40;
    else
      expenseScore = 20;

    // Consistency: how many months have transactions in last 3
    int activeMonths = 0;
    for (int i = 1; i <= 3; i++) {
      final hasData = transactions.any((t) {
        final d = DateTime(now.year, now.month - i, 1);
        return t.date.year == d.year && t.date.month == d.month;
      });
      if (hasData) activeMonths++;
    }
    final consistencyScore = (activeMonths / 3 * 100).clamp(0, 100);

    final overallScore =
        (savingsScore * 0.4 + expenseScore * 0.4 + consistencyScore * 0.2)
            .clamp(0, 100);

    String rating;
    if (overallScore >= 80)
      rating = 'excellent';
    else if (overallScore >= 60)
      rating = 'good';
    else if (overallScore >= 40)
      rating = 'fair';
    else
      rating = 'poor';

    final strengths = <String>[];
    final improvements = <String>[];

    if (savingsRate >= 20)
      strengths.add('Good savings rate (${savingsRate.toInt()}%)');
    else
      improvements.add(
        'Increase your savings rate (currently ${savingsRate.toInt()}%)',
      );

    if (expenseRatio <= 70)
      strengths.add('Controlled spending (${expenseRatio.toInt()}% of income)');
    else
      improvements.add(
        'Reduce expenses (${expenseRatio.toInt()}% of income spent)',
      );

    if (activeMonths >= 2)
      strengths.add('Consistent tracking for $activeMonths months');
    else
      improvements.add('Track transactions every month for better insights');

    return FinancialHealthScore(
      score: overallScore.toDouble(),
      rating: rating,
      breakdown: {
        'Savings Rate': savingsScore,
        'Spending Control': expenseScore,
        'Consistency': consistencyScore.toDouble(),
      },
      strengths: strengths,
      improvements: improvements,
      calculatedAt: now,
    );
  }

  // ══════════════════════════════════════════════════════
  // 4. SAVINGS RECOMMENDATIONS
  // Based on top 2 spending categories vs previous months
  // ══════════════════════════════════════════════════════

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

      // Recommend 15% reduction from whichever is lower (current or prev avg)
      final baseline = current < prev ? current : (current + prev) / 2;
      final recommended = baseline * 0.85;
      final savings = current - recommended;

      if (savings > 100) {
        // Only suggest if saving >PKR 100 is meaningful
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

  // ══════════════════════════════════════════════════════
  // 5. BUILD INSIGHT CARDS
  // Combines anomalies, predictions, health, recommendations
  // ══════════════════════════════════════════════════════

  List<AIInsight> _buildInsights(List<Transaction> transactions) {
    final insights = <AIInsight>[];
    final now = DateTime.now();
    int id = 1;

    // Anomaly insights
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

    // Prediction insight
    if (_prediction != null) {
      insights.add(
        AIInsight(
          id: '${id++}',
          title: 'Next Month Prediction',
          description:
              'Based on your spending pattern, you\'ll likely spend PKR ${_prediction!.predictedAmount.toStringAsFixed(0)} next month. '
              '(${(_prediction!.confidence * 100).toInt()}% confidence)',
          type: InsightType.prediction,
          priority: InsightPriority.medium,
          createdAt: now,
        ),
      );
    }

    // Health score insight
    if (_healthScore != null) {
      insights.add(
        AIInsight(
          id: '${id++}',
          title: 'Financial Health Score',
          description:
              'Your financial health score is ${_healthScore!.score.toInt()}/100 (${_healthScore!.rating.toUpperCase()}). '
              '${_healthScore!.improvements.isNotEmpty ? _healthScore!.improvements.first : "Keep up the great work!"}',
          type: InsightType.achievement,
          priority: _healthScore!.score < 50
              ? InsightPriority.high
              : InsightPriority.low,
          createdAt: now,
        ),
      );
    }

    // Recommendation insights
    for (final rec in _recommendations.take(2)) {
      insights.add(
        AIInsight(
          id: '${id++}',
          title: '${rec.category} Savings Opportunity',
          description:
              'You could save PKR ${rec.potentialSavings.toStringAsFixed(0)}/month '
              'by reducing ${rec.category} spending by 15%. ${rec.reason}.',
          type: InsightType.recommendation,
          priority: InsightPriority.medium,
          createdAt: now,
        ),
      );
    }

    // Spending tip (always show if data exists)
    final now2 = DateTime.now();
    final thisMonthExpense = transactions
        .where(
          (t) =>
              t.isExpense &&
              t.date.year == now2.year &&
              t.date.month == now2.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    final thisMonthIncome = transactions
        .where(
          (t) =>
              t.isIncome &&
              t.date.year == now2.year &&
              t.date.month == now2.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    if (thisMonthIncome > 0) {
      final savingsRate =
          ((thisMonthIncome - thisMonthExpense) / thisMonthIncome * 100).clamp(
            0,
            100,
          );
      insights.add(
        AIInsight(
          id: '${id++}',
          title: 'This Month\'s Savings Rate',
          description: savingsRate >= 20
              ? 'Great job! You\'ve saved ${savingsRate.toInt()}% of your income this month. Keep it up!'
              : 'Your current savings rate is ${savingsRate.toInt()}%. '
                    'Financial experts recommend saving at least 20% of income.',
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

  // ══════════════════════════════════════════════════════
  // HELPER METHODS
  // ══════════════════════════════════════════════════════

  /// Returns total expenses per category for a given month
  Map<String, double> _getMonthExpenses(
    List<Transaction> transactions,
    int year,
    int month,
  ) {
    // Handle month overflow (e.g. month -1 = previous year December)
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

  /// Returns total expense amount for a given month
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
        return [
          'Plan meals in advance',
          'Cook at home more often',
          'Buy groceries in bulk',
          'Avoid impulse restaurant visits',
        ];
      case 'transport':
        return [
          'Use public transport where possible',
          'Carpool with colleagues',
          'Combine errands into single trips',
        ];
      case 'entertainment':
        return [
          'Review and cancel unused subscriptions',
          'Look for free entertainment options',
          'Set a fixed monthly entertainment budget',
        ];
      case 'shopping':
        return [
          'Wait 48 hours before non-essential purchases',
          'Use a shopping list and stick to it',
          'Compare prices before buying',
        ];
      case 'bills':
        return [
          'Review all recurring subscriptions',
          'Negotiate better rates on utilities',
          'Switch to more economical plans',
        ];
      default:
        return [
          'Review your recent spending in this category',
          'Set a monthly limit for $category',
          'Track every $category expense carefully',
        ];
    }
  }

  // ══════════════════════════════════════════════════════
  // INDIVIDUAL ACTIONS
  // ══════════════════════════════════════════════════════

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
    notifyListeners();
  }
}
