class Transaction {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String paymentMethod; // 'cash', 'card', 'digital_wallet'
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Check if transaction is income
  bool get isIncome => type.toLowerCase() == 'income';

  // Check if transaction is expense
  bool get isExpense => type.toLowerCase() == 'expense';

  // Get formatted amount with sign
  String get formattedAmount {
    return isIncome ? '+$amount' : '-$amount';
  }

  // Copy with method for updating transaction
  Transaction copyWith({
    String? id,
    double? amount,
    String? category,
    DateTime? date,
    String? type,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'type': type,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      paymentMethod: json['paymentMethod'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // Create empty transaction
  factory Transaction.empty() {
    return Transaction(
      id: '',
      amount: 0.0,
      category: '',
      date: DateTime.now(),
      type: 'expense',
      paymentMethod: 'cash',
      createdAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, amount: $amount, category: $category, type: $type, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Transaction Summary (for analytics)
class TransactionSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int incomeCount;
  final int expenseCount;
  final DateTime startDate;
  final DateTime endDate;

  TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.incomeCount,
    required this.expenseCount,
    required this.startDate,
    required this.endDate,
  });

  // Calculate from list of transactions
  factory TransactionSummary.fromTransactions(
    List<Transaction> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    double totalIncome = 0;
    double totalExpense = 0;
    int incomeCount = 0;
    int expenseCount = 0;

    for (var transaction in transactions) {
      if (transaction.isIncome) {
        totalIncome += transaction.amount;
        incomeCount++;
      } else {
        totalExpense += transaction.amount;
        expenseCount++;
      }
    }

    return TransactionSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': balance,
      'incomeCount': incomeCount,
      'expenseCount': expenseCount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}

// Category Summary (spending per category)
class CategorySummary {
  final String category;
  final double amount;
  final int count;
  final double percentage;

  CategorySummary({
    required this.category,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'count': count,
      'percentage': percentage,
    };
  }
}
