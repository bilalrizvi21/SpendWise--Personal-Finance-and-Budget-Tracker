import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transaction_provider.dart';
import 'budget_provider.dart';
import 'goal_provider.dart';
import 'user_provider.dart';
import 'ai_insights_provider.dart';

/// Helper class to initialize all providers with data
class AppProviders {
  /// Load all initial data for providers
  static Future<void> loadAllData(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final aiProvider = Provider.of<AIInsightsProvider>(context, listen: false);

    // Load data in parallel
    await Future.wait([
      userProvider.initializeUser(),
      transactionProvider.loadTransactions(),
      budgetProvider.loadBudgets(),
      goalProvider.loadGoals(),
      aiProvider.generateInsights(),
    ]);
  }

  /// Refresh all provider data
  static Future<void> refreshAllData(BuildContext context) async {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final aiProvider = Provider.of<AIInsightsProvider>(context, listen: false);

    await Future.wait([
      transactionProvider.loadTransactions(),
      budgetProvider.loadBudgets(),
      goalProvider.loadGoals(),
      aiProvider.generateInsights(),
    ]);
  }

  /// Clear all provider data (for logout)
  static void clearAllData(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final aiProvider = Provider.of<AIInsightsProvider>(context, listen: false);

    transactionProvider.clearTransactions();
    budgetProvider.clearBudgets();
    goalProvider.clearGoals();
    aiProvider.clearInsights();
  }
}
