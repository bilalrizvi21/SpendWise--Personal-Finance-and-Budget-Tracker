import 'package:shared_preferences/shared_preferences.dart';

/// Handles all PIN-related storage and verification
/// PIN is stored as a simple string in shared_preferences
/// For production you'd use flutter_secure_storage, but for FYP this is fine
class PinService {
  static const _pinKey = 'spendwise_pin';
  static const _pinEnabledKey = 'spendwise_pin_enabled';
  static const _biometricEnabledKey = 'spendwise_biometric_enabled';

  static final PinService instance = PinService._();
  PinService._();

  // ── Check if PIN is set ──
  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_pinKey);
    return pin != null && pin.isNotEmpty;
  }

  // ── Check if app lock is enabled ──
  Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledKey) ?? false;
  }

  // ── Check if biometric is enabled ──
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // ── Save PIN ──
  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setBool(_pinEnabledKey, true);
  }

  // ── Verify PIN ──
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey);
    return savedPin == pin;
  }

  // ── Remove PIN and disable app lock ──
  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_pinEnabledKey, false);
    await prefs.setBool(_biometricEnabledKey, false);
  }

  // ── Enable / disable app lock ──
  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, enabled);
  }

  // ── Enable / disable biometric ──
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }
}
