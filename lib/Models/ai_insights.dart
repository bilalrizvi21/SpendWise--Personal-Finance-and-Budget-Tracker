import 'package:flutter/material.dart';

class AIInsight {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final InsightPriority priority;
  final String? actionable;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;
  final bool isDismissed;

  AIInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    this.actionable,
    this.data,
    required this.createdAt,
    this.isRead = false,
    this.isDismissed = false,
  });

  // Get icon based on insight type
  IconData get icon {
    switch (type) {
      case InsightType.prediction:
        return Icons.trending_up;
      case InsightType.anomaly:
        return Icons.warning_amber;
      case InsightType.recommendation:
        return Icons.lightbulb;
      case InsightType.achievement:
        return Icons.emoji_events;
      case InsightType.warning:
        return Icons.error_outline;
      case InsightType.tip:
        return Icons.tips_and_updates;
    }
  }

  // Get color based on priority
  Color get color {
    switch (priority) {
      case InsightPriority.high:
        return const Color(0xFFF44336);
      case InsightPriority.medium:
        return const Color(0xFFFF9800);
      case InsightPriority.low:
        return const Color(0xFF2196F3);
    }
  }

  // Copy with method
  AIInsight copyWith({
    String? id,
    String? title,
    String? description,
    InsightType? type,
    InsightPriority? priority,
    String? actionable,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    bool? isDismissed,
  }) {
    return AIInsight(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      actionable: actionable ?? this.actionable,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'actionable': actionable,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isDismissed': isDismissed,
    };
  }

  // Create from JSON
  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: InsightType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InsightType.tip,
      ),
      priority: InsightPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => InsightPriority.low,
      ),
      actionable: json['actionable'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isDismissed: json['isDismissed'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'AIInsight(id: $id, title: $title, type: ${type.name}, priority: ${priority.name})';
  }
}

// Insight Types
enum InsightType {
  prediction,
  anomaly,
  recommendation,
  achievement,
  warning,
  tip,
}

// Insight Priority
enum InsightPriority { high, medium, low }

// Spending Prediction
class SpendingPrediction {
  final double predictedAmount;
  final String period; // 'next_week', 'next_month'
  final double confidence; // 0.0 to 1.0
  final Map<String, double>? categoryBreakdown;
  final DateTime generatedAt;

  SpendingPrediction({
    required this.predictedAmount,
    required this.period,
    required this.confidence,
    this.categoryBreakdown,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'predictedAmount': predictedAmount,
      'period': period,
      'confidence': confidence,
      'categoryBreakdown': categoryBreakdown,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory SpendingPrediction.fromJson(Map<String, dynamic> json) {
    return SpendingPrediction(
      predictedAmount: (json['predictedAmount'] as num).toDouble(),
      period: json['period'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      categoryBreakdown: json['categoryBreakdown'] != null
          ? Map<String, double>.from(json['categoryBreakdown'])
          : null,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }
}

// Spending Pattern
class SpendingPattern {
  final String pattern; // 'weekday_heavy', 'weekend_heavy', 'consistent'
  final String description;
  final Map<String, dynamic> details;
  final DateTime analyzedAt;

  SpendingPattern({
    required this.pattern,
    required this.description,
    required this.details,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'description': description,
      'details': details,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory SpendingPattern.fromJson(Map<String, dynamic> json) {
    return SpendingPattern(
      pattern: json['pattern'] as String,
      description: json['description'] as String,
      details: json['details'] as Map<String, dynamic>,
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    );
  }
}

// Anomaly Detection
class Anomaly {
  final String category;
  final double expectedAmount;
  final double actualAmount;
  final double deviation; // percentage
  final String severity; // 'minor', 'moderate', 'major'
  final String description;
  final DateTime detectedAt;

  Anomaly({
    required this.category,
    required this.expectedAmount,
    required this.actualAmount,
    required this.deviation,
    required this.severity,
    required this.description,
    required this.detectedAt,
  });

  bool get isMajor => severity == 'major';
  bool get isModerate => severity == 'moderate';
  bool get isMinor => severity == 'minor';

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'expectedAmount': expectedAmount,
      'actualAmount': actualAmount,
      'deviation': deviation,
      'severity': severity,
      'description': description,
      'detectedAt': detectedAt.toIso8601String(),
    };
  }

  factory Anomaly.fromJson(Map<String, dynamic> json) {
    return Anomaly(
      category: json['category'] as String,
      expectedAmount: (json['expectedAmount'] as num).toDouble(),
      actualAmount: (json['actualAmount'] as num).toDouble(),
      deviation: (json['deviation'] as num).toDouble(),
      severity: json['severity'] as String,
      description: json['description'] as String,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
    );
  }
}

// Savings Recommendation
class SavingsRecommendation {
  final String category;
  final double currentSpending;
  final double recommendedSpending;
  final double potentialSavings;
  final String reason;
  final List<String> actionSteps;
  final DateTime generatedAt;

  SavingsRecommendation({
    required this.category,
    required this.currentSpending,
    required this.recommendedSpending,
    required this.potentialSavings,
    required this.reason,
    required this.actionSteps,
    required this.generatedAt,
  });

  double get savingsPercentage =>
      (potentialSavings / currentSpending * 100).clamp(0, 100);

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'currentSpending': currentSpending,
      'recommendedSpending': recommendedSpending,
      'potentialSavings': potentialSavings,
      'reason': reason,
      'actionSteps': actionSteps,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory SavingsRecommendation.fromJson(Map<String, dynamic> json) {
    return SavingsRecommendation(
      category: json['category'] as String,
      currentSpending: (json['currentSpending'] as num).toDouble(),
      recommendedSpending: (json['recommendedSpending'] as num).toDouble(),
      potentialSavings: (json['potentialSavings'] as num).toDouble(),
      reason: json['reason'] as String,
      actionSteps: List<String>.from(json['actionSteps']),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }
}

// Financial Health Score
class FinancialHealthScore {
  final double score; // 0 to 100
  final String rating; // 'excellent', 'good', 'fair', 'poor'
  final Map<String, double> breakdown; // category scores
  final List<String> strengths;
  final List<String> improvements;
  final DateTime calculatedAt;

  FinancialHealthScore({
    required this.score,
    required this.rating,
    required this.breakdown,
    required this.strengths,
    required this.improvements,
    required this.calculatedAt,
  });

  Color get scoreColor {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'rating': rating,
      'breakdown': breakdown,
      'strengths': strengths,
      'improvements': improvements,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory FinancialHealthScore.fromJson(Map<String, dynamic> json) {
    return FinancialHealthScore(
      score: (json['score'] as num).toDouble(),
      rating: json['rating'] as String,
      breakdown: Map<String, double>.from(json['breakdown']),
      strengths: List<String>.from(json['strengths']),
      improvements: List<String>.from(json['improvements']),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }
}
