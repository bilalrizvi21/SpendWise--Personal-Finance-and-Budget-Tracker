import 'package:flutter/foundation.dart';
import '../Models/goal.dart';
import '../Services/database_service.dart';
import '../Services/notification_service.dart';

class GoalProvider extends ChangeNotifier {
  List<Goal> _goals = [];
  bool _isLoading = false;
  String? _error;

  final DatabaseService _dbService = DatabaseService.instance;
  final Set<String> _notifiedThisSession = {};

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
    } catch (_) {
      return null;
    }
  }

  // ════════════════════════════════════════
  // LOAD
  // ════════════════════════════════════════

  Future<void> loadGoals() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _goals = await _dbService.getAllGoals();
      _sortGoals();

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

  Future<void> addGoal(Goal goal) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.createGoal(goal);
      _goals.add(goal);
      _sortGoals();

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

  Future<void> updateGoal(Goal goal) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.updateGoal(goal);
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) _goals[index] = goal;
      _sortGoals();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addAmountToGoal(String goalId, double amount) async {
    final goal = getGoalById(goalId);
    if (goal == null) return;
    await updateGoal(goal.addAmount(amount));
  }

  Future<void> completeGoal(String goalId) async {
    final goal = getGoalById(goalId);
    if (goal != null) {
      await updateGoal(goal.markCompleted());
      _notifiedThisSession.removeWhere((k) => k.startsWith(goalId));
    }
  }

  // ════════════════════════════════════════
  // DELETE
  // ════════════════════════════════════════

  Future<void> deleteGoal(String goalId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.deleteGoal(goalId);
      _goals.removeWhere((g) => g.id == goalId);
      _notifiedThisSession.removeWhere((k) => k.startsWith(goalId));

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
  // PUBLIC: called by MainNavigation after preferences are loaded
  // ════════════════════════════════════════

  Future<void> checkAndNotify({required bool enabled}) async {
    print(
      '🎯 GoalProvider.checkAndNotify — enabled=$enabled, activeGoals=${activeGoals.length}',
    );

    if (!enabled) {
      print('⏭️ Goal reminders disabled — skipping');
      return;
    }

    for (final goal in activeGoals) {
      print(
        '  🔍 Checking goal: "${goal.name}" | '
        'isAchieved=${goal.isAchieved} | '
        'isOverdue=${goal.isOverdue} | '
        'deadline=${goal.deadline} | '
        'daysRemaining=${_daysRemainingActual(goal)}',
      );

      // ── 1. Achieved (100% but not marked complete) ──
      if (goal.isAchieved) {
        final key = '${goal.id}_achieved';
        if (!_notifiedThisSession.contains(key)) {
          _notifiedThisSession.add(key);
          print('  🔔 Firing ACHIEVED notification for ${goal.name}');
          await NotificationService.instance.showGoalReminderNotification(
            goalName: goal.name,
            type: 'achieved',
            percentage: goal.percentageCompleted,
          );
        }
        continue;
      }

      // ── 2. Overdue (deadline passed) ──
      if (goal.isOverdue) {
        final key = '${goal.id}_overdue';
        if (!_notifiedThisSession.contains(key)) {
          _notifiedThisSession.add(key);
          print('  🔔 Firing OVERDUE notification for ${goal.name}');
          await NotificationService.instance.showGoalReminderNotification(
            goalName: goal.name,
            type: 'overdue',
            percentage: goal.percentageCompleted,
          );
        }
        continue;
      }

      // ── 3. Deadline within 7 days ──
      if (goal.deadline != null) {
        final days = _daysRemainingActual(goal);
        if (days != null && days <= 7) {
          final key = '${goal.id}_deadline_$days';
          if (!_notifiedThisSession.contains(key)) {
            _notifiedThisSession.add(key);
            print(
              '  🔔 Firing DEADLINE_NEAR notification for ${goal.name} ($days days)',
            );
            await NotificationService.instance.showGoalReminderNotification(
              goalName: goal.name,
              type: 'deadline_near',
              daysRemaining: days,
              percentage: goal.percentageCompleted,
            );
          }
        }
      }
    }
    print('✅ GoalProvider.checkAndNotify complete');
  }

  /// More accurate days remaining that includes today (day 0 = today, not overdue)
  /// The Goal model's daysRemaining returns 0 when isBefore(now) which incorrectly
  /// marks today's deadline as overdue. We fix that here.
  int? _daysRemainingActual(Goal goal) {
    if (goal.deadline == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(
      goal.deadline!.year,
      goal.deadline!.month,
      goal.deadline!.day,
    );
    final diff = deadlineDay.difference(today).inDays;
    return diff; // negative = overdue, 0 = today, positive = days left
  }

  void _sortGoals() {
    _goals.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      return 0;
    });
  }

  void clearGoals() {
    _goals = [];
    _notifiedThisSession.clear();
    notifyListeners();
  }
}
