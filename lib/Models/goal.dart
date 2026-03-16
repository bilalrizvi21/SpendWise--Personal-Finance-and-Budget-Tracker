class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  // Calculate remaining amount
  double get remainingAmount => targetAmount - currentAmount;

  // Calculate percentage completed
  double get percentageCompleted =>
      (currentAmount / targetAmount * 100).clamp(0, 100);

  // Check if goal is achieved
  bool get isAchieved => currentAmount >= targetAmount;

  // Calculate days remaining until deadline
  int? get daysRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    if (deadline!.isBefore(now)) return 0;
    return deadline!.difference(now).inDays;
  }

  // Check if deadline is near (within 7 days)
  bool get isDeadlineNear {
    if (daysRemaining == null) return false;
    return daysRemaining! <= 7 && daysRemaining! > 0;
  }

  // Check if deadline has passed
  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!) && !isCompleted;
  }

  // Calculate required monthly savings to reach goal
  double? get requiredMonthlySavings {
    if (deadline == null || isCompleted) return null;

    final now = DateTime.now();
    if (deadline!.isBefore(now)) return null;

    final monthsRemaining = (deadline!.difference(now).inDays / 30).ceil();
    if (monthsRemaining <= 0) return null;

    return remainingAmount / monthsRemaining;
  }

  // Get goal status
  GoalStatus get status {
    if (isCompleted) return GoalStatus.completed;
    if (isOverdue) return GoalStatus.overdue;
    if (isAchieved) return GoalStatus.achieved;
    if (percentageCompleted >= 75) return GoalStatus.onTrack;
    if (isDeadlineNear) return GoalStatus.nearDeadline;
    return GoalStatus.inProgress;
  }

  // Copy with method
  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Add amount to goal
  Goal addAmount(double amount) {
    final newAmount = currentAmount + amount;
    final completed = newAmount >= targetAmount;

    return copyWith(
      currentAmount: newAmount,
      isCompleted: completed,
      completedAt: completed && completedAt == null
          ? DateTime.now()
          : completedAt,
      updatedAt: DateTime.now(),
    );
  }

  // Mark as completed
  Goal markCompleted() {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  // Create empty goal
  factory Goal.empty() {
    return Goal(
      id: '',
      name: '',
      targetAmount: 0.0,
      currentAmount: 0.0,
      createdAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Goal(id: $id, name: $name, target: $targetAmount, current: $currentAmount, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Goal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Goal Status Enum
enum GoalStatus {
  inProgress,
  onTrack,
  nearDeadline,
  achieved,
  overdue,
  completed,
}

// Goal Summary
class GoalSummary {
  final int totalGoals;
  final int completedGoals;
  final int activeGoals;
  final int overdueGoals;
  final double totalTargetAmount;
  final double totalCurrentAmount;
  final double totalRemainingAmount;
  final double overallProgress;

  GoalSummary({
    required this.totalGoals,
    required this.completedGoals,
    required this.activeGoals,
    required this.overdueGoals,
    required this.totalTargetAmount,
    required this.totalCurrentAmount,
    required this.totalRemainingAmount,
    required this.overallProgress,
  });

  // Calculate from list of goals
  factory GoalSummary.fromGoals(List<Goal> goals) {
    int completed = 0;
    int active = 0;
    int overdue = 0;
    double totalTarget = 0;
    double totalCurrent = 0;

    for (var goal in goals) {
      totalTarget += goal.targetAmount;
      totalCurrent += goal.currentAmount;

      if (goal.isCompleted) {
        completed++;
      } else if (goal.isOverdue) {
        overdue++;
      } else {
        active++;
      }
    }

    return GoalSummary(
      totalGoals: goals.length,
      completedGoals: completed,
      activeGoals: active,
      overdueGoals: overdue,
      totalTargetAmount: totalTarget,
      totalCurrentAmount: totalCurrent,
      totalRemainingAmount: totalTarget - totalCurrent,
      overallProgress: totalTarget > 0 ? (totalCurrent / totalTarget * 100) : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalGoals': totalGoals,
      'completedGoals': completedGoals,
      'activeGoals': activeGoals,
      'overdueGoals': overdueGoals,
      'totalTargetAmount': totalTargetAmount,
      'totalCurrentAmount': totalCurrentAmount,
      'totalRemainingAmount': totalRemainingAmount,
      'overallProgress': overallProgress,
    };
  }
}
