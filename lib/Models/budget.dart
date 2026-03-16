class Budget {
  final String id;
  final String category;
  final double limit;
  final double used;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.used,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Calculate remaining amount
  double get remaining => limit - used;

  // Calculate percentage used
  double get percentageUsed => (used / limit * 100).clamp(0, 100);

  // Check if budget is exceeded
  bool get isExceeded => used > limit;

  // Check if budget is near limit (80% or more)
  bool get isNearLimit => percentageUsed >= 80;

  // Get status
  BudgetStatus get status {
    if (isExceeded) return BudgetStatus.exceeded;
    if (isNearLimit) return BudgetStatus.warning;
    return BudgetStatus.safe;
  }

  // Check if budget is current (active month)
  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate) && isActive;
  }

  // Copy with method
  Budget copyWith({
    String? id,
    String? category,
    double? limit,
    double? used,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      used: used ?? this.used,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'limit': limit,
      'used': used,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      category: json['category'] as String,
      limit: (json['limit'] as num).toDouble(),
      used: (json['used'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // Create empty budget
  factory Budget.empty() {
    return Budget(
      id: '',
      category: '',
      limit: 0.0,
      used: 0.0,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      createdAt: DateTime.now(),
    );
  }

  // Create monthly budget
  factory Budget.monthly({
    required String id,
    required String category,
    required double limit,
    double used = 0.0,
  }) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return Budget(
      id: id,
      category: category,
      limit: limit,
      used: used,
      startDate: startDate,
      endDate: endDate,
      createdAt: now,
    );
  }

  @override
  String toString() {
    return 'Budget(id: $id, category: $category, limit: $limit, used: $used, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Budget Status Enum
enum BudgetStatus { safe, warning, exceeded }

// Budget Summary
class BudgetSummary {
  final int totalBudgets;
  final int safeBudgets;
  final int warningBudgets;
  final int exceededBudgets;
  final double totalLimit;
  final double totalUsed;
  final double totalRemaining;

  BudgetSummary({
    required this.totalBudgets,
    required this.safeBudgets,
    required this.warningBudgets,
    required this.exceededBudgets,
    required this.totalLimit,
    required this.totalUsed,
    required this.totalRemaining,
  });

  // Calculate from list of budgets
  factory BudgetSummary.fromBudgets(List<Budget> budgets) {
    int safe = 0;
    int warning = 0;
    int exceeded = 0;
    double totalLimit = 0;
    double totalUsed = 0;

    for (var budget in budgets) {
      totalLimit += budget.limit;
      totalUsed += budget.used;

      switch (budget.status) {
        case BudgetStatus.safe:
          safe++;
          break;
        case BudgetStatus.warning:
          warning++;
          break;
        case BudgetStatus.exceeded:
          exceeded++;
          break;
      }
    }

    return BudgetSummary(
      totalBudgets: budgets.length,
      safeBudgets: safe,
      warningBudgets: warning,
      exceededBudgets: exceeded,
      totalLimit: totalLimit,
      totalUsed: totalUsed,
      totalRemaining: totalLimit - totalUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBudgets': totalBudgets,
      'safeBudgets': safeBudgets,
      'warningBudgets': warningBudgets,
      'exceededBudgets': exceededBudgets,
      'totalLimit': totalLimit,
      'totalUsed': totalUsed,
      'totalRemaining': totalRemaining,
    };
  }
}
