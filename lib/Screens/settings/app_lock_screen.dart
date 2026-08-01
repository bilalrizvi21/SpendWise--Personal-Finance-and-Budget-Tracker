import 'dart:async';
import 'package:flutter/material.dart';
import '../../Core/constants/app_colors.dart';
import '../../Services/pin_service.dart';
import '../../Services/biometric_service.dart';

/// Full-screen PIN entry shown before profile selection.
/// Calls [onUnlocked] when the user successfully authenticates.
class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const AppLockScreen({Key? key, required this.onUnlocked}) : super(key: key);

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  String _entered = '';
  int _attempts = 0;
  bool _locked = false;
  int _lockSeconds = 30;
  Timer? _lockTimer;
  bool _biometricAvailable = false;
  String _error = '';

  // Shake animation
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _checkBiometric();
    // Auto-trigger biometric on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final biometricEnabled = await PinService.instance.isBiometricEnabled();
    final available = await BiometricService.instance.isAvailable();
    if (mounted) {
      setState(() => _biometricAvailable = biometricEnabled && available);
    }
  }

  Future<void> _tryBiometric() async {
    if (!_biometricAvailable || _locked) return;
    final success = await BiometricService.instance.authenticate();
    if (success && mounted) widget.onUnlocked();
  }

  void _onKey(String digit) {
    if (_locked || _entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _error = '';
    });
    if (_entered.length == 4) _verify();
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _verify() async {
    final correct = await PinService.instance.verifyPin(_entered);
    if (correct) {
      widget.onUnlocked();
    } else {
      _attempts++;
      _shakeCtrl.forward(from: 0);
      if (_attempts >= 3) {
        _startLockout();
      } else {
        setState(() {
          _entered = '';
          _error =
              'Incorrect PIN. ${3 - _attempts} attempt${3 - _attempts == 1 ? '' : 's'} remaining.';
        });
      }
    }
  }

  void _startLockout() {
    setState(() {
      _locked = true;
      _entered = '';
      _lockSeconds = 30;
      _error = '';
    });
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _lockSeconds--);
      if (_lockSeconds <= 0) {
        t.cancel();
        setState(() {
          _locked = false;
          _attempts = 0;
          _error = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── Wallet icon ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.neonBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'SpendWise',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _locked
                  ? 'Too many attempts. Wait $_lockSeconds seconds.'
                  : 'Enter your PIN to continue',
              style: TextStyle(
                color: _locked ? AppColors.error : AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // ── PIN dots ──
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                final offset =
                    _shakeAnim.value *
                    12 *
                    ((_shakeAnim.value * 10).round().isEven ? 1 : -1);
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _entered.length;
                  final isError = _error.isNotEmpty && _entered.isEmpty;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isError
                          ? AppColors.error
                          : filled
                          ? AppColors.primary
                          : AppColors.surface,
                      border: Border.all(
                        color: isError
                            ? AppColors.error
                            : filled
                            ? AppColors.primary
                            : AppColors.textSecondary.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: filled && !isError
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),

            // Error message
            if (_error.isNotEmpty && !_locked)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),

            const Spacer(),

            // ── Keypad ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  _keyRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _keyRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _keyRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric button
                      _keyButton(
                        child: _biometricAvailable
                            ? Icon(
                                Icons.fingerprint,
                                color: _locked
                                    ? AppColors.textSecondary
                                    : AppColors.primary,
                                size: 28,
                              )
                            : const SizedBox(width: 64, height: 64),
                        onTap: _biometricAvailable && !_locked
                            ? _tryBiometric
                            : null,
                      ),
                      _digitButton('0'),
                      _keyButton(
                        child: Icon(
                          Icons.backspace_outlined,
                          color: _entered.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          size: 24,
                        ),
                        onTap: _locked ? null : _onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _keyRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_digitButton).toList(),
    );
  }

  Widget _digitButton(String digit) {
    return _keyButton(
      child: Text(
        digit,
        style: TextStyle(
          color: _locked ? AppColors.textSecondary : AppColors.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: _locked ? null : () => _onKey(digit),
    );
  }

  Widget _keyButton({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: Center(child: child),
      ),
    );
  }
}
