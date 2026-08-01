import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/constants/app_strings.dart';
import '../../Core/constants/app_colors.dart';
import '../../Providers/user_provider.dart';
import 'profile_page.dart';
import 'security_page.dart';
import 'reports_page.dart';
import 'categories_management_page.dart';
import 'help_page.dart';
import 'about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          AppStrings.settings,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // ── Profile header card ──
              _ProfileHeaderCard(userProvider: userProvider),

              // ── Profile ──
              _sectionHeader('Profile'),
              _tile(
                context,
                icon: Icons.person_outline,
                title: AppStrings.userDetails,
                subtitle: userProvider.userName,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
              ),

              // ── Appearance ──
              _sectionHeader('Appearance'),
              _tile(
                context,
                icon: Icons.palette_outlined,
                title: AppStrings.theme,
                subtitle: _themeLabel(userProvider.theme),
                onTap: () => _showThemePicker(context, userProvider),
              ),
              _tile(
                context,
                icon: Icons.currency_exchange,
                title: AppStrings.currency,
                subtitle: userProvider.currency,
                onTap: () => _showCurrencyPicker(context, userProvider),
              ),

              // ── Notifications ──
              _sectionHeader(AppStrings.notifications),
              _switchTile(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: AppStrings.budgetAlerts,
                subtitle: 'Alert when spending reaches 80% of budget',
                value: userProvider.preferences?.budgetAlertsEnabled ?? true,
                onChanged: (val) =>
                    userProvider.toggleNotification('budget', val),
              ),
              _switchTile(
                context,
                icon: Icons.flag_outlined,
                title: AppStrings.goalReminders,
                subtitle: 'Remind when goal deadlines are near',
                value: userProvider.preferences?.goalRemindersEnabled ?? true,
                onChanged: (val) =>
                    userProvider.toggleNotification('goal', val),
              ),
              _switchTile(
                context,
                icon: Icons.analytics_outlined,
                title: AppStrings.aiAnomalyWarnings,
                subtitle: 'Alert when unusual spending is detected',
                value:
                    userProvider.preferences?.aiAnomalyWarningsEnabled ?? true,
                onChanged: (val) =>
                    userProvider.toggleNotification('anomaly', val),
              ),

              // ── Security ──
              _sectionHeader(AppStrings.dataAndSecurity),
              _tile(
                context,
                icon: Icons.lock_outline,
                title: 'App Lock & Biometric',
                subtitle: 'PIN and fingerprint settings',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecurityPage()),
                ),
              ),

              // ── Categories ──
              _sectionHeader('Categories'),
              _tile(
                context,
                icon: Icons.category_outlined,
                title: AppStrings.categoriesManagement,
                subtitle: 'Add and manage custom categories',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoriesManagementPage(),
                  ),
                ),
              ),

              // ── Reports ──
              _sectionHeader('Reports'),
              _tile(
                context,
                icon: Icons.assessment_outlined,
                title: AppStrings.reportsAndHistory,
                subtitle: 'Monthly income and expense breakdown',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsPage()),
                ),
              ),

              // ── Help & About ──
              _sectionHeader('Help & About'),
              _tile(
                context,
                icon: Icons.help_outline,
                title: AppStrings.helpAndSupport,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpPage()),
                ),
              ),
              _tile(
                context,
                icon: Icons.info_outline,
                title: AppStrings.aboutApp,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                ),
              ),

              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'SpendWise v1.0.0 • SSUET FYP 2022F',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Theme picker ──
  void _showThemePicker(BuildContext context, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              const Text(
                'Choose Theme',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...['light', 'dark', 'system'].map((t) {
                final isSelected = userProvider.theme == t;
                final label = t == 'light'
                    ? '☀️  Light'
                    : t == 'dark'
                    ? '🌙  Dark'
                    : '📱  System Default';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    label,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () async {
                    await userProvider.changeTheme(t);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── Currency picker ──
  void _showCurrencyPicker(BuildContext context, UserProvider userProvider) {
    final currencies = [
      {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': '₨'},
      {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
      {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
      {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
      {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'د.إ'},
      {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': '﷼'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              const Text(
                'Choose Currency',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: currencies.map((c) {
                    final isSelected = userProvider.currency == c['code'];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            c['symbol']!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        c['code']!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        c['name']!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () async {
                        await userProvider.changeCurrency(c['code']!);
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _themeLabel(String theme) {
    switch (theme) {
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System Default';
      default:
        return 'Light';
    }
  }

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.textLight,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _switchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Profile header card at top of settings ──
class _ProfileHeaderCard extends StatelessWidget {
  final UserProvider userProvider;
  const _ProfileHeaderCard({required this.userProvider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F3864), Color(0xFF2E75B6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                userProvider.userInitials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userProvider.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userProvider.userEmail.isNotEmpty
                        ? userProvider.userEmail
                        : 'Tap to edit profile',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}
