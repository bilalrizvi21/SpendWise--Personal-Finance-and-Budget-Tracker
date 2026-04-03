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
import 'Screens/main_navigation.dart';
import 'Screens/settings/app_lock_screen.dart';
import 'Services/pin_service.dart';

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
            themeMode: _resolveThemeMode(userProvider.theme),
            home: const _AppEntry(),
          );
        },
      ),
    );
  }

  ThemeMode _resolveThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry({Key? key}) : super(key: key);

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _checkDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLock();
    }
  }

  Future<void> _checkLock() async {
    final lockEnabled = await PinService.instance.isAppLockEnabled();
    setState(() {
      _isLocked = lockEnabled;
      _checkDone = true;
    });
  }

  void _onUnlocked() => setState(() => _isLocked = false);

  @override
  Widget build(BuildContext context) {
    if (!_checkDone) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF00D9FF),
                size: 56,
              ),
              SizedBox(height: 16),
              Text(
                'SpendWise',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLocked) {
      return AppLockScreen(onUnlocked: _onUnlocked);
    }

    return const MainNavigationPage();
  }
}
