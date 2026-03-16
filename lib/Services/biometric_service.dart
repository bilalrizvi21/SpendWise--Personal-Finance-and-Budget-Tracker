import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Wraps local_auth to handle biometric authentication
class BiometricService {
  static final BiometricService instance = BiometricService._();
  BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  // ── Check if device supports biometrics ──
  Future<bool> isAvailable() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } on PlatformException {
      return false;
    }
  }

  // ── Get list of enrolled biometrics ──
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  // ── Check if fingerprint is enrolled ──
  Future<bool> hasFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong);
  }

  // ── Authenticate with biometrics ──
  Future<bool> authenticate() async {
    try {
      final available = await isAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: 'Authenticate to access SpendWise',
      );
    } on PlatformException catch (e) {
      print('Biometric error: ${e.message}');
      return false;
    }
  }

  // ── Get biometric type label for UI ──
  Future<String> getBiometricLabel() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) return 'Face ID';
    if (biometrics.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (biometrics.contains(BiometricType.iris)) return 'Iris';
    return 'Biometric';
  }

  // ── Get biometric icon for UI ──
  Future<String> getBiometricIconType() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) return 'face';
    return 'fingerprint';
  }
}
