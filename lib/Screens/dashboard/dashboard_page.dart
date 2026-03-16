import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendwise_2/Core/widgets/progress_widget.dart';
import 'package:spendwise_2/Providers/ai_insights_provider.dart';
import 'package:spendwise_2/Providers/goal_provider.dart';
import 'package:spendwise_2/Providers/transaction_provider.dart';
import 'package:spendwise_2/Providers/user_provider.dart';
import 'package:spendwise_2/Screens/transactions/add_tranactions_page.dart';
import '../../Core/constants/app_colors.dart';
import '../../Core/constants/app_strings.dart';
import '../../Core/widgets/custom_card.dart';
import '../../Core/widgets/custom_button.dart';
import '../main_navigation.dart';
import '../../Core/widgets/loading_indicator.dart';
import '../../Core/utils/currency_formatter.dart';

import '../settings/settings_page.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final transactionProvider = context.read<TransactionProvider>();
    final goalProvider = context.read<GoalProvider>();
    final aiProvider = context.read<AIInsightsProvider>();

    await Future.wait([
      transactionProvider.loadTransactions(),
      goalProvider.loadGoals(),
      aiProvider.generateInsights(),
    ]);
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
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
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
        builder: (context, transactionProvider, goalProvider, aiProvider, child) {
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
                  // Top spacing for app bar
                  const SizedBox(height: 100),

                  // Modern Financial Overview Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FinancialOverviewCard(
                      totalIncome: summary.totalIncome,
                      totalExpenses: summary.totalExpense,
                      balance: summary.balance,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions (Premium Style)
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
                                  builder: (context) =>
                                      const AddTransactionPage(type: 'income'),
                                ),
                              );
                              if (result == true) {
                                _loadData();
                              }
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
                                  builder: (context) =>
                                      const AddTransactionPage(type: 'expense'),
                                ),
                              );
                              if (result == true) {
                                _loadData();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Anomaly Alert (if any)
                  if (anomalies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InfoCard(
                        title: 'Unusual Spending Detected',
                        description: anomalies.first.description,
                        icon: Icons.warning_amber,
                        color: AppColors.warning,
                        onTap: () {
                          // Navigate to detailed view
                        },
                      ),
                    ),

                  if (anomalies.isNotEmpty) const SizedBox(height: 24),

                  // Expense Distribution Chart
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
                        CustomTextButton(
                          text: 'View All',
                          onPressed: () {
                            final navState = context
                                .findAncestorStateOfType<
                                  MainNavigationPageState
                                >();
                            navState?.onNavItemTapped(4);
                          },
                        ),
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
                    ...activeGoals.map((goal) {
                      return Padding(
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
                      );
                    }).toList(),

                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --------------------------
// Premium QuickActionButton
// --------------------------
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
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
