import 'package:flutter/foundation.dart';
import '../Models/budget.dart';
import '../Services/database_service.dart';

class BudgetProvider extends ChangeNotifier {
  List<Budget> _budgets = [];
  bool _isLoading = false;
  String? _error;

  final DatabaseService _dbService = DatabaseService.instance;

  // Getters
  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Budget> get activeBudgets => _budgets.where((b) => b.isActive).toList();

  List<Budget> get currentMonthBudgets =>
      _budgets.where((b) => b.isCurrent).toList();

  Budget? getBudgetByCategory(String category) {
    try {
      return _budgets.firstWhere(
        (b) =>
            b.category.toLowerCase() == category.toLowerCase() && b.isCurrent,
      );
    } catch (e) {
      return null;
    }
  }

  BudgetSummary getBudgetSummary() {
    return BudgetSummary.fromBudgets(currentMonthBudgets);
  }

  List<Budget> getBudgetsByStatus(BudgetStatus status) {
    return currentMonthBudgets.where((b) => b.status == status).toList();
  }

  bool isBudgetExceeded(String category) =>
      getBudgetByCategory(category)?.isExceeded ?? false;

  bool isBudgetNearLimit(String category) =>
      getBudgetByCategory(category)?.isNearLimit ?? false;

  // ========== LOAD ==========

  /// Load budgets from DB and calculate real spending from transactions
  Future<void> loadBudgets() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // 1. Load stored budget limits from DB
      final storedBudgets = await _dbService.getAllBudgets();

      // 2. Get real monthly spending per category from transactions table
      final spending = await _dbService.getMonthlySpendingByCategory();

      // 3. Merge: attach real spending to each budget
      _budgets = storedBudgets.map((budget) {
        final spent =
            spending[budget.category] ??
            spending.entries
                .firstWhere(
                  (e) => e.key.toLowerCase() == budget.category.toLowerCase(),
                  orElse: () => const MapEntry('', 0.0),
                )
                .value;
        return budget.copyWith(used: spent);
      }).toList();

      print('✅ Loaded ${_budgets.length} budgets with real spending data');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('❌ Error loading budgets: $e');
      notifyListeners();
    }
  }

  // ========== ADD ==========

  Future<void> addBudget(Budget budget) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if budget for this category already exists this month
      final existing = getBudgetByCategory(budget.category);
      if (existing != null) {
        throw Exception(
          'A budget for ${budget.category} already exists this month.',
        );
      }

      // Save to DB
      await _dbService.createBudget(budget);

      // Get real spending for this category and attach it
      final spending = await _dbService.getMonthlySpendingByCategory();
      final spent = spending[budget.category] ?? 0.0;
      final budgetWithSpending = budget.copyWith(used: spent);

      _budgets.add(budgetWithSpending);

      print('✅ Budget added: ${budget.category}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========== UPDATE ==========

  Future<void> updateBudget(Budget budget) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.updateBudget(budget);

      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        _budgets[index] = budget;
      }

      print('✅ Budget updated: ${budget.category}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========== DELETE ==========

  Future<void> deleteBudget(String budgetId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.deleteBudget(budgetId);
      _budgets.removeWhere((b) => b.id == budgetId);

      print('✅ Budget deleted: $budgetId');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========== SYNC WITH TRANSACTIONS ==========

  /// Called automatically after a new expense transaction is added.
  /// Re-fetches spending from DB so budget 'used' values are always accurate.
  Future<void> syncWithTransactions() async {
    try {
      if (_budgets.isEmpty) return;

      final spending = await _dbService.getMonthlySpendingByCategory();

      _budgets = _budgets.map((budget) {
        final spent = spending.entries
            .firstWhere(
              (e) => e.key.toLowerCase() == budget.category.toLowerCase(),
              orElse: () => const MapEntry('', 0.0),
            )
            .value;
        return budget.copyWith(used: spent);
      }).toList();

      print('🔄 Budget spending synced with transactions');
      notifyListeners();
    } catch (e) {
      print('❌ Error syncing budgets: $e');
    }
  }

  // ========== RESET MONTHLY ==========

  /// Creates fresh budgets for the new month (same limits, zero spending)
  Future<void> resetMonthlyBudgets() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      for (var budget in currentMonthBudgets) {
        // Mark old budget inactive
        await _dbService.updateBudget(budget.copyWith(isActive: false));

        // Create new budget for current month
        final newBudget = Budget.monthly(
          id: '${budget.id}_${DateTime.now().millisecondsSinceEpoch}',
          category: budget.category,
          limit: budget.limit,
        );
        await _dbService.createBudget(newBudget);
      }

      // Reload fresh
      await loadBudgets();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearBudgets() {
    _budgets = [];
    notifyListeners();
  }
}
