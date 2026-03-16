import 'package:flutter/foundation.dart';
import '../Models/goal.dart';
import '../Services/database_service.dart';

class GoalProvider extends ChangeNotifier {
  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _error;

  final DatabaseService _dbService = DatabaseService.instance;

  // Getters
  List<Goal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Goal> get activeGoals => _goals.where((g) => !g.isCompleted).toList();
  List<Goal> get completedGoals => _goals.where((g) => g.isCompleted).toList();
  List<Goal> get goalsNearDeadline =>
      activeGoals.where((g) => g.isDeadlineNear).toList();
  List<Goal> get overdueGoals => activeGoals.where((g) => g.isOverdue).toList();
  List<Goal> get achievedGoals =>
      activeGoals.where((g) => g.isAchieved && !g.isCompleted).toList();

  List<Goal> getGoalsByStatus(GoalStatus status) =>
      _goals.where((g) => g.status == status).toList();

  GoalSummary getGoalSummary() => GoalSummary.fromGoals(_goals);

  Goal? getGoalById(String id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== LOAD ==========

  Future<void> loadGoals() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _goals = await _dbService.getAllGoals();
      _sortGoals();

      print('✅ Loaded ${_goals.length} goals from database');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('❌ Error loading goals: $e');
      notifyListeners();
    }
  }

  // ========== ADD ==========

  Future<void> addGoal(Goal goal) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.createGoal(goal);
      _goals.add(goal);
      _sortGoals();

      print('✅ Goal added: ${goal.name}');

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

  Future<void> updateGoal(Goal goal) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.updateGoal(goal);

      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
      }
      _sortGoals();

      print('✅ Goal updated: ${goal.name}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========== ADD AMOUNT ==========

  Future<void> addAmountToGoal(String goalId, double amount) async {
    final goal = getGoalById(goalId);
    if (goal != null) {
      final updatedGoal = goal.addAmount(amount);
      await updateGoal(updatedGoal);
    }
  }

  // ========== COMPLETE ==========

  Future<void> completeGoal(String goalId) async {
    final goal = getGoalById(goalId);
    if (goal != null) {
      final updatedGoal = goal.markCompleted();
      await updateGoal(updatedGoal);
    }
  }

  // ========== DELETE ==========

  Future<void> deleteGoal(String goalId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.deleteGoal(goalId);
      _goals.removeWhere((g) => g.id == goalId);

      print('✅ Goal deleted: $goalId');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearGoals() {
    _goals = [];
    notifyListeners();
  }

  // Sort: active first (by deadline), then completed
  void _sortGoals() {
    _goals.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      if (a.deadline != null) return -1;
      if (b.deadline != null) return 1;
      return 0;
    });
  }
}
