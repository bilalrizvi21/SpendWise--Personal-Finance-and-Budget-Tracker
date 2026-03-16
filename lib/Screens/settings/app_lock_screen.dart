import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../Core/constants/app_colors.dart';
import '../../../Services/pin_service.dart';
import '../../../Services/biometric_service.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const AppLockScreen({Key? key, required this.onUnlocked}) : super(key: key);

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _errorMessage = '';
  int _failedAttempts = 0;
  bool _isLocked = false;
  bool _biometricAvailable = false;
  String _biometricLabel = 'Fingerprint';
  String _biometricIconType = 'fingerprint';

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _checkBiometric();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final biometricEnabled = await PinService.instance.isBiometricEnabled();
    final available = await BiometricService.instance.isAvailable();

    if (biometricEnabled && available) {
      final label = await BiometricService.instance.getBiometricLabel();
      final iconType = await BiometricService.instance.getBiometricIconType();
      setState(() {
        _biometricAvailable = true;
        _biometricLabel = label;
        _biometricIconType = iconType;
      });
      // Auto-trigger biometric on open
      _authenticateWithBiometric();
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final success = await BiometricService.instance.authenticate();
    if (success && mounted) {
      HapticFeedback.heavyImpact();
      widget.onUnlocked();
    }
  }

  void _onDigitTap(String digit) {
    if (_isLocked || _enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += digit;
      _errorMessage = '';
    });
    HapticFeedback.lightImpact();

    if (_enteredPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _verifyPin);
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty || _isLocked) return;
    HapticFeedback.lightImpact();
    setState(
      () => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1),
    );
  }

  Future<void> _verifyPin() async {
    final valid = await PinService.instance.verifyPin(_enteredPin);

    if (valid) {
      HapticFeedback.heavyImpact();
      widget.onUnlocked();
    } else {
      _failedAttempts++;
      HapticFeedback.vibrate();
      _shakeController.forward(from: 0);

      if (_failedAttempts >= 3) {
        setState(() {
          _isLocked = true;
          _enteredPin = '';
          _errorMessage = 'Too many attempts. Wait 30 seconds.';
        });
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted) {
            setState(() {
              _isLocked = false;
              _failedAttempts = 0;
              _errorMessage = '';
            });
          }
        });
      } else {
        setState(() {
          _errorMessage =
              'Incorrect PIN. ${3 - _failedAttempts} attempts left.';
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // App logo + lock
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SpendWise',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your PIN to continue',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final offset =
                    _shakeAnimation.value *
                    12 *
                    ((_shakeAnimation.value * 10).toInt().isEven ? 1 : -1);
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? (_isLocked ? AppColors.error : AppColors.primary)
                          : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? (_isLocked ? AppColors.error : AppColors.primary)
                            : AppColors.textSecondary,
                        width: 2,
                      ),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color:
                                    (_isLocked
                                            ? AppColors.error
                                            : AppColors.primary)
                                        .withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // Error / locked message
            AnimatedOpacity(
              opacity: _errorMessage.isNotEmpty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Number pad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric button or empty
                      _biometricAvailable
                          ? _buildBiometricButton()
                          : const SizedBox(width: 72),
                      _buildDigitButton('0'),
                      _buildBackspaceButton(),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildDigitButton).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    return GestureDetector(
      onTap: () => _onDigitTap(digit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _isLocked
              ? AppColors.cardBackground.withOpacity(0.5)
              : AppColors.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              color: _isLocked ? AppColors.textLight : AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return GestureDetector(
      onTap: _onBackspace,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _authenticateWithBiometric,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Center(
          child: Icon(
            _biometricIconType == 'face'
                ? Icons.face_outlined
                : Icons.fingerprint,
            color: AppColors.primary,
            size: 32,
          ),
        ),
      ),
    );
  }
}
