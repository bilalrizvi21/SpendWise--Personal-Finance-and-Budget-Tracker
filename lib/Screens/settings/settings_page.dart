import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendwise_2/Models/user.dart';
import '../../Core/constants/app_strings.dart';
import '../../Core/constants/app_colors.dart';
import '../../Providers/user_provider.dart';
import 'profile_page.dart';
import 'security_page.dart';
import 'categories_management_page.dart';
import 'reports_page.dart';
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
        title: const Text(
          AppStrings.settings,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final prefs = userProvider.preferences;

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // ── Profile Header (no edit button) ──
              _buildProfileHeader(context, userProvider),

              // ── Profile Section ──
              _buildSectionHeader('Profile'),
              _buildTile(
                context,
                icon: Icons.person_outline,
                title: AppStrings.userDetails,
                subtitle: userProvider.userName,
                onTap: () => _navigate(context, const ProfilePage()),
              ),
              _buildTile(
                context,
                icon: Icons.currency_exchange,
                title: AppStrings.currency,
                subtitle: prefs?.currency ?? 'PKR',
                onTap: () => _showCurrencyPicker(context, userProvider),
              ),

              // ── Appearance ──
              _buildSectionHeader(AppStrings.appearance),
              _buildTile(
                context,
                icon: Icons.palette_outlined,
                title: AppStrings.theme,
                subtitle: _themeLabel(prefs?.theme ?? 'dark'),
                onTap: () => _showThemePicker(context, userProvider),
              ),

              // ── Notifications ──
              _buildSectionHeader(AppStrings.notifications),
              _buildSwitchTile(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: AppStrings.budgetAlerts,
                subtitle: 'Alert when budget is near limit',
                value: prefs?.budgetAlertsEnabled ?? true,
                onChanged: (val) =>
                    userProvider.toggleNotification('budget', val),
              ),
              _buildSwitchTile(
                context,
                icon: Icons.flag_outlined,
                title: AppStrings.goalReminders,
                subtitle: 'Remind about upcoming goal deadlines',
                value: prefs?.goalRemindersEnabled ?? true,
                onChanged: (val) =>
                    userProvider.toggleNotification('goal', val),
              ),
              _buildSwitchTile(
                context,
                icon: Icons.analytics_outlined,
                title: AppStrings.aiAnomalyWarnings,
                subtitle: 'Warn about unusual spending patterns',
                value: prefs?.aiAnomalyWarningsEnabled ?? true,
                onChanged: (val) =>
                    userProvider.toggleNotification('anomaly', val),
              ),

              // ── Security ──
              _buildSectionHeader(AppStrings.dataAndSecurity),
              _buildTile(
                context,
                icon: Icons.lock_outline,
                title: 'Security & PIN',
                subtitle: 'Manage PIN and biometric access',
                onTap: () => _navigate(context, const SecurityPage()),
              ),

              // ── Categories ──
              _buildSectionHeader('Categories'),
              _buildTile(
                context,
                icon: Icons.category_outlined,
                title: AppStrings.categoriesManagement,
                subtitle: 'Manage your spending categories',
                onTap: () =>
                    _navigate(context, const CategoriesManagementPage()),
              ),

              // ── Reports ──
              _buildSectionHeader('Reports'),
              _buildTile(
                context,
                icon: Icons.assessment_outlined,
                title: AppStrings.reportsAndHistory,
                subtitle: 'View monthly spending reports',
                onTap: () => _navigate(context, const ReportsPage()),
              ),

              // ── Help & About ──
              _buildSectionHeader('Help & About'),
              _buildTile(
                context,
                icon: Icons.help_outline,
                title: AppStrings.helpAndSupport,
                subtitle: 'FAQs and support',
                onTap: () => _navigate(context, const HelpPage()),
              ),
              _buildTile(
                context,
                icon: Icons.info_outline,
                title: AppStrings.aboutApp,
                subtitle: 'Version 1.0.0',
                onTap: () => _navigate(context, const AboutPage()),
              ),

              const SizedBox(height: 32),
              Center(
                child: Text(
                  'SpendWise v1.0.0',
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.5),
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

  // ── Profile Header — no edit button, tapping navigates to profile ──
  Widget _buildProfileHeader(BuildContext context, UserProvider provider) {
    return GestureDetector(
      onTap: () => _navigate(context, const ProfilePage()),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                provider.userInitials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.userEmail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron instead of edit button
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          fontWeight: FontWeight.w500,
          fontSize: 15,
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
        color: AppColors.textLight,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          fontWeight: FontWeight.w500,
          fontSize: 15,
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  String _themeLabel(String theme) {
    switch (theme) {
      case 'dark':
        return 'Dark Mode';
      case 'light':
        return 'Light Mode';
      default:
        return 'System Default';
    }
  }

  void _showThemePicker(BuildContext context, UserProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose Theme',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...[
            ('light', 'Light Mode', Icons.light_mode),
            ('dark', 'Dark Mode', Icons.dark_mode),
            ('system', 'System Default', Icons.settings_brightness),
          ].map((item) {
            final isSelected = provider.preferences?.theme == item.$1;
            return ListTile(
              leading: Icon(
                item.$3,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(
                item.$2,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                provider.changeTheme(item.$1);
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Fixed: use ListView inside a constrained height container to prevent overflow
  void _showCurrencyPicker(BuildContext context, UserProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Currency',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // ← Scrollable list — no more overflow
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: SupportedCurrencies.currencies.map((currency) {
                    final isSelected =
                        provider.preferences?.currency == currency['code'];
                    return ListTile(
                      leading: Text(
                        currency['symbol']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      title: Text(
                        currency['name']!,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        currency['code']!,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        provider.changeCurrency(currency['code']!);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
