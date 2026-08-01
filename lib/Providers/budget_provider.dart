import 'package:flutter/foundation.dart';
import '../Models/budget.dart';
import '../Services/database_service.dart';
import '../Services/notification_service.dart';

class BudgetProvider extends ChangeNotifier {
  List<Budget> _budgets = [];
  bool _isLoading = false;
  String? _error;

  final DatabaseService _dbService = DatabaseService.instance;

  // Track which budgets have been notified in this session
  // to avoid spamming the user on every sync
  final Set<String> _notifiedThisSession = {};

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
    } catch (_) {
      return null;
    }
  }

  BudgetSummary getBudgetSummary() =>
      BudgetSummary.fromBudgets(currentMonthBudgets);

  List<Budget> getBudgetsByStatus(BudgetStatus status) =>
      currentMonthBudgets.where((b) => b.status == status).toList();

  bool isBudgetExceeded(String category) =>
      getBudgetByCategory(category)?.isExceeded ?? false;

  bool isBudgetNearLimit(String category) =>
      getBudgetByCategory(category)?.isNearLimit ?? false;

  // ════════════════════════════════════════
  // LOAD
  // ════════════════════════════════════════

  Future<void> loadBudgets() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final storedBudgets = await _dbService.getAllBudgets();
      final spending = await _dbService.getMonthlySpendingByCategory();

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

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════
  // ADD
  // ════════════════════════════════════════

  Future<void> addBudget(Budget budget) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final existing = getBudgetByCategory(budget.category);
      if (existing != null) {
        throw Exception(
          'A budget for ${budget.category} already exists this month.',
        );
      }

      await _dbService.createBudget(budget);

      final spending = await _dbService.getMonthlySpendingByCategory();
      final spent = spending[budget.category] ?? 0.0;
      _budgets.add(budget.copyWith(used: spent));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ════════════════════════════════════════
  // UPDATE
  // ════════════════════════════════════════

  Future<void> updateBudget(Budget budget) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.updateBudget(budget);
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) _budgets[index] = budget;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ════════════════════════════════════════
  // DELETE
  // ════════════════════════════════════════

  Future<void> deleteBudget(String budgetId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.deleteBudget(budgetId);
      _budgets.removeWhere((b) => b.id == budgetId);
      _notifiedThisSession.remove(budgetId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ════════════════════════════════════════
  // SYNC — called after every expense add/edit/delete
  // This is the KEY method — it updates spending AND fires notifications
  // ════════════════════════════════════════

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

      notifyListeners();

      // ── Fire notifications for budgets crossing the 80% threshold ──
      await _checkAndNotifyBudgets();
    } catch (e) {
      print('❌ syncWithTransactions: $e');
    }
  }

  // ════════════════════════════════════════
  // BUDGET ALERT NOTIFICATIONS
  // Fires a push notification when a budget first crosses 80% or 100%
  // in this session. Uses a composite key (id + level) so it notifies
  // once at 80% and again if the budget is then exceeded (100%).
  // ════════════════════════════════════════

  // Called by MainNavigation on launch
  Future<void> checkAndNotify({required bool enabled}) async {
    if (!enabled) return;
    await _checkAndNotifyBudgets();
  }

  Future<void> _checkAndNotifyBudgets({double threshold = 80.0}) async {
    for (final budget in currentMonthBudgets) {
      final pct = budget.percentageUsed;

      // Determine notification level
      final String? level = pct >= 100
          ? 'exceeded'
          : pct >= threshold
          ? 'warning'
          : null;

      if (level == null) continue;

      final notifyKey = '${budget.id}_$level';
      if (_notifiedThisSession.contains(notifyKey)) continue;

      _notifiedThisSession.add(notifyKey);

      await NotificationService.instance.showBudgetAlertNotification(
        category: budget.category,
        usedAmount: budget.used,
        limitAmount: budget.limit,
        percentage: pct,
      );

      print('🔔 Budget alert ($level): ${budget.category} at ${pct.toInt()}%');
    }
  }

  // ════════════════════════════════════════
  // RESET MONTHLY
  // ════════════════════════════════════════

  Future<void> resetMonthlyBudgets() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      for (final budget in currentMonthBudgets) {
        await _dbService.updateBudget(budget.copyWith(isActive: false));
        final newBudget = Budget.monthly(
          id: '${budget.id}_${DateTime.now().millisecondsSinceEpoch}',
          category: budget.category,
          limit: budget.limit,
        );
        await _dbService.createBudget(newBudget);
      }

      _notifiedThisSession.clear();
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
    _notifiedThisSession.clear();
    notifyListeners();
  }
}
