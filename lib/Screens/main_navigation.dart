import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Core/constants/app_colors.dart';
import '../Core/constants/app_strings.dart';
import '../Providers/transaction_provider.dart';
import '../Providers/budget_provider.dart';
import '../Providers/goal_provider.dart';
import '../Providers/ai_insights_provider.dart';
import '../Providers/user_provider.dart';
import '../Providers/recurring_transaction_provider.dart';
import '../Services/notification_service.dart';
import 'dashboard/dashboard_page.dart';
import 'transactions/transactions_page.dart';
import 'budget/budget_planner_page.dart';
import 'ai_insights/ai_insights_page.dart';
import 'goals/goals_page.dart';
import 'chatbot/chatbot_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => MainNavigationPageState();
}

class MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  Future<void> _initializeData() async {
    print('🚀 MainNavigation: starting initialization');

    // Step 1: Initialize notifications
    await NotificationService.instance.initialize();
    print('✅ Notifications initialized');

    // Step 2: Load user preferences FIRST — must finish before reading toggles
    final userProvider = context.read<UserProvider>();
    await userProvider.initializeUser();
    print('✅ User initialized: ${userProvider.userName}');

    // Step 3: Read toggles from loaded preferences
    final prefs = userProvider.preferences;
    final budgetAlertsEnabled = prefs?.budgetAlertsEnabled ?? true;
    final goalRemindersEnabled = prefs?.goalRemindersEnabled ?? true;
    final anomalyWarningsEnabled = prefs?.aiAnomalyWarningsEnabled ?? true;
    print(
      '🔔 Toggles — budget:$budgetAlertsEnabled goal:$goalRemindersEnabled anomaly:$anomalyWarningsEnabled',
    );

    // Step 4: Load all data in parallel
    final txProvider = context.read<TransactionProvider>();
    await Future.wait([
      txProvider.loadTransactions(),
      context.read<BudgetProvider>().loadBudgets(),
      context.read<GoalProvider>().loadGoals(),
      context.read<RecurringTransactionProvider>().loadRecurring(),
    ]);
    print(
      '✅ All data loaded — ${txProvider.transactions.length} transactions, '
      '${context.read<GoalProvider>().activeGoals.length} active goals',
    );

    // Step 5: Run AI insights with real transactions
    await context.read<AIInsightsProvider>().generateInsights(
      transactions: txProvider.transactions,
    );
    print(
      '✅ AI insights generated — ${context.read<AIInsightsProvider>().anomalies.length} anomalies',
    );

    if (!mounted) return;

    // Step 6: Fire notifications
    print('🔔 Firing budget notifications (enabled=$budgetAlertsEnabled)');
    await context.read<BudgetProvider>().checkAndNotify(
      enabled: budgetAlertsEnabled,
    );

    print('🔔 Firing goal notifications (enabled=$goalRemindersEnabled)');
    await context.read<GoalProvider>().checkAndNotify(
      enabled: goalRemindersEnabled,
    );

    print('🔔 Firing anomaly notifications (enabled=$anomalyWarningsEnabled)');
    await context.read<AIInsightsProvider>().notifyAnomalies(
      enabled: anomalyWarningsEnabled,
    );

    // Step 7: Process recurring transactions
    if (mounted) {
      await context.read<RecurringTransactionProvider>().processDueTransactions(
        context,
      );
    }

    print('✅ MainNavigation initialization complete');
  }

  final List<Widget> _pages = const [
    DashboardPage(),
    TransactionsPage(),
    BudgetPlannerPage(),
    AIInsightsPage(),
    GoalsPage(),
  ];

  final List<NavigationItem> _navItems = const [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: AppStrings.navHome,
    ),
    NavigationItem(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: AppStrings.navTransactions,
    ),
    NavigationItem(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: AppStrings.navBudget,
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: AppStrings.navInsights,
    ),
    NavigationItem(
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
      label: AppStrings.navGoals,
    ),
  ];

  void onNavItemTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: onNavItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: _navItems.map((item) {
            final isSelected = _navItems.indexOf(item) == _currentIndex;
            return BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 26,
                ),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotPage()),
              ),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            )
          : null,
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
