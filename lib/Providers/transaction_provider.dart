import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import '../Models/transaction.dart';
import '../Services/database_service.dart';
import 'budget_provider.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  final DatabaseService _dbService = DatabaseService.instance;

  // Getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Transaction> get incomeTransactions =>
      _transactions.where((t) => t.isIncome).toList();

  List<Transaction> get expenseTransactions =>
      _transactions.where((t) => t.isExpense).toList();

  List<Transaction> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _transactions.where((t) {
      return t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  List<Transaction> get todayTransactions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return getTransactionsByDateRange(today, tomorrow);
  }

  List<Transaction> get thisWeekTransactions {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return getTransactionsByDateRange(startOfWeek, endOfWeek);
  }

  List<Transaction> get thisMonthTransactions {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getTransactionsByDateRange(startOfMonth, endOfMonth);
  }

  TransactionSummary getTransactionSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? DateTime(now.year, now.month + 1, 0);
    final filteredTransactions = getTransactionsByDateRange(start, end);
    return TransactionSummary.fromTransactions(
      filteredTransactions,
      start,
      end,
    );
  }

  List<CategorySummary> getCategorySummary({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filteredTransactions = startDate != null && endDate != null
        ? getTransactionsByDateRange(startDate, endDate)
        : expenseTransactions;

    final Map<String, double> categoryTotals = {};
    final Map<String, int> categoryCounts = {};

    for (var transaction in filteredTransactions) {
      if (transaction.isExpense) {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
        categoryCounts[transaction.category] =
            (categoryCounts[transaction.category] ?? 0) + 1;
      }
    }

    final totalExpense = categoryTotals.values.fold(0.0, (a, b) => a + b);

    return categoryTotals.entries.map((entry) {
      return CategorySummary(
        category: entry.key,
        amount: entry.value,
        count: categoryCounts[entry.key] ?? 0,
        percentage: totalExpense > 0 ? (entry.value / totalExpense * 100) : 0,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<Transaction> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;
    final lowerQuery = query.toLowerCase();
    return _transactions.where((t) {
      return t.category.toLowerCase().contains(lowerQuery) ||
          t.notes?.toLowerCase().contains(lowerQuery) == true ||
          t.amount.toString().contains(query);
    }).toList();
  }

  // ========== ADD - Syncs budgets automatically! ==========

  Future<void> addTransaction(
    Transaction transaction, {
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('💾 Saving transaction to database...');
      await _dbService.createTransaction(transaction);

      _transactions.add(transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      print('✅ Transaction saved successfully!');

      _isLoading = false;
      notifyListeners();

      // 🔄 Auto-sync budget spending if it's an expense
      if (transaction.isExpense && context != null) {
        final budgetProvider = Provider.of<BudgetProvider>(
          context,
          listen: false,
        );
        await budgetProvider.syncWithTransactions();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('❌ Error saving transaction: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTransaction(
    Transaction transaction, {
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔍 Updating transaction in database...');
      await _dbService.updateTransaction(transaction);

      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }

      print('✅ Transaction updated successfully!');

      _isLoading = false;
      notifyListeners();

      // 🔄 Re-sync budgets after update too
      if (context != null) {
        final budgetProvider = Provider.of<BudgetProvider>(
          context,
          listen: false,
        );
        await budgetProvider.syncWithTransactions();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('❌ Error updating transaction: $e');
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

      print('🗑️ Deleting transaction from database...');
      await _dbService.deleteTransaction(transactionId);
      _transactions.removeWhere((t) => t.id == transactionId);

      print('✅ Transaction deleted successfully!');

      _isLoading = false;
      notifyListeners();

      // 🔄 Re-sync budgets after delete
      if (context != null) {
        final budgetProvider = Provider.of<BudgetProvider>(
          context,
          listen: false,
        );
        await budgetProvider.syncWithTransactions();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('❌ Error deleting transaction: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadTransactions() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('📖 Loading transactions from database...');
      _transactions = await _dbService.getAllTransactions();
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      print('✅ Loaded ${_transactions.length} transactions from database!');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('❌ Error loading transactions: $e');
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
      print('✅ All transactions deleted from database!');
    } catch (e) {
      print('❌ Error deleting all transactions: $e');
    }
  }
}
