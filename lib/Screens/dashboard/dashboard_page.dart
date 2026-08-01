import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendwise_2/Core/widgets/progress_widget.dart';
import 'package:spendwise_2/Providers/ai_insights_provider.dart';
import 'package:spendwise_2/Providers/budget_provider.dart';
import 'package:spendwise_2/Providers/goal_provider.dart';
import 'package:spendwise_2/Providers/transaction_provider.dart';
import 'package:spendwise_2/Providers/user_provider.dart';
import 'package:spendwise_2/Screens/transactions/add_tranactions_page.dart';
import '../../Core/constants/app_colors.dart';
import '../../Core/constants/app_strings.dart';
import '../../Core/widgets/custom_card.dart';
import '../../Core/widgets/custom_button.dart';
import '../../Core/widgets/loading_indicator.dart';
import '../../Core/utils/currency_formatter.dart';
import '../settings/settings_page.dart';
import '../profile/profile_selection_page.dart';
import 'widgets/financial_overview_card.dart';
import 'widgets/expense_chart.dart';
import 'widgets/spending_trend_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final transactionProvider = context.read<TransactionProvider>();
    final goalProvider = context.read<GoalProvider>();
    final aiProvider = context.read<AIInsightsProvider>();

    await Future.wait([
      transactionProvider.loadTransactions(),
      goalProvider.loadGoals(),
    ]);

    await aiProvider.generateInsights(
      transactions: transactionProvider.transactions,
    );
  }

  // ── Bell icon: show all notifications in bottom sheet ──
  void _showNotificationsSheet(BuildContext context) {
    final budgets = context.read<BudgetProvider>().currentMonthBudgets;
    final alertBudgets = budgets.where((b) => b.percentageUsed >= 80).toList()
      ..sort((a, b) => b.percentageUsed.compareTo(a.percentageUsed));

    final anomalies = context.read<AIInsightsProvider>().anomalies;

    final goals = context.read<GoalProvider>().activeGoals;
    final goalAlerts = goals.where((g) {
      if (g.isAchieved) return true;
      if (g.isOverdue) return true;
      final days = g.daysRemaining;
      return days != null && days <= 7;
    }).toList();

    final totalAlerts =
        alertBudgets.length + anomalies.length + goalAlerts.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (totalAlerts > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$totalAlerts',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── All clear ──
                if (totalAlerts == 0)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.success,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All good! No alerts right now.',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Budget Alerts ──
                if (alertBudgets.isNotEmpty) ...[
                  _sheetSectionHeader('💰 Budget Alerts', AppColors.error),
                  const SizedBox(height: 8),
                  ...alertBudgets.map((budget) {
                    final isExceeded = budget.percentageUsed >= 100;
                    final color = isExceeded
                        ? AppColors.error
                        : AppColors.warning;
                    return _sheetCard(
                      color: color,
                      icon: isExceeded
                          ? Icons.warning_rounded
                          : Icons.trending_up,
                      title: isExceeded
                          ? '🚨 ${budget.category} budget exceeded!'
                          : '⚠️ ${budget.category} at ${budget.percentageUsed.toInt()}%',
                      subtitle:
                          'PKR ${budget.used.toStringAsFixed(0)} used of PKR ${budget.limit.toStringAsFixed(0)}',
                      badge: '${budget.percentageUsed.toInt()}%',
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // ── Anomaly Warnings ──
                if (anomalies.isNotEmpty) ...[
                  _sheetSectionHeader(
                    '🧠 AI Spending Alerts',
                    AppColors.warning,
                  ),
                  const SizedBox(height: 8),
                  ...anomalies.map((anomaly) {
                    final isMajor = anomaly.severity == 'major';
                    final color = isMajor ? AppColors.error : AppColors.warning;
                    return _sheetCard(
                      color: color,
                      icon: Icons.auto_graph,
                      title:
                          '${anomaly.category} spending ${anomaly.deviation.toInt()}% above usual',
                      subtitle:
                          'PKR ${anomaly.actualAmount.toStringAsFixed(0)} vs avg PKR ${anomaly.expectedAmount.toStringAsFixed(0)}',
                      badge: anomaly.severity.toUpperCase(),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // ── Goal Reminders ──
                if (goalAlerts.isNotEmpty) ...[
                  _sheetSectionHeader('🎯 Goal Reminders', AppColors.primary),
                  const SizedBox(height: 8),
                  ...goalAlerts.map((goal) {
                    String title;
                    String subtitle;
                    Color color;
                    IconData icon;

                    if (goal.isAchieved) {
                      title = '🎉 ${goal.name} — Goal reached!';
                      subtitle = 'Mark it as complete to celebrate your win.';
                      color = AppColors.success;
                      icon = Icons.emoji_events_outlined;
                    } else if (goal.isOverdue) {
                      title = '⏰ ${goal.name} — Deadline passed';
                      subtitle =
                          '${goal.percentageCompleted.toInt()}% complete. Consider extending the deadline.';
                      color = AppColors.error;
                      icon = Icons.timer_off_outlined;
                    } else {
                      final days = goal.daysRemaining ?? 0;
                      title = days == 0
                          ? '📅 ${goal.name} — Due today!'
                          : '📅 ${goal.name} — $days day${days == 1 ? '' : 's'} left';
                      subtitle =
                          '${goal.percentageCompleted.toInt()}% of PKR ${goal.targetAmount.toStringAsFixed(0)} saved';
                      color = AppColors.primary;
                      icon = Icons.flag_outlined;
                    }

                    return _sheetCard(
                      color: color,
                      icon: icon,
                      title: title,
                      subtitle: subtitle,
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _sheetCard({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          AppStrings.appName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Bell → all notifications bottom sheet
          Consumer3<BudgetProvider, AIInsightsProvider, GoalProvider>(
            builder: (context, budgetProvider, aiProvider, goalProvider, _) {
              final budgetAlerts = budgetProvider.currentMonthBudgets
                  .where((b) => b.percentageUsed >= 80)
                  .length;
              final anomalyAlerts = aiProvider.anomalies.length;
              final goalAlerts = goalProvider.activeGoals.where((g) {
                if (g.isAchieved || g.isOverdue) return true;
                final days = g.daysRemaining;
                return days != null && days <= 7;
              }).length;
              final alertCount = budgetAlerts + anomalyAlerts + goalAlerts;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => _showNotificationsSheet(context),
                  ),
                  if (alertCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$alertCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Settings gear
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),

          // Profile avatar → profile selection
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ProfileSelectionPage(isLaunchScreen: false),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      userProvider.userInitials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer3<TransactionProvider, GoalProvider, AIInsightsProvider>(
        builder: (context, transactionProvider, goalProvider, aiProvider, _) {
          if (transactionProvider.isLoading) {
            return const Center(child: LoadingIndicator(size: 48));
          }

          final summary = transactionProvider.getTransactionSummary();
          final activeGoals = goalProvider.activeGoals.take(2).toList();
          final anomalies = aiProvider.anomalies;

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),

                  // Financial Overview Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FinancialOverviewCard(
                      totalIncome: summary.totalIncome,
                      totalExpenses: summary.totalExpense,
                      balance: summary.balance,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: QuickActionButton(
                            text: AppStrings.addIncome,
                            icon: Icons.add,
                            color: AppColors.income,
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AddTransactionPage(type: 'income'),
                                ),
                              );
                              if (result == true) _loadData();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionButton(
                            text: AppStrings.addExpense,
                            icon: Icons.remove,
                            color: AppColors.expense,
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AddTransactionPage(type: 'expense'),
                                ),
                              );
                              if (result == true) _loadData();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Anomaly Alerts
                  if (anomalies.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.auto_graph,
                                  color: AppColors.warning,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Spending Alerts',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${anomalies.length}',
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...anomalies.map(_buildAnomalyCard).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Expense Chart
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.expenseDistribution,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const ExpenseChart(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Spending Trend Chart
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.monthlySpendingTrend,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const SpendingTrendChart(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Savings Goals
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          AppStrings.savingsGoals,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        CustomTextButton(text: 'View All', onPressed: () {}),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (activeGoals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: EmptyState(
                        icon: Icons.flag_outlined,
                        title: 'No Active Goals',
                        description: 'Set a savings goal to get started',
                      ),
                    )
                  else
                    ...activeGoals.map(
                      (goal) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GoalProgressCard(
                          goalName: goal.name,
                          current: goal.currentAmount,
                          target: goal.targetAmount,
                          deadline: goal.deadline?.toString().split(' ')[0],
                          color: AppColors.textSecondary,
                          smartTip: goal.requiredMonthlySavings != null
                              ? 'Save ${CurrencyFormatter.formatCompact(goal.requiredMonthlySavings!)} per month to reach your goal on time'
                              : 'Keep saving consistently to reach your goal',
                        ),
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnomalyCard(anomaly) {
    final isMajor = anomaly.severity == 'major';
    final color = isMajor ? AppColors.error : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isMajor ? Icons.warning_rounded : Icons.trending_up,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anomaly.description,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expected: PKR ${anomaly.expectedAmount.toStringAsFixed(0)}'
                  ' • Actual: PKR ${anomaly.actualAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              anomaly.severity.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Button ──
class QuickActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const QuickActionButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.15),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.9), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
