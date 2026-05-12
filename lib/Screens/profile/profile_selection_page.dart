import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/constants/app_colors.dart';
import '../../Providers/user_provider.dart';
import '../../Providers/transaction_provider.dart';
import '../../Providers/budget_provider.dart';
import '../../Providers/goal_provider.dart';
import '../../Providers/ai_insights_provider.dart';
import '../../Providers/recurring_transaction_provider.dart';
import '../../Services/database_service.dart';
import '../main_navigation.dart';
import 'profile_setup_page.dart';

/// Shown on every app launch AND when the avatar is tapped inside the app.
///
/// [isLaunchScreen] = true  → no back button (this IS the entry point)
/// [isLaunchScreen] = false → back button shown (opened from inside the app)
class ProfileSelectionPage extends StatefulWidget {
  final bool isLaunchScreen;

  const ProfileSelectionPage({Key? key, this.isLaunchScreen = false})
    : super(key: key);

  @override
  State<ProfileSelectionPage> createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Always refresh the list when this page appears
      await context.read<UserProvider>().refreshProfiles();

      if (!mounted) return;
      final userProvider = context.read<UserProvider>();

      // No profiles at all → go straight to setup
      if (!userProvider.hasProfiles) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ProfileSetupPage(isFirstProfile: true),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final profiles = userProvider.profiles;
            final activeId = userProvider.activeProfile?.id;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button — only when opened from inside the app
                      if (!widget.isLaunchScreen)
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.textPrimary,
                              size: 16,
                            ),
                          ),
                        ),

                      SizedBox(height: widget.isLaunchScreen ? 0 : 24),

                      // App branding
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppColors.neonBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'SpendWise',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Text(
                        profiles.isEmpty ? 'Get Started' : 'Select Profile',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profiles.isEmpty
                            ? 'Create your first profile to start tracking your finances.'
                            : 'Choose a profile or create a new one.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Profile list ──
                Expanded(
                  child: profiles.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: profiles.length,
                          itemBuilder: (context, index) {
                            final profile = profiles[index];
                            final isActive = profile.id == activeId;
                            return _ProfileCard(
                              profile: profile,
                              isActive: isActive,
                              canDelete: profiles.length > 1,
                              // Both active and inactive cards are tappable.
                              // Active card enters the app immediately.
                              // Inactive card switches profile then enters.
                              onTap: () => _selectProfile(context, profile),
                              onDelete: () => _confirmDelete(
                                context,
                                userProvider,
                                profile,
                              ),
                            );
                          },
                        ),
                ),

                // ── Add New Profile button ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openSetup(context),
                      icon: const Icon(
                        Icons.person_add_outlined,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'Add New Profile',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Select any profile (active or not) and enter the app ──
  Future<void> _selectProfile(
    BuildContext context,
    ProfileRecord profile,
  ) async {
    final userProvider = context.read<UserProvider>();

    // Switch to selected profile (no-op if already active, but still
    // sets the DB filter and persists the choice)
    await userProvider.switchToProfile(profile);
    if (!context.mounted) return;

    // Reload all data providers for this profile
    await Future.wait([
      context.read<TransactionProvider>().loadTransactions(),
      context.read<BudgetProvider>().loadBudgets(),
      context.read<GoalProvider>().loadGoals(),
      context.read<RecurringTransactionProvider>().loadRecurring(),
    ]);

    if (!context.mounted) return;

    // Re-run AI insights with fresh transactions
    await context.read<AIInsightsProvider>().generateInsights(
      transactions: context.read<TransactionProvider>().transactions,
    );

    if (!context.mounted) return;

    // Clear the entire navigation stack and go to the main app
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationPage()),
      (_) => false,
    );
  }

  // ── Open setup to create a new profile ──
  void _openSetup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileSetupPage(isFirstProfile: false),
      ),
    );
  }

  // ── Delete confirmation ──
  void _confirmDelete(
    BuildContext context,
    UserProvider userProvider,
    ProfileRecord profile,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Profile?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will permanently delete "${profile.name}" and ALL their '
          'transactions, budgets, and goals. This cannot be undone.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await userProvider.deleteProfile(profile.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile card widget
// ─────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final ProfileRecord profile;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = profile.avatarColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withOpacity(0.5)
              : Colors.white.withOpacity(0.06),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap, // Always tappable — active card enters app directly
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Avatar circle
                CircleAvatar(
                  radius: 26,
                  backgroundColor: color.withOpacity(0.18),
                  child: Text(
                    profile.initials,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Name + contact
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.email.isNotEmpty
                            ? profile.email
                            : profile.phone,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Active badge OR delete button
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (canDelete)
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
