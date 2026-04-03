class RecurringTransaction {
  final String id;
  final String name; // e.g. "Netflix Subscription"
  final double amount;
  final String category;
  final String type; // 'income' or 'expense'
  final String paymentMethod;
  final int dayOfMonth; // 1-28, day to fire each month
  final DateTime nextDueDate; // next scheduled date
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? notes;

  RecurringTransaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.type,
    required this.paymentMethod,
    required this.dayOfMonth,
    required this.nextDueDate,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.notes,
  });

  bool get isExpense => type.toLowerCase() == 'expense';
  bool get isIncome => type.toLowerCase() == 'income';

  /// Whether this recurring transaction is due today or overdue
  bool get isDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(
      nextDueDate.year,
      nextDueDate.month,
      nextDueDate.day,
    );
    return !dueDay.isAfter(today);
  }

  /// Calculate the next due date after processing (next month, same day)
  DateTime get nextMonthDueDate {
    final next = DateTime(nextDueDate.year, nextDueDate.month + 1, dayOfMonth);
    return next;
  }

  /// Days until next due
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(
      nextDueDate.year,
      nextDueDate.month,
      nextDueDate.day,
    );
    return dueDay.difference(today).inDays;
  }

  RecurringTransaction copyWith({
    String? id,
    String? name,
    double? amount,
    String? category,
    String? type,
    String? paymentMethod,
    int? dayOfMonth,
    DateTime? nextDueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? notes,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'category': category,
    'type': type,
    'paymentMethod': paymentMethod,
    'dayOfMonth': dayOfMonth,
    'nextDueDate': nextDueDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'isActive': isActive ? 1 : 0,
    'notes': notes,
  };

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      RecurringTransaction(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        type: json['type'] as String,
        paymentMethod: json['paymentMethod'] as String,
        dayOfMonth: json['dayOfMonth'] as int,
        nextDueDate: DateTime.parse(json['nextDueDate'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        isActive: (json['isActive'] as int) == 1,
        notes: json['notes'] as String?,
      );
}
