import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Core/constants/app_colors.dart';
import '../../Providers/user_provider.dart';
import '../profile/profile_selection_page.dart';

/// Three-step profile creation: Name → Phone → Email
///
/// [isFirstProfile] = true  → very first launch, no back navigation
/// [isFirstProfile] = false → adding an additional profile
class ProfileSetupPage extends StatefulWidget {
  final bool isFirstProfile;

  const ProfileSetupPage({Key? key, this.isFirstProfile = false})
    : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _pageController = PageController();
  int _step = 0;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _nameKey = GlobalKey<FormState>();
  final _phoneKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey<FormState>();

  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _next() {
    final valid = switch (_step) {
      0 => _nameKey.currentState?.validate() ?? false,
      1 => _phoneKey.currentState?.validate() ?? false,
      _ => _emailKey.currentState?.validate() ?? false,
    };
    if (!valid) return;

    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createProfile();
    }
  }

  void _back() {
    if (_step == 0) {
      if (!widget.isFirstProfile) Navigator.pop(context);
      return;
    }
    setState(() => _step--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _createProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final userProvider = context.read<UserProvider>();

      final newProfile = await userProvider.createProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

      // Activate the new profile
      await userProvider.switchToProfile(newProfile);

      if (!mounted) return;

      // Go back to profile selection so user sees the new profile in the list
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const ProfileSelectionPage(isLaunchScreen: true),
        ),
        (_) => false,
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating profile: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Static header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (!widget.isFirstProfile || _step > 0)
                        GestureDetector(
                          onTap: _back,
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
                        )
                      else
                        const SizedBox(width: 42),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.neonBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    widget.isFirstProfile && _step == 0
                        ? 'Welcome to SpendWise'
                        : 'New Profile',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    widget.isFirstProfile
                        ? 'Set up your profile to get started'
                        : 'Fill in the details for the new profile',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Step dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final active = i == _step;
                      final done = i < _step;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: (active || done)
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Scrollable step content — prevents keyboard overflow ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _scrollable(_buildNameStep()),
                  _scrollable(_buildPhoneStep()),
                  _scrollable(_buildEmailStep()),
                ],
              ),
            ),

            // ── Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          _step < 2 ? 'Continue' : 'Create Profile',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scrollable(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: child,
    );
  }

  // ── Step 1: Name ──
  Widget _buildNameStep() {
    return Form(
      key: _nameKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel('👤  What\'s your name?'),
          const SizedBox(height: 6),
          _stepHint('This will appear on your profile throughout the app.'),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameCtrl,
            autofocus: false,
            textCapitalization: TextCapitalization.words,
            style: _inputStyle,
            decoration: _inputDeco('Full Name', Icons.person_outline),
            onFieldSubmitted: (_) => _next(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your name';
              }
              if (v.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ── Step 2: Phone ──
  Widget _buildPhoneStep() {
    return Form(
      key: _phoneKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel('📱  Phone number?'),
          const SizedBox(height: 6),
          _stepHint(
            'Used for profile identification. Any number works for demo.',
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            // ✅ Fixed regex — no special chars inside character class
            // Just allow digits, +, spaces and hyphens
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
            ],
            style: _inputStyle,
            decoration: _inputDeco('+92 300 1234567', Icons.phone_outlined),
            onFieldSubmitted: (_) => _next(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter a phone number';
              }
              // Count only digits for length check
              final digits = v.trim().replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.length < 7) {
                return 'Enter a valid phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ── Step 3: Email ──
  Widget _buildEmailStep() {
    return Form(
      key: _emailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel('✉️  Email address?'),
          const SizedBox(height: 6),
          _stepHint(
            'For a demo profile, anything like demo@test.com works fine.',
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: _inputStyle,
            decoration: _inputDeco('email@example.com', Icons.email_outlined),
            onFieldSubmitted: (_) => _next(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter an email';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Preview card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    _nameCtrl.text.trim().isNotEmpty
                        ? _nameCtrl.text.trim()[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameCtrl.text.trim().isEmpty
                            ? 'Your Name'
                            : _nameCtrl.text.trim(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _phoneCtrl.text.trim().isEmpty
                            ? 'Phone number'
                            : _phoneCtrl.text.trim(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ──
const TextStyle _inputStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 17,
  fontWeight: FontWeight.w500,
);

Widget _stepLabel(String text) => Text(
  text,
  style: const TextStyle(
    color: AppColors.textPrimary,
    fontSize: 19,
    fontWeight: FontWeight.bold,
  ),
);

Widget _stepHint(String text) => Text(
  text,
  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
);

InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.textLight),
  prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
  filled: true,
  fillColor: AppColors.cardBackground,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.primary, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.error),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.error, width: 2),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
);
