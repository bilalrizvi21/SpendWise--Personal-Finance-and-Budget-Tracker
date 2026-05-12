import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../Models/transaction.dart';
import '../Services/database_service.dart';
import 'budget_provider.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  final DatabaseService _dbService = DatabaseService.instance;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Transaction> get incomeTransactions =>
      _transactions.where((t) => t.isIncome).toList();

  List<Transaction> get expenseTransactions =>
      _transactions.where((t) => t.isExpense).toList();

  /// Returns transactions whose date falls within [startDate, endDate] inclusive.
  /// Compares only the date portion (year, month, day) — not the time component.
  /// This fixes the "today shows yesterday" bug caused by the old isAfter/isBefore
  /// logic which was off by one day.
  List<Transaction> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    // Normalise both bounds to midnight so time-of-day never affects comparison
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return _transactions.where((t) {
      final txDate = DateTime(t.date.year, t.date.month, t.date.day);
      return !txDate.isBefore(start) && !txDate.isAfter(end);
    }).toList();
  }

  // ── Today: exactly today's date ──
  List<Transaction> get todayTransactions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return getTransactionsByDateRange(today, today); // same start and end
  }

  // ── This week: Monday → Sunday of the current week ──
  List<Transaction> get thisWeekTransactions {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return getTransactionsByDateRange(startOfWeek, endOfWeek);
  }

  // ── This month: 1st → last day of current month ──
  List<Transaction> get thisMonthTransactions {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getTransactionsByDateRange(startOfMonth, endOfMonth);
  }

  // ── Custom range ──
  List<Transaction> getTransactionsForCustomRange(
    DateTime start,
    DateTime end,
  ) {
    return getTransactionsByDateRange(start, end);
  }

  TransactionSummary getTransactionSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? DateTime(now.year, now.month + 1, 0);
    return TransactionSummary.fromTransactions(
      getTransactionsByDateRange(start, end),
      start,
      end,
    );
  }

  List<CategorySummary> getCategorySummary({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filtered = startDate != null && endDate != null
        ? getTransactionsByDateRange(startDate, endDate)
        : expenseTransactions;

    final Map<String, double> totals = {};
    final Map<String, int> counts = {};

    for (var t in filtered) {
      if (t.isExpense) {
        totals[t.category] = (totals[t.category] ?? 0) + t.amount;
        counts[t.category] = (counts[t.category] ?? 0) + 1;
      }
    }

    final totalExpense = totals.values.fold(0.0, (a, b) => a + b);

    return totals.entries
        .map(
          (e) => CategorySummary(
            category: e.key,
            amount: e.value,
            count: counts[e.key] ?? 0,
            percentage: totalExpense > 0 ? (e.value / totalExpense * 100) : 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<Transaction> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;
    final q = query.toLowerCase();
    return _transactions
        .where(
          (t) =>
              t.category.toLowerCase().contains(q) ||
              t.notes?.toLowerCase().contains(q) == true ||
              t.amount.toString().contains(query),
        )
        .toList();
  }

  Future<void> addTransaction(
    Transaction transaction, {
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.createTransaction(transaction);
      _transactions.add(transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      _isLoading = false;
      notifyListeners();

      if (transaction.isExpense && context != null) {
        Provider.of<BudgetProvider>(
          context,
          listen: false,
        ).syncWithTransactions();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void addTransactionToList(Transaction transaction) {
    _transactions.add(transaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> updateTransaction(
    Transaction transaction, {
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }

      _isLoading = false;
      notifyListeners();

      if (context != null) {
        Provider.of<BudgetProvider>(
          context,
          listen: false,
        ).syncWithTransactions();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTransaction(
    String transactionId, {
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.deleteTransaction(transactionId);
      _transactions.removeWhere((t) => t.id == transactionId);

      _isLoading = false;
      notifyListeners();

      if (context != null) {
        Provider.of<BudgetProvider>(
          context,
          listen: false,
        ).syncWithTransactions();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadTransactions() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _transactions = await _dbService.getAllTransactions();
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearTransactions() {
    _transactions = [];
    notifyListeners();
  }

  Future<void> deleteAllTransactions() async {
    try {
      await _dbService.deleteAllTransactions();
      _transactions = [];
      notifyListeners();
    } catch (e) {
      print('❌ Error deleting all transactions: $e');
    }
  }
}
