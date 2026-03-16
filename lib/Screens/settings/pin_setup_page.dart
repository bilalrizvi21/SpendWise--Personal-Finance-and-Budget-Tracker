import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../Core/constants/app_colors.dart';
import '../../../Services/pin_service.dart';

/// Used for:
/// 1. First-time PIN setup (isChanging: false)
/// 2. Changing existing PIN (isChanging: true)
class PinSetupPage extends StatefulWidget {
  final bool isChanging;
  final VoidCallback? onSuccess;

  const PinSetupPage({Key? key, this.isChanging = false, this.onSuccess})
    : super(key: key);

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage>
    with SingleTickerProviderStateMixin {
  // Steps: verify_old (if changing) → enter_new → confirm_new
  String _step = 'enter_new';
  String _enteredPin = '';
  String _firstPin = '';
  String _errorMessage = '';
  bool _isLoading = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.isChanging) _step = 'verify_old';

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  String get _title {
    switch (_step) {
      case 'verify_old':
        return 'Enter Current PIN';
      case 'enter_new':
        return widget.isChanging ? 'Enter New PIN' : 'Set a PIN';
      case 'confirm_new':
        return 'Confirm PIN';
      default:
        return '';
    }
  }

  String get _subtitle {
    switch (_step) {
      case 'verify_old':
        return 'Enter your current 4-digit PIN to continue';
      case 'enter_new':
        return 'Choose a 4-digit PIN to protect SpendWise';
      case 'confirm_new':
        return 'Enter the same PIN again to confirm';
      default:
        return '';
    }
  }

  void _onDigitTap(String digit) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += digit;
      _errorMessage = '';
    });
    HapticFeedback.lightImpact();

    if (_enteredPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _processPin);
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(
      () => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1),
    );
  }

  Future<void> _processPin() async {
    setState(() => _isLoading = true);

    switch (_step) {
      case 'verify_old':
        final valid = await PinService.instance.verifyPin(_enteredPin);
        if (valid) {
          setState(() {
            _step = 'enter_new';
            _enteredPin = '';
            _isLoading = false;
          });
        } else {
          _showError('Incorrect PIN. Try again.');
        }
        break;

      case 'enter_new':
        setState(() {
          _firstPin = _enteredPin;
          _step = 'confirm_new';
          _enteredPin = '';
          _isLoading = false;
        });
        break;

      case 'confirm_new':
        if (_enteredPin == _firstPin) {
          await PinService.instance.savePin(_enteredPin);
          setState(() => _isLoading = false);
          HapticFeedback.heavyImpact();

          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          _showError("PINs don't match. Try again.");
          setState(() {
            _step = 'enter_new';
            _firstPin = '';
          });
        }
        break;
    }
  }

  void _showError(String message) {
    HapticFeedback.vibrate();
    _shakeController.forward(from: 0);
    setState(() {
      _errorMessage = message;
      _enteredPin = '';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Lock icon
            Container(
              padding: const EdgeInsets.all(20),
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
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: 36,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              _title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 40),

            // PIN dots with shake animation
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final offset =
                    _shakeAnimation.value *
                    10 *
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
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        width: 2,
                      ),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
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

            // Error message
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: _errorMessage.isNotEmpty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
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
                      const SizedBox(width: 72), // empty space
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
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
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
            style: const TextStyle(
              color: AppColors.textPrimary,
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
}
