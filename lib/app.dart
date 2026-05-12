import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendwise_2/Providers/ai_insights_provider.dart';
import 'package:spendwise_2/Providers/budget_provider.dart';
import 'package:spendwise_2/Providers/goal_provider.dart';
import 'package:spendwise_2/Providers/transaction_provider.dart';
import 'package:spendwise_2/Providers/user_provider.dart';
import 'package:spendwise_2/Providers/recurring_transaction_provider.dart';
import 'Core/constants/app_theme.dart';
import 'Core/constants/app_strings.dart';
import 'Screens/profile/profile_selection_page.dart';

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => AIInsightsProvider()),
        ChangeNotifierProvider(create: (_) => RecurringTransactionProvider()),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: userProvider.theme == 'dark'
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const _AppEntry(),
          );
        },
      ),
    );
  }
}

/// On every cold launch:
///   1. Show splash while [initializeUser] runs (loads profiles from DB)
///   2. Always route to [ProfileSelectionPage]
///      • No profiles  → ProfileSelectionPage auto-pushes ProfileSetupPage
///      • Has profiles → user sees the list, picks one, then enters the app
///
/// This guarantees the profile screen is ALWAYS shown on launch,
/// which is the desired behaviour for demo/evaluation purposes.
class _AppEntry extends StatefulWidget {
  const _AppEntry({Key? key}) : super(key: key);

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Loads all profiles from DB and restores the last active profile ID.
    // Does NOT navigate — navigation is handled in build().
    await context.read<UserProvider>().initializeUser();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _SplashScreen();

    // Always land on the profile selection screen.
    // ProfileSelectionPage handles routing to setup or dashboard internally.
    return const ProfileSelectionPage(isLaunchScreen: true);
  }
}

// ── Simple splash shown during the ~100-200ms init ──
class _SplashScreen extends StatelessWidget {
  const _SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFF00D9FF),
              size: 56,
            ),
            SizedBox(height: 16),
            Text(
              'SpendWise',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'AI-Powered Finance Manager',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
