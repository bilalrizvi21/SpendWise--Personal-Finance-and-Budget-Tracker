import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles local push notifications for SpendWise
/// Used for recurring transaction processing alerts
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

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
    print('✅ NotificationService initialized');
  }

  /// Show a notification when a recurring transaction is processed
  Future<void> showRecurringTransactionNotification({
    required String name,
    required double amount,
    required String type,
    required String category,
  }) async {
    await initialize();

    final isExpense = type.toLowerCase() == 'expense';
    final sign = isExpense ? '-' : '+';
    final title = isExpense
        ? '💸 Recurring Expense Processed'
        : '💰 Recurring Income Added';
    final body =
        '$name: $sign PKR ${amount.toStringAsFixed(0)} added to $category';

    const androidDetails = AndroidNotificationDetails(
      'recurring_transactions',
      'Recurring Transactions',
      channelDescription: 'Notifications for automatic recurring transactions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );

    print('🔔 Notification shown: $title — $body');
  }

  /// Show a budget alert notification
  Future<void> showBudgetAlertNotification({
    required String category,
    required double percentage,
  }) async {
    await initialize();

    final isExceeded = percentage >= 100;
    final title = isExceeded ? '🚨 Budget Exceeded!' : '⚠️ Budget Alert';
    final body = isExceeded
        ? 'You have exceeded your $category budget!'
        : 'You have used ${percentage.toInt()}% of your $category budget.';

    const androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription:
          'Notifications when budgets are near limit or exceeded',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
      title,
      body,
      details,
    );
  }
}
