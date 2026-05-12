import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/user.dart';
import '../Services/database_service.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  UserPreferences? _preferences;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  List<ProfileRecord> _profiles = [];
  ProfileRecord? _activeProfile;

  // ── Existing getters — IDENTICAL to original so no other file breaks ──
  User? get user => _user;
  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String get userName => _user?.name ?? 'User';
  String get userEmail => _user?.email ?? '';
  String get userInitials => _user?.initials ?? 'U';
  String get currency => _preferences?.currency ?? 'PKR';
  String get theme => _preferences?.theme ?? 'light';

  // ── New profile getters ──
  List<ProfileRecord> get profiles => List.unmodifiable(_profiles);
  ProfileRecord? get activeProfile => _activeProfile;
  bool get hasProfiles => _profiles.isNotEmpty;

  static const _activeIdKey = 'spendwise_active_profile_id';

  // ════════════════════════════════════════
  // INITIALIZE — called on every app launch
  // ════════════════════════════════════════

  Future<void> initializeUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load all profiles from the DB
      _profiles = await DatabaseService.instance.getAllProfiles();
      print('👤 Found ${_profiles.length} profiles in DB');

      if (_profiles.isEmpty) {
        // No profiles → app.dart will route to ProfileSelectionPage
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Restore the last-used profile ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_activeIdKey);

      ProfileRecord? found;
      if (savedId != null) {
        try {
          found = _profiles.firstWhere((p) => p.id == savedId);
        } catch (_) {}
      }

      // Use saved profile, or fall back to first profile
      final profile = found ?? _profiles.first;
      await _activateProfile(profile, persist: false);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('❌ initializeUser: $e');
      notifyListeners();
    }
  }

  // ════════════════════════════════════════
  // CREATE PROFILE — called from ProfileSetupPage
  // ════════════════════════════════════════

  Future<ProfileRecord> createProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final colorIndex = _profiles.length % profileAvatarColors.length;
    final newProfile = ProfileRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      avatarColorIndex: colorIndex,
      createdAt: DateTime.now(),
    );
    await DatabaseService.instance.createProfile(newProfile);
    _profiles.add(newProfile);
    notifyListeners();
    print('✅ Profile created: ${newProfile.name}');
    return newProfile;
  }

  // ════════════════════════════════════════
  // SWITCH PROFILE
  // After calling this the caller must reload all data providers.
  // ════════════════════════════════════════

  Future<void> switchToProfile(ProfileRecord profile) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _activateProfile(profile, persist: true);
      _isLoading = false;
      notifyListeners();
      print('✅ Switched to: ${profile.name}');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ════════════════════════════════════════
  // UPDATE PROFILE
  // Same signature as the original updateProfile call in profile_page.dart
  // ════════════════════════════════════════

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl, // kept for compatibility
  }) async {
    if (_activeProfile == null) return;
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updated = _activeProfile!.copyWith(
        name: name,
        email: email,
        phone: phoneNumber,
      );
      await DatabaseService.instance.updateProfile(updated);

      _activeProfile = updated;
      final idx = _profiles.indexWhere((p) => p.id == updated.id);
      if (idx != -1) _profiles[idx] = updated;
      _user = _buildUser(updated);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ════════════════════════════════════════
  // DELETE PROFILE
  // ════════════════════════════════════════

  Future<void> deleteProfile(String profileId) async {
    if (_profiles.length <= 1) return; // Cannot delete last profile
    await DatabaseService.instance.deleteProfile(profileId);
    _profiles.removeWhere((p) => p.id == profileId);
    if (_activeProfile?.id == profileId) {
      await _activateProfile(_profiles.first, persist: true);
    }
    notifyListeners();
  }

  // ════════════════════════════════════════
  // PREFERENCES
  // Same signature as original so settings_page.dart works unchanged
  // ════════════════════════════════════════

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
    await _savePrefs(_preferences!);
    notifyListeners();
  }

  Future<void> changeCurrency(String c) => updatePreferences(currency: c);
  Future<void> changeTheme(String t) => updatePreferences(theme: t);

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

  // No-op stubs kept so any existing references compile
  Future<void> changePassword(String oldPw, String newPw) async {}
  Future<void> login(String email, String password) async {}
  Future<void> register(String name, String email, String password) async {}
  Future<void> logout() async {
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
  // ════════════════════════════════════════
  // REFRESH PROFILES
  // Used by ProfileSelectionPage
  // ════════════════════════════════════════

  Future<void> refreshProfiles() async {
    try {
      _profiles = await DatabaseService.instance.getAllProfiles();

      // If active profile still exists, keep it
      if (_activeProfile != null) {
        try {
          _activeProfile = _profiles.firstWhere(
            (p) => p.id == _activeProfile!.id,
          );
        } catch (_) {
          // If deleted, fallback to first
          _activeProfile = _profiles.isNotEmpty ? _profiles.first : null;
        }
      }

      notifyListeners();

      print('🔄 Profiles refreshed (${_profiles.length})');
    } catch (e) {
      print('❌ refreshProfiles error: $e');
    }
  }

  // ════════════════════════════════════════
  // PRIVATE HELPERS
  // ════════════════════════════════════════

  Future<void> _activateProfile(
    ProfileRecord profile, {
    required bool persist,
  }) async {
    _activeProfile = profile;
    DatabaseService.instance.setActiveProfile(profile.id);
    _user = _buildUser(profile);
    _preferences = await _loadPrefs(profile.id);
    _isAuthenticated = true;

    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeIdKey, profile.id);
    }
  }

  User _buildUser(ProfileRecord p) => User(
    id: p.id,
    name: p.name,
    email: p.email,
    phoneNumber: p.phone.isEmpty ? null : p.phone,
    createdAt: p.createdAt,
  );

  Future<UserPreferences> _loadPrefs(String profileId) async {
    final sp = await SharedPreferences.getInstance();
    final k = 'prefs_$profileId';
    return UserPreferences(
      userId: profileId,
      currency: sp.getString('${k}_currency') ?? 'PKR',
      theme: sp.getString('${k}_theme') ?? 'light',
      budgetAlertThreshold: sp.getInt('${k}_threshold') ?? 80,
      notificationsEnabled: sp.getBool('${k}_notif') ?? true,
      budgetAlertsEnabled: sp.getBool('${k}_budget_alert') ?? true,
      goalRemindersEnabled: sp.getBool('${k}_goal_reminder') ?? true,
      aiAnomalyWarningsEnabled: sp.getBool('${k}_anomaly') ?? true,
    );
  }

  Future<void> _savePrefs(UserPreferences p) async {
    final sp = await SharedPreferences.getInstance();
    final k = 'prefs_${p.userId}';
    await sp.setString('${k}_currency', p.currency);
    await sp.setString('${k}_theme', p.theme);
    await sp.setInt('${k}_threshold', p.budgetAlertThreshold);
    await sp.setBool('${k}_notif', p.notificationsEnabled);
    await sp.setBool('${k}_budget_alert', p.budgetAlertsEnabled);
    await sp.setBool('${k}_goal_reminder', p.goalRemindersEnabled);
    await sp.setBool('${k}_anomaly', p.aiAnomalyWarningsEnabled);
  }
}
