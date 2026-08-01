import 'package:flutter/material.dart';
import '../../Core/constants/app_colors.dart';
import '../../Services/pin_service.dart';
import '../../Services/biometric_service.dart';
import 'pin_setup_page.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({Key? key}) : super(key: key);

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _appLockEnabled = false;
  bool _biometricEnabled = false;
  bool _pinSet = false;
  bool _biometricAvailable = false;
  String _biometricLabel = 'Biometric';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pinSet = await PinService.instance.isPinSet();
    final lockEnabled = await PinService.instance.isAppLockEnabled();
    final bioEnabled = await PinService.instance.isBiometricEnabled();
    final bioAvailable = await BiometricService.instance.isAvailable();
    final bioLabel = await BiometricService.instance.getBiometricLabel();

    if (mounted) {
      setState(() {
        _pinSet = pinSet;
        _appLockEnabled = lockEnabled;
        _biometricEnabled = bioEnabled;
        _biometricAvailable = bioAvailable;
        _biometricLabel = bioLabel;
        _loading = false;
      });
    }
  }

  // ── Enable/disable app lock ──
  Future<void> _toggleAppLock(bool value) async {
    if (value) {
      // Need a PIN first
      if (!_pinSet) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const PinSetupPage(isChanging: false),
          ),
        );
        if (result != true) return; // user cancelled
        await _load();
      }
      await PinService.instance.setAppLockEnabled(true);
      setState(() => _appLockEnabled = true);
      _showSnack('App lock enabled', AppColors.success);
    } else {
      // Confirm before disabling
      final confirm = await _confirmDialog(
        title: 'Disable App Lock?',
        body: 'Your app will no longer require a PIN or biometric to open.',
        confirmText: 'Disable',
        isDestructive: true,
      );
      if (!confirm) return;
      await PinService.instance.setAppLockEnabled(false);
      await PinService.instance.setBiometricEnabled(false);
      setState(() {
        _appLockEnabled = false;
        _biometricEnabled = false;
      });
      _showSnack('App lock disabled', AppColors.warning);
    }
  }

  // ── Enable/disable biometric ──
  Future<void> _toggleBiometric(bool value) async {
    if (!_appLockEnabled) {
      _showSnack('Enable app lock first', AppColors.warning);
      return;
    }
    if (value) {
      // Test biometric before enabling
      final success = await BiometricService.instance.authenticate();
      if (!success) {
        _showSnack('Biometric authentication failed', AppColors.error);
        return;
      }
      await PinService.instance.setBiometricEnabled(true);
      setState(() => _biometricEnabled = true);
      _showSnack('$_biometricLabel enabled', AppColors.success);
    } else {
      await PinService.instance.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
      _showSnack('$_biometricLabel disabled', AppColors.warning);
    }
  }

  // ── Change PIN ──
  Future<void> _changePIN() async {
    if (!_pinSet) {
      _showSnack('No PIN set. Enable app lock first.', AppColors.warning);
      return;
    }
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PinSetupPage(isChanging: true)),
    );
    if (result == true) await _load();
  }

  // ── Remove PIN ──
  Future<void> _removePin() async {
    final confirm = await _confirmDialog(
      title: 'Remove PIN?',
      body: 'This will also disable app lock and biometric authentication.',
      confirmText: 'Remove',
      isDestructive: true,
    );
    if (!confirm) return;
    await PinService.instance.removePin();
    await _load();
    _showSnack('PIN removed and app lock disabled', AppColors.warning);
  }

  // ── Test biometric ──
  Future<void> _testBiometric() async {
    final success = await BiometricService.instance.authenticate();
    _showSnack(
      success ? '$_biometricLabel works correctly!' : '$_biometricLabel failed',
      success ? AppColors.success : AppColors.error,
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _confirmDialog({
    required String title,
    required String body,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? AppColors.error
                  : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

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
          'Security',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Status card ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: _appLockEnabled
                        ? const LinearGradient(
                            colors: [Color(0xFF1F3864), Color(0xFF2E75B6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _appLockEnabled ? null : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: _appLockEnabled
                        ? null
                        : Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              (_appLockEnabled
                                      ? Colors.white
                                      : AppColors.primary)
                                  .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _appLockEnabled
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          color: _appLockEnabled
                              ? Colors.white
                              : AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _appLockEnabled
                                  ? 'App Lock is ON'
                                  : 'App Lock is OFF',
                              style: TextStyle(
                                color: _appLockEnabled
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _appLockEnabled
                                  ? 'Your app is protected with a PIN${_biometricEnabled ? ' and $_biometricLabel' : ''}'
                                  : 'Enable PIN lock to protect your financial data',
                              style: TextStyle(
                                color: _appLockEnabled
                                    ? Colors.white.withOpacity(0.8)
                                    : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── App Lock toggle ──
                _sectionHeader('App Lock'),
                _settingsTile(
                  icon: Icons.lock_rounded,
                  title: 'Enable App Lock',
                  subtitle: _pinSet
                      ? 'PIN is set. Toggle to enable or disable.'
                      : 'Tap to set a PIN and enable app lock',
                  trailing: Switch(
                    value: _appLockEnabled,
                    onChanged: _toggleAppLock,
                    activeColor: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 12),

                // ── PIN Management ──
                _sectionHeader('PIN Management'),
                _settingsTile(
                  icon: Icons.pin_rounded,
                  title: _pinSet ? 'Change PIN' : 'Set PIN',
                  subtitle: _pinSet
                      ? 'Update your 4-digit PIN'
                      : 'Set a 4-digit PIN for app lock',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                  onTap: _pinSet ? _changePIN : () => _toggleAppLock(true),
                ),

                if (_pinSet) ...[
                  const SizedBox(height: 8),
                  _settingsTile(
                    icon: Icons.delete_outline,
                    title: 'Remove PIN',
                    subtitle: 'This will disable app lock entirely',
                    iconColor: AppColors.error,
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                    onTap: _removePin,
                  ),
                ],

                const SizedBox(height: 12),

                // ── Biometric ──
                if (_biometricAvailable) ...[
                  _sectionHeader('Biometric Authentication'),
                  _settingsTile(
                    icon: Icons.fingerprint,
                    title: _biometricLabel,
                    subtitle: _appLockEnabled
                        ? 'Use $_biometricLabel instead of PIN'
                        : 'Enable app lock first to use $_biometricLabel',
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: _appLockEnabled ? _toggleBiometric : null,
                      activeColor: AppColors.primary,
                    ),
                  ),
                  if (_biometricEnabled) ...[
                    const SizedBox(height: 8),
                    _settingsTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Test $_biometricLabel',
                      subtitle: 'Verify your biometric works correctly',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      onTap: _testBiometric,
                    ),
                  ],
                  const SizedBox(height: 12),
                ],

                // ── Info card ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'App lock is shown every time you open SpendWise, before the profile selection screen. After 3 incorrect PIN attempts, a 30-second lockout is enforced.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        trailing: trailing,
      ),
    );
  }
}
