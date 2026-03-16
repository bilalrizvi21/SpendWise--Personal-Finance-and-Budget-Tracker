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
  bool _biometricAvailable = false;
  bool _pinSet = false;
  String _biometricLabel = 'Fingerprint';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final pinSet = await PinService.instance.isPinSet();
    final appLock = await PinService.instance.isAppLockEnabled();
    final biometric = await PinService.instance.isBiometricEnabled();
    final biometricAvailable = await BiometricService.instance.isAvailable();
    final biometricLabel = await BiometricService.instance.getBiometricLabel();

    setState(() {
      _pinSet = pinSet;
      _appLockEnabled = appLock;
      _biometricEnabled = biometric;
      _biometricAvailable = biometricAvailable;
      _biometricLabel = biometricLabel;
      _isLoading = false;
    });
  }

  Future<void> _toggleAppLock(bool enabled) async {
    if (enabled && !_pinSet) {
      // Need to set PIN first
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PinSetupPage()),
      );
      if (result == true) {
        await _loadStatus();
        _showSnackbar('App lock enabled!');
      }
    } else if (!enabled) {
      // Show confirmation before disabling
      final confirm = await _showConfirmDialog(
        'Disable App Lock?',
        'Your PIN will be removed and the app will no longer require authentication.',
      );
      if (confirm == true) {
        await PinService.instance.removePin();
        await _loadStatus();
        _showSnackbar('App lock disabled');
      }
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (!_appLockEnabled) {
      _showSnackbar('Enable App Lock first', isError: true);
      return;
    }
    await PinService.instance.setBiometricEnabled(enabled);
    setState(() => _biometricEnabled = enabled);
    _showSnackbar(
      enabled ? '$_biometricLabel enabled!' : '$_biometricLabel disabled',
    );
  }

  Future<void> _changePin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PinSetupPage(isChanging: true)),
    );
    await _loadStatus();
    _showSnackbar('PIN changed successfully!');
  }

  Future<void> _testBiometric() async {
    final success = await BiometricService.instance.authenticate();
    _showSnackbar(
      success ? 'Biometric works!' : 'Biometric failed',
      isError: !success,
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          content,
          style: const TextStyle(color: AppColors.textSecondary),
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
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Security',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Status Card ──
                _buildStatusCard(),

                const SizedBox(height: 16),

                // ── App Lock Toggle ──
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'App Lock',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Require PIN every time you open SpendWise',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildIconBox(Icons.lock_outline),
                              const SizedBox(width: 12),
                              Text(
                                _appLockEnabled ? 'Enabled' : 'Disabled',
                                style: TextStyle(
                                  color: _appLockEnabled
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _appLockEnabled,
                            onChanged: _toggleAppLock,
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Biometric Toggle ──
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _biometricLabel,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_biometricAvailable) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Not available',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _biometricAvailable
                            ? 'Use $_biometricLabel instead of PIN'
                            : 'Your device does not support biometric authentication',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildIconBox(Icons.fingerprint),
                              const SizedBox(width: 12),
                              Text(
                                _biometricEnabled ? 'Enabled' : 'Disabled',
                                style: TextStyle(
                                  color: _biometricEnabled
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _biometricEnabled,
                            onChanged: _biometricAvailable
                                ? _toggleBiometric
                                : null,
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                      // Test biometric button
                      if (_biometricAvailable && _biometricEnabled) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _testBiometric,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.fingerprint,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Test $_biometricLabel',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Change PIN ──
                if (_pinSet)
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Change PIN',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Update your 4-digit security PIN',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _changePin,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Change PIN'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary.withOpacity(
                                0.15,
                              ),
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // ── Privacy note ──
                _buildCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: AppColors.success,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your data is safe',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'PIN and all financial data is stored locally on your device only.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _appLockEnabled
            ? const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [AppColors.cardBackground, AppColors.surface],
              ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            _appLockEnabled ? Icons.lock : Icons.lock_open_outlined,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _appLockEnabled ? 'App is Protected' : 'App is Unlocked',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _appLockEnabled
                      ? _biometricEnabled
                            ? 'PIN + $_biometricLabel enabled'
                            : 'PIN protection active'
                      : 'Enable app lock for security',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}
