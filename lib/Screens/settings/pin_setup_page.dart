import 'package:flutter/material.dart';
import '../../Core/constants/app_colors.dart';
import '../../Services/pin_service.dart';

/// Used for both setting a new PIN and changing an existing one.
/// [isChanging] = true → first step verifies the old PIN.
class PinSetupPage extends StatefulWidget {
  final bool isChanging;

  const PinSetupPage({Key? key, this.isChanging = false}) : super(key: key);

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage>
    with SingleTickerProviderStateMixin {
  // Steps: verify_old → enter_new → confirm_new
  // If not changing: enter_new → confirm_new
  late String _step;
  String _entered = '';
  String _newPin = '';
  String _error = '';

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _step = widget.isChanging ? 'verify_old' : 'enter_new';
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (_step) {
      case 'verify_old':
        return 'Enter Current PIN';
      case 'enter_new':
        return 'Enter New PIN';
      case 'confirm_new':
        return 'Confirm New PIN';
      default:
        return '';
    }
  }

  String get _subtitle {
    switch (_step) {
      case 'verify_old':
        return 'Enter your existing 4-digit PIN';
      case 'enter_new':
        return 'Choose a 4-digit PIN for your app lock';
      case 'confirm_new':
        return 'Re-enter your PIN to confirm';
      default:
        return '';
    }
  }

  void _onKey(String digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _error = '';
    });
    if (_entered.length == 4) _processStep();
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _processStep() async {
    await Future.delayed(const Duration(milliseconds: 150));

    if (_step == 'verify_old') {
      final correct = await PinService.instance.verifyPin(_entered);
      if (correct) {
        setState(() {
          _step = 'enter_new';
          _entered = '';
          _error = '';
        });
      } else {
        _shakeCtrl.forward(from: 0);
        setState(() {
          _entered = '';
          _error = 'Incorrect PIN. Try again.';
        });
      }
    } else if (_step == 'enter_new') {
      setState(() {
        _newPin = _entered;
        _entered = '';
        _step = 'confirm_new';
      });
    } else if (_step == 'confirm_new') {
      if (_entered == _newPin) {
        await PinService.instance.savePin(_entered);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isChanging
                    ? 'PIN changed successfully!'
                    : 'PIN set successfully! App lock is now enabled.',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context, true); // true = success
        }
      } else {
        _shakeCtrl.forward(from: 0);
        setState(() {
          _entered = '';
          _newPin = '';
          _step = 'enter_new';
          _error = 'PINs did not match. Please try again.';
        });
      }
    }
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
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          widget.isChanging ? 'Change PIN' : 'Set PIN',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Lock icon
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppColors.primary,
                size: 36,
              ),
            ),

            const SizedBox(height: 20),

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
              _error.isNotEmpty ? _error : _subtitle,
              style: TextStyle(
                color: _error.isNotEmpty
                    ? AppColors.error
                    : AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),

            // Step indicator
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isChanging)
                    _stepDot(_step == 'verify_old', _step != 'verify_old'),
                  _stepDot(_step == 'enter_new', _step == 'confirm_new'),
                  _stepDot(_step == 'confirm_new', false),
                ],
              ),
            ),

            const Spacer(),

            // PIN dots
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                final offset =
                    _shakeAnim.value *
                    10 *
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
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : AppColors.surface,
                      border: Border.all(
                        color: filled
                            ? AppColors.primary
                            : AppColors.textSecondary.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: filled
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

            const Spacer(),

            // Keypad
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
                      const SizedBox(width: 72, height: 72),
                      _digitButton('0'),
                      _keyButton(
                        child: Icon(
                          Icons.backspace_outlined,
                          color: _entered.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          size: 24,
                        ),
                        onTap: _onDelete,
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

  Widget _stepDot(bool isActive, bool isDone) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: (isActive || isDone) ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _keyRow(List<String> digits) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: digits.map(_digitButton).toList(),
  );

  Widget _digitButton(String digit) => _keyButton(
    child: Text(
      digit,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w500,
      ),
    ),
    onTap: () => _onKey(digit),
  );

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
