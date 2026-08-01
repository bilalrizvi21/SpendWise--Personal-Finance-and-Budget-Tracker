import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles all local push notifications for SpendWise.
/// Three notification types:
///   1. Recurring transaction processed
///   2. Budget threshold alert (80% / exceeded)
///   3. Goal reminder (deadline approaching / overdue / achieved)
///   4. AI anomaly warning (unusual spending detected)
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
    print('✅ NotificationService initialized');
  }

  // ── 1. Recurring transaction ──
  Future<void> showRecurringTransactionNotification({
    required String name,
    required double amount,
    required String type,
    required String category,
  }) async {
    await initialize();
    final isExpense = type.toLowerCase() == 'expense';
    await _show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      channelId: 'recurring_transactions',
      channelName: 'Recurring Transactions',
      channelDesc: 'Automatic recurring transaction notifications',
      title: isExpense
          ? '💸 Recurring Expense Processed'
          : '💰 Recurring Income Added',
      body:
          '$name: ${isExpense ? '-' : '+'}PKR ${amount.toStringAsFixed(0)} under $category',
    );
  }

  // ── 2. Budget alert ──
  Future<void> showBudgetAlertNotification({
    required String category,
    required double usedAmount,
    required double limitAmount,
    required double percentage,
  }) async {
    await initialize();
    final isExceeded = percentage >= 100;
    final pct = percentage.toInt();
    await _show(
      id: category.hashCode,
      channelId: 'budget_alerts',
      channelName: 'Budget Alerts',
      channelDesc: 'Notifications when budgets approach or exceed limits',
      title: isExceeded
          ? '🚨 Budget Exceeded — $category'
          : '⚠️ Budget Alert — $category',
      body: isExceeded
          ? 'You\'ve exceeded your $category budget! '
                'Spent PKR ${usedAmount.toStringAsFixed(0)} of PKR ${limitAmount.toStringAsFixed(0)}'
          : '$pct% of your $category budget used. '
                'PKR ${usedAmount.toStringAsFixed(0)} / PKR ${limitAmount.toStringAsFixed(0)}',
    );
  }

  // ── 3. Goal reminder ──
  // Called when a goal's deadline is near, overdue, or achieved
  Future<void> showGoalReminderNotification({
    required String goalName,
    required String type, // 'deadline_near' | 'overdue' | 'achieved'
    int? daysRemaining,
    double? percentage,
  }) async {
    await initialize();

    String title;
    String body;

    switch (type) {
      case 'achieved':
        title = '🎉 Goal Achieved — $goalName!';
        body =
            'You\'ve reached 100% of your "$goalName" goal. Mark it as complete!';
        break;
      case 'overdue':
        title = '⏰ Goal Deadline Passed — $goalName';
        body =
            'Your "$goalName" goal deadline has passed at ${percentage?.toInt() ?? 0}% completion.';
        break;
      case 'deadline_near':
      default:
        title = '📅 Goal Reminder — $goalName';
        body = daysRemaining != null && daysRemaining <= 0
            ? 'Your "$goalName" goal deadline is today!'
            : 'Only $daysRemaining day${daysRemaining == 1 ? '' : 's'} left to reach "$goalName".';
    }

    await _show(
      // Use a stable ID per goal so repeated checks don't stack notifications
      id: goalName.hashCode + type.hashCode,
      channelId: 'goal_reminders',
      channelName: 'Goal Reminders',
      channelDesc: 'Reminders for savings goal deadlines and achievements',
      title: title,
      body: body,
    );
  }

  // ── 4. AI anomaly warning ──
  // Called once per detected anomaly per session
  Future<void> showAnomalyNotification({
    required String category,
    required double deviation,
    required String severity,
    required double actualAmount,
    required double expectedAmount,
  }) async {
    await initialize();

    final pct = deviation.toInt();
    final severityEmoji = severity == 'major'
        ? '🚨'
        : severity == 'moderate'
        ? '⚠️'
        : '📊';

    await _show(
      id: 'anomaly_$category'.hashCode,
      channelId: 'anomaly_warnings',
      channelName: 'AI Spending Alerts',
      channelDesc: 'AI-detected unusual spending pattern warnings',
      title: '$severityEmoji Unusual $category Spending',
      body:
          'Your $category spending is $pct% above usual. '
          'PKR ${actualAmount.toStringAsFixed(0)} vs avg PKR ${expectedAmount.toStringAsFixed(0)}.',
    );
  }

  // ── Internal helper ──
  Future<void> _show({
    required int id,
    required String channelId,
    required String channelName,
    required String channelDesc,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    print('🔔 Notification: $title');
  }
}
