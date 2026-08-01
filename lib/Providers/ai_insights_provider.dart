import 'package:flutter/foundation.dart';
import '../Models/ai_insights.dart';
import '../Models/transaction.dart';
import '../Services/notification_service.dart';
import '../Services/inflation_service.dart';

class AIInsightsProvider extends ChangeNotifier {
  List<AIInsight> _insights = [];
  SpendingPrediction? _prediction;
  FinancialHealthScore? _healthScore;
  List<Anomaly> _anomalies = [];
  List<SavingsRecommendation> _recommendations = [];
  EconomicData? _economicData;
  bool _isLoading = false;
  String? _error;

  final Set<String> _notifiedAnomalies = {};

  List<AIInsight> get insights => _insights;
  SpendingPrediction? get prediction => _prediction;
  FinancialHealthScore? get healthScore => _healthScore;
  List<Anomaly> get anomalies => _anomalies;
  List<SavingsRecommendation> get recommendations => _recommendations;
  EconomicData? get economicData => _economicData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<AIInsight> get unreadInsights =>
      _insights.where((i) => !i.isRead).toList();
  List<AIInsight> get activeInsights =>
      _insights.where((i) => !i.isDismissed).toList();

  List<AIInsight> getInsightsByType(InsightType type) =>
      _insights.where((i) => i.type == type).toList();

  // ════════════════════════════════════════
  // MAIN — fetches inflation data then generates insights
  // ════════════════════════════════════════

