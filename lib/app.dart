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
import 'Services/pin_service.dart';
import 'Screens/profile/profile_selection_page.dart';
import 'Screens/settings/app_lock_screen.dart';

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

/// Launch flow:
///   1. Splash while initializing
///   2. Check if app lock is enabled
///      ├── YES → show AppLockScreen (PIN / biometric)
///      │          └── on unlock → ProfileSelectionPage
///      └── NO  → ProfileSelectionPage directly
///
/// ProfileSelectionPage handles:
///   • No profiles → auto-pushes ProfileSetupPage
///   • Profiles exist → user picks one → MainNavigationPage
class _AppEntry extends StatefulWidget {
  const _AppEntry({Key? key}) : super(key: key);

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _ready = false;
  bool _lockEnabled = false;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Load profiles in parallel with PIN check
    await Future.wait([
      context.read<UserProvider>().initializeUser(),
      _checkLock(),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _checkLock() async {
    _lockEnabled = await PinService.instance.isAppLockEnabled();
    // If no PIN is actually set (e.g. lock was enabled then PIN removed),
    // treat as unlocked to avoid a dead-end screen.
    if (_lockEnabled) {
      final pinSet = await PinService.instance.isPinSet();
      if (!pinSet) _lockEnabled = false;
    }
  }

  void _onUnlocked() {
    setState(() => _unlocked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _SplashScreen();

    // Show lock screen if enabled and not yet unlocked this session
    if (_lockEnabled && !_unlocked) {
      return AppLockScreen(onUnlocked: _onUnlocked);
    }

    // Profile selection (handles no-profiles → setup flow)
    return const ProfileSelectionPage(isLaunchScreen: true);
  }
}

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
