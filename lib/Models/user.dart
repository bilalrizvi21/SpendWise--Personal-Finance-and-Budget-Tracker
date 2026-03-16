class User {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String currency;
  final String language;
  final bool notificationsEnabled;
  final bool budgetAlertsEnabled;
  final bool goalRemindersEnabled;
  final bool aiAnomalyWarningsEnabled;
  final bool biometricEnabled;
  final String theme; // 'light', 'dark', 'system'
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.currency = 'PKR',
    this.language = 'en',
    this.notificationsEnabled = true,
    this.budgetAlertsEnabled = true,
    this.goalRemindersEnabled = true,
    this.aiAnomalyWarningsEnabled = true,
    this.biometricEnabled = false,
    this.theme = 'light',
    required this.createdAt,
    this.updatedAt,
  });

  // Get user initials for avatar
  String get initials {
    final names = name.split(' ');
    if (names.isEmpty) return '';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  // Check if user has complete profile
  bool get hasCompleteProfile {
    return name.isNotEmpty && email.isNotEmpty && phoneNumber != null;
  }

  // Copy with method
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? currency,
    String? language,
    bool? notificationsEnabled,
    bool? budgetAlertsEnabled,
    bool? goalRemindersEnabled,
    bool? aiAnomalyWarningsEnabled,
    bool? biometricEnabled,
    String? theme,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      goalRemindersEnabled: goalRemindersEnabled ?? this.goalRemindersEnabled,
      aiAnomalyWarningsEnabled:
          aiAnomalyWarningsEnabled ?? this.aiAnomalyWarningsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      theme: theme ?? this.theme,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'currency': currency,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'budgetAlertsEnabled': budgetAlertsEnabled,
      'goalRemindersEnabled': goalRemindersEnabled,
      'aiAnomalyWarningsEnabled': aiAnomalyWarningsEnabled,
      'biometricEnabled': biometricEnabled,
      'theme': theme,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      currency: json['currency'] as String? ?? 'PKR',
      language: json['language'] as String? ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      budgetAlertsEnabled: json['budgetAlertsEnabled'] as bool? ?? true,
      goalRemindersEnabled: json['goalRemindersEnabled'] as bool? ?? true,
      aiAnomalyWarningsEnabled:
          json['aiAnomalyWarningsEnabled'] as bool? ?? true,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      theme: json['theme'] as String? ?? 'light',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // Create empty user
  factory User.empty() {
    return User(id: '', name: '', email: '', createdAt: DateTime.now());
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// User Preferences (separate from main user model)
class UserPreferences {
  final String userId;
  final String currency;
  final String dateFormat;
  final String timeFormat;
  final String theme;
  final String language;
  final bool notificationsEnabled;
  final bool budgetAlertsEnabled;
  final bool goalRemindersEnabled;
  final bool aiAnomalyWarningsEnabled;
  final bool biometricEnabled;
  final bool autoBackupEnabled;
  final int budgetAlertThreshold; // percentage (e.g., 80 for 80%)
  final DateTime? lastBackupDate;

  UserPreferences({
    required this.userId,
    this.currency = 'PKR',
    this.dateFormat = 'dd/MM/yyyy',
    this.timeFormat = '12h',
    this.theme = 'light',
    this.language = 'en',
    this.notificationsEnabled = true,
    this.budgetAlertsEnabled = true,
    this.goalRemindersEnabled = true,
    this.aiAnomalyWarningsEnabled = true,
    this.biometricEnabled = false,
    this.autoBackupEnabled = false,
    this.budgetAlertThreshold = 80,
    this.lastBackupDate,
  });

  UserPreferences copyWith({
    String? userId,
    String? currency,
    String? dateFormat,
    String? timeFormat,
    String? theme,
    String? language,
    bool? notificationsEnabled,
    bool? budgetAlertsEnabled,
    bool? goalRemindersEnabled,
    bool? aiAnomalyWarningsEnabled,
    bool? biometricEnabled,
    bool? autoBackupEnabled,
    int? budgetAlertThreshold,
    DateTime? lastBackupDate,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      currency: currency ?? this.currency,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      goalRemindersEnabled: goalRemindersEnabled ?? this.goalRemindersEnabled,
      aiAnomalyWarningsEnabled:
          aiAnomalyWarningsEnabled ?? this.aiAnomalyWarningsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currency': currency,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'theme': theme,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'budgetAlertsEnabled': budgetAlertsEnabled,
      'goalRemindersEnabled': goalRemindersEnabled,
      'aiAnomalyWarningsEnabled': aiAnomalyWarningsEnabled,
      'biometricEnabled': biometricEnabled,
      'autoBackupEnabled': autoBackupEnabled,
      'budgetAlertThreshold': budgetAlertThreshold,
      'lastBackupDate': lastBackupDate?.toIso8601String(),
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'] as String,
      currency: json['currency'] as String? ?? 'PKR',
      dateFormat: json['dateFormat'] as String? ?? 'dd/MM/yyyy',
      timeFormat: json['timeFormat'] as String? ?? '12h',
      theme: json['theme'] as String? ?? 'light',
      language: json['language'] as String? ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      budgetAlertsEnabled: json['budgetAlertsEnabled'] as bool? ?? true,
      goalRemindersEnabled: json['goalRemindersEnabled'] as bool? ?? true,
      aiAnomalyWarningsEnabled:
          json['aiAnomalyWarningsEnabled'] as bool? ?? true,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      autoBackupEnabled: json['autoBackupEnabled'] as bool? ?? false,
      budgetAlertThreshold: json['budgetAlertThreshold'] as int? ?? 80,
      lastBackupDate: json['lastBackupDate'] != null
          ? DateTime.parse(json['lastBackupDate'] as String)
          : null,
    );
  }
}

// Supported Currencies
class SupportedCurrencies {
  static const List<Map<String, String>> currencies = [
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': 'PKR'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'AED'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': 'SAR'},
  ];

  static String getSymbol(String code) {
    try {
      return currencies.firstWhere((c) => c['code'] == code)['symbol']!;
    } catch (e) {
      return code;
    }
  }

  static String getName(String code) {
    try {
      return currencies.firstWhere((c) => c['code'] == code)['name']!;
    } catch (e) {
      return code;
    }
  }
}
