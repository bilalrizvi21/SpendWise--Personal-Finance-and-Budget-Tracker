import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  UserPreferences? _preferences;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  static const _userKey = 'spendwise_user';
  static const _prefsKey = 'spendwise_preferences';

  // Getters
  User? get user => _user;
  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  String get userName => _user?.name ?? 'User';
  String get userEmail => _user?.email ?? '';
  String get userInitials => _user?.initials ?? 'U';
  String get currency => _preferences?.currency ?? 'PKR';
  String get theme => _preferences?.theme ?? 'dark';

  // ========== INITIALIZE ==========

  Future<void> initializeUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();

      // Try loading saved user
      final userJson = prefs.getString(_userKey);
      final prefsJson = prefs.getString(_prefsKey);

      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
      } else {
        // First launch — create default user
        _user = User(
          id: '1',
          name: 'Your Name',
          email: 'your@email.com',
          phoneNumber: '',
          currency: 'PKR',
          createdAt: DateTime.now(),
        );
        await _saveUser();
      }

      if (prefsJson != null) {
        _preferences = UserPreferences.fromJson(jsonDecode(prefsJson));
      } else {
        _preferences = UserPreferences(
          userId: _user!.id,
          currency: 'PKR',
          theme: 'dark',
          budgetAlertThreshold: 80,
        );
        await _savePreferences();
      }

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== PERSIST HELPERS ==========

  Future<void> _saveUser() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_preferences!.toJson()));
  }

  // ========== UPDATE PROFILE ==========

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    if (_user == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = _user!.copyWith(
        name: name ?? _user!.name,
        email: email ?? _user!.email,
        phoneNumber: phoneNumber ?? _user!.phoneNumber,
        profileImageUrl: profileImageUrl ?? _user!.profileImageUrl,
        updatedAt: DateTime.now(),
      );

      await _saveUser();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========== UPDATE PREFERENCES ==========

  Future<void> updatePreferences({
    String? currency,
    String? theme,
    String? language,
    bool? notificationsEnabled,
    bool? budgetAlertsEnabled,
    bool? goalRemindersEnabled,
    bool? aiAnomalyWarningsEnabled,
    bool? biometricEnabled,
    int? budgetAlertThreshold,
  }) async {
    if (_preferences == null) return;

    try {
      _preferences = _preferences!.copyWith(
        currency: currency,
        theme: theme,
        language: language,
        notificationsEnabled: notificationsEnabled,
        budgetAlertsEnabled: budgetAlertsEnabled,
        goalRemindersEnabled: goalRemindersEnabled,
        aiAnomalyWarningsEnabled: aiAnomalyWarningsEnabled,
        biometricEnabled: biometricEnabled,
        budgetAlertThreshold: budgetAlertThreshold,
      );

      await _savePreferences();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> changeCurrency(String currency) async {
    await updatePreferences(currency: currency);
  }

  Future<void> changeTheme(String theme) async {
    await updatePreferences(theme: theme);
  }

  Future<void> toggleNotification(String type, bool value) async {
    switch (type) {
      case 'budget':
        await updatePreferences(budgetAlertsEnabled: value);
        break;
      case 'goal':
        await updatePreferences(goalRemindersEnabled: value);
        break;
      case 'anomaly':
        await updatePreferences(aiAnomalyWarningsEnabled: value);
        break;
      case 'all':
        await updatePreferences(notificationsEnabled: value);
        break;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    // Local app — just simulate success
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_prefsKey);
    _user = null;
    _preferences = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await logout();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Keep these for backwards compatibility
  Future<void> login(String email, String password) async {
    _user = User(
      id: '1',
      name: 'User',
      email: email,
      createdAt: DateTime.now(),
    );
    _preferences = UserPreferences(userId: _user!.id);
    _isAuthenticated = true;
    await _saveUser();
    await _savePreferences();
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    _user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
    _preferences = UserPreferences(userId: _user!.id);
    _isAuthenticated = true;
    await _saveUser();
    await _savePreferences();
    notifyListeners();
  }
}