  Future<void> generateInsights({List<Transaction>? transactions}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch economic data in parallel with analysis
      final economicFuture = InflationService.instance.getEconomicData();

      if (transactions == null || transactions.isEmpty) {
        _economicData = await economicFuture;
        _insights = [];
        _anomalies = [];
        _prediction = null;
        _healthScore = null;
        _recommendations = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Run analysis and fetch economic data together
      _economicData = await economicFuture;
      _anomalies = _detectAnomalies(transactions);

      // ── Prediction factors in inflation ──
      _prediction = _predictNextMonth(transactions, _economicData!);
      _healthScore = _calculateHealthScore(transactions);
      _recommendations = _generateRecommendations(transactions);
      _insights = _buildInsights(transactions);

      print(
        '🧠 AI Insights: ${_anomalies.length} anomalies, '
        '${_insights.length} insights | '
        'Inflation: ${_economicData!.inflationLabel}',
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
  // PUBLIC: anomaly notifications
  // ════════════════════════════════════════

  Future<void> notifyAnomalies({required bool enabled}) async {
    print(
      '🧠 AIInsightsProvider.notifyAnomalies — '
      'enabled=$enabled, anomalies=${_anomalies.length}',
    );
    if (!enabled || _anomalies.isEmpty) return;

    for (final anomaly in _anomalies) {
      final key = '${anomaly.category}_${anomaly.severity}';
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
    final current = _getMonthExpenses(transactions, now.year, now.month);
    final m1 = _getMonthExpenses(transactions, now.year, now.month - 1);
    final m2 = _getMonthExpenses(transactions, now.year, now.month - 2);
    final m3 = _getMonthExpenses(transactions, now.year, now.month - 3);

    final anomalies = <Anomaly>[];

    for (final entry in current.entries) {
      final category = entry.key;
      final currentAmount = entry.value;

      final history = <double>[];
      if (m1.containsKey(category)) history.add(m1[category]!);
      if (m2.containsKey(category)) history.add(m2[category]!);
      if (m3.containsKey(category)) history.add(m3[category]!);

      if (history.isEmpty) continue;

      final avg = history.fold(0.0, (a, b) => a + b) / history.length;
      if (avg == 0) continue;

      final deviation = ((currentAmount - avg) / avg) * 100;

      if (deviation >= 20) {
        final severity = deviation >= 50
            ? 'major'
            : deviation >= 30
            ? 'moderate'
            : 'minor';

        anomalies.add(
          Anomaly(
            category: category,
            expectedAmount: avg,
            actualAmount: currentAmount,
            deviation: deviation,
            severity: severity,
            description:
                '🚨 Your $category spending is ${deviation.toInt()}% '
                'higher than usual (PKR ${currentAmount.toStringAsFixed(0)} '
                'vs avg PKR ${avg.toStringAsFixed(0)})',
            detectedAt: now,
          ),
        );
      }
    }

    anomalies.sort((a, b) => b.deviation.compareTo(a.deviation));
    return anomalies;
  }

  // ════════════════════════════════════════
  // 2. PREDICTION — WITH INFLATION ADJUSTMENT
  //
  // Base prediction = weighted avg of last 3 months
  // Inflation adjustment = multiply by annual inflation factor
  // This accounts for rising prices in Pakistan
  // ════════════════════════════════════════

  SpendingPrediction? _predictNextMonth(
    List<Transaction> transactions,
    EconomicData economic,
  ) {
    final now = DateTime.now();
    final m1 = _getTotalMonthExpense(transactions, now.year, now.month - 1);
    final m2 = _getTotalMonthExpense(transactions, now.year, now.month - 2);
    final m3 = _getTotalMonthExpense(transactions, now.year, now.month - 3);

    if (m1 == 0 && m2 == 0 && m3 == 0) return null;

    // Base weighted prediction
    double basePrediction;
    if (m1 > 0 && m2 > 0 && m3 > 0) {
      basePrediction = (m1 * 0.5) + (m2 * 0.3) + (m3 * 0.2);
    } else if (m1 > 0 && m2 > 0) {
      basePrediction = (m1 * 0.6) + (m2 * 0.4);
    } else {
      basePrediction = m1 > 0 ? m1 : m2;
    }

    // Apply monthly inflation factor
    // Annual 11.8% → monthly ≈ 0.93% increase
    final monthlyInflationFactor = 1 + (economic.inflationRate / 100 / 12);
    final inflationAdjusted = basePrediction * monthlyInflationFactor;

    final lastMonthCats = _getMonthExpenses(
      transactions,
      now.year,
      now.month - 1,
    );
    final lastTotal = lastMonthCats.values.fold(0.0, (a, b) => a + b);
    final Map<String, double> breakdown = {};
    if (lastTotal > 0) {
      for (final e in lastMonthCats.entries) {
        breakdown[e.key] = (e.value / lastTotal) * inflationAdjusted;
      }
    }

    return SpendingPrediction(
      predictedAmount: inflationAdjusted,
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
    if (savingsRate >= 20)
      strengths.add('Good savings rate (${savingsRate.toInt()}%)');
    else
      improvements.add(
        'Increase savings rate (currently ${savingsRate.toInt()}%)',
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
    final current = _getMonthExpenses(transactions, now.year, now.month);
    final prev = _getMonthExpenses(transactions, now.year, now.month - 1);
    if (current.isEmpty) return [];

    final sorted = current.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recommendations = <SavingsRecommendation>[];
    for (final entry in sorted.take(3)) {
      final category = entry.key;
      final currentAmt = entry.value;
      final prevAmt = prev[category] ?? currentAmt;
      final baseline = currentAmt < prevAmt
          ? currentAmt
          : (currentAmt + prevAmt) / 2;
      final recommended = baseline * 0.85;
      final savings = currentAmt - recommended;
      if (savings > 100) {
        recommendations.add(
          SavingsRecommendation(
            category: category,
            currentSpending: currentAmt,
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

    // Inflation-adjusted prediction insight
    if (_prediction != null && _economicData != null) {
      final inflation = _economicData!.inflationRate;
      insights.add(
        AIInsight(
          id: '${id++}',
          title: 'Next Month Prediction (Inflation-Adjusted)',
          description:
              'Based on your spending history + Pakistan\'s ${_economicData!.inflationLabel} '
              'inflation rate, you\'ll likely spend PKR ${_prediction!.predictedAmount.toStringAsFixed(0)} '
              'next month. Inflation adds ~PKR ${(_prediction!.predictedAmount * (inflation / 100 / 12)).toStringAsFixed(0)} '
              'to your baseline prediction. (${(_prediction!.confidence * 100).toInt()}% confidence)',
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
              'Save PKR ${rec.potentialSavings.toStringAsFixed(0)}/month by reducing ${rec.category} by 15%. ${rec.reason}.',
          type: InsightType.recommendation,
          priority: InsightPriority.medium,
          createdAt: now,
        ),
      );
    }

    // Savings rate tip
    final thisExpense = transactions
        .where(
          (t) =>
              t.isExpense &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (s, t) => s + t.amount);
    final thisIncome = transactions
        .where(
          (t) =>
              t.isIncome &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (s, t) => s + t.amount);
    if (thisIncome > 0) {
      final rate = ((thisIncome - thisExpense) / thisIncome * 100).clamp(
        0.0,
        100.0,
      );
      insights.add(
        AIInsight(
          id: '${id++}',
          title: 'This Month\'s Savings Rate',
          description: rate >= 20
              ? 'Great job! You\'ve saved ${rate.toInt()}% of income this month!'
              : 'Your savings rate is ${rate.toInt()}%. Aim for at least 20%.',
          type: InsightType.tip,
          priority: rate < 10 ? InsightPriority.high : InsightPriority.low,
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
        .fold(0.0, (s, t) => s + t.amount);
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
    _economicData = null;
    _notifiedAnomalies.clear();
    notifyListeners();
  }
}
