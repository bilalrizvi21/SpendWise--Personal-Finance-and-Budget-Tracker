import 'package:flutter/foundation.dart';
import 'package:spendwise_2/Models/ai_insights.dart';

class AIInsightsProvider extends ChangeNotifier {
  List<AIInsight> _insights = [];
  SpendingPrediction? _prediction;
  FinancialHealthScore? _healthScore;
  List<Anomaly> _anomalies = [];
  List<SavingsRecommendation> _recommendations = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AIInsight> get insights => _insights;
  SpendingPrediction? get prediction => _prediction;
  FinancialHealthScore? get healthScore => _healthScore;
  List<Anomaly> get anomalies => _anomalies;
  List<SavingsRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get unread insights
  List<AIInsight> get unreadInsights =>
      _insights.where((i) => !i.isRead).toList();

  // Get insights by type
  List<AIInsight> getInsightsByType(InsightType type) {
    return _insights.where((i) => i.type == type).toList();
  }

  // Get insights by priority
  List<AIInsight> getInsightsByPriority(InsightPriority priority) {
    return _insights.where((i) => i.priority == priority).toList();
  }

  // Get active insights (not dismissed)
  List<AIInsight> get activeInsights =>
      _insights.where((i) => !i.isDismissed).toList();

  // Generate insights
  Future<void> generateInsights() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: Call ML API to generate insights
      await Future.delayed(const Duration(seconds: 2));

      // Mock insights
      _insights = _generateMockInsights();
      _prediction = _generateMockPrediction();
      _healthScore = _generateMockHealthScore();
      _anomalies = _generateMockAnomalies();
      _recommendations = _generateMockRecommendations();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark insight as read
  Future<void> markInsightAsRead(String insightId) async {
    final index = _insights.indexWhere((i) => i.id == insightId);
    if (index != -1) {
      _insights[index] = _insights[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // Dismiss insight
  Future<void> dismissInsight(String insightId) async {
    final index = _insights.indexWhere((i) => i.id == insightId);
    if (index != -1) {
      _insights[index] = _insights[index].copyWith(isDismissed: true);
      notifyListeners();
    }
  }

  // Generate spending prediction
  Future<void> generatePrediction() async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Call ML API
      await Future.delayed(const Duration(seconds: 1));

      _prediction = _generateMockPrediction();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate financial health score
  Future<void> calculateHealthScore() async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Call ML API
      await Future.delayed(const Duration(seconds: 1));

      _healthScore = _generateMockHealthScore();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Detect anomalies
  Future<void> detectAnomalies() async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Call ML API
      await Future.delayed(const Duration(seconds: 1));

      _anomalies = _generateMockAnomalies();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate mock insights
  List<AIInsight> _generateMockInsights() {
    return [
      AIInsight(
        id: '1',
        title: 'Predicted Next Month Expense',
        description:
            'Based on your spending pattern, you\'ll likely spend PKR 34,500 next month.',
        type: InsightType.prediction,
        priority: InsightPriority.medium,
        createdAt: DateTime.now(),
      ),
      AIInsight(
        id: '2',
        title: 'Spending Behavior',
        description:
            'You spend 40% more on weekends. Consider meal planning to reduce food expenses.',
        type: InsightType.tip,
        priority: InsightPriority.low,
        createdAt: DateTime.now(),
      ),
      AIInsight(
        id: '3',
        title: 'Unusual Spike Detected',
        description:
            'Your transport expenses increased by 35% this month. Check for subscription renewals.',
        type: InsightType.anomaly,
        priority: InsightPriority.high,
        createdAt: DateTime.now(),
      ),
      AIInsight(
        id: '4',
        title: 'Savings Recommendation',
        description:
            'You can save PKR 5,000/month by reducing entertainment budget by 30%.',
        type: InsightType.recommendation,
        priority: InsightPriority.medium,
        createdAt: DateTime.now(),
      ),
      AIInsight(
        id: '5',
        title: 'Smart Suggestion',
        description:
            'Set up automatic transfers of PKR 3,000 to your savings goal every payday.',
        type: InsightType.tip,
        priority: InsightPriority.low,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Generate mock prediction
  SpendingPrediction _generateMockPrediction() {
    return SpendingPrediction(
      predictedAmount: 34500,
      period: 'next_month',
      confidence: 0.85,
      categoryBreakdown: {
        'Food': 11000,
        'Transport': 8500,
        'Bills': 6000,
        'Entertainment': 4000,
        'Shopping': 5000,
      },
      generatedAt: DateTime.now(),
    );
  }

  // Generate mock health score
  FinancialHealthScore _generateMockHealthScore() {
    return FinancialHealthScore(
      score: 75,
      rating: 'good',
      breakdown: {
        'Savings Rate': 80,
        'Budget Adherence': 70,
        'Debt Management': 85,
        'Emergency Fund': 60,
      },
      strengths: ['Good savings rate', 'Low debt', 'Consistent income'],
      improvements: [
        'Build emergency fund',
        'Reduce entertainment spending',
        'Set up automatic savings',
      ],
      calculatedAt: DateTime.now(),
    );
  }

  // Generate mock anomalies
  List<Anomaly> _generateMockAnomalies() {
    return [
      Anomaly(
        category: 'Food',
        expectedAmount: 8000,
        actualAmount: 11200,
        deviation: 40,
        severity: 'moderate',
        description: 'Food spending 40% higher than usual',
        detectedAt: DateTime.now(),
      ),
      Anomaly(
        category: 'Transport',
        expectedAmount: 4000,
        actualAmount: 8500,
        deviation: 112,
        severity: 'major',
        description: 'Significant increase in transport costs',
        detectedAt: DateTime.now(),
      ),
    ];
  }

  // Generate mock recommendations
  List<SavingsRecommendation> _generateMockRecommendations() {
    return [
      SavingsRecommendation(
        category: 'Entertainment',
        currentSpending: 5000,
        recommendedSpending: 3500,
        potentialSavings: 1500,
        reason: 'Entertainment spending is above average',
        actionSteps: [
          'Cancel unused subscriptions',
          'Look for free entertainment options',
          'Set a monthly entertainment budget',
        ],
        generatedAt: DateTime.now(),
      ),
      SavingsRecommendation(
        category: 'Food',
        currentSpending: 11200,
        recommendedSpending: 8000,
        potentialSavings: 3200,
        reason: 'Food expenses are 40% above budget',
        actionSteps: [
          'Plan meals in advance',
          'Cook at home more often',
          'Buy groceries in bulk',
        ],
        generatedAt: DateTime.now(),
      ),
    ];
  }

  // Clear all insights
  void clearInsights() {
    _insights = [];
    _prediction = null;
    _healthScore = null;
    _anomalies = [];
    _recommendations = [];
    notifyListeners();
  }
}
