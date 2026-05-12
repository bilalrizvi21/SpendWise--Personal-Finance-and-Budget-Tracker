import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../Models/transaction.dart' as model;
import '../Models/budget.dart';
import '../Models/goal.dart';
import '../Models/category.dart';
import '../Models/recurring_transaction.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// ProfileRecord model — lives here, imported everywhere via database_service.dart
// ─────────────────────────────────────────────
class ProfileRecord {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int avatarColorIndex;
  final DateTime createdAt;

  const ProfileRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarColorIndex,
    required this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color get avatarColor =>
      profileAvatarColors[avatarColorIndex % profileAvatarColors.length];

  ProfileRecord copyWith({
    String? name,
    String? email,
    String? phone,
    int? avatarColorIndex,
  }) => ProfileRecord(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
    createdAt: createdAt,
  );

  // Column name 'ac' is short and has zero chance of collision with SQLite keywords
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'ac': avatarColorIndex,
    'created_at': createdAt.toIso8601String(),
  };

  static ProfileRecord fromMap(Map<String, dynamic> m) => ProfileRecord(
    id: m['id'] as String,
    name: m['name'] as String,
    email: (m['email'] as String?) ?? '',
    phone: (m['phone'] as String?) ?? '',
    avatarColorIndex: (m['ac'] as int?) ?? 0,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

const List<Color> profileAvatarColors = [
  Color(0xFF00D9FF),
  Color(0xFF10B981),
  Color(0xFFB794F6),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFFEC4899),
  Color(0xFF3B82F6),
];

// ─────────────────────────────────────────────
// DatabaseService singleton
// ─────────────────────────────────────────────
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  // Filters every data query to the active profile
  String _activeProfileId = 'default';

  DatabaseService._init();

  void setActiveProfile(String profileId) {
    _activeProfileId = profileId;
    print('📁 DB profile → $_activeProfileId');
  }

  String get activeProfileId => _activeProfileId;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('spendwise.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    print('📁 DB path: $path');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) => print('✅ DB opened'),
    );
  }

  // ── Called ONLY on a brand-new install (no existing DB file) ──
  Future<void> _createDB(Database db, int version) async {
    await db.execute(_profilesTableSQL);
    await db.execute(_transactionsTableSQL);
    await db.execute(_budgetsTableSQL);
    await db.execute(_goalsTableSQL);
    await db.execute(_categoriesTableSQL);
    await db.execute(_recurringTableSQL);
    print('✅ All tables created (v7 fresh install)');
  }

  // ── Called when an existing DB is opened at a lower version ──
  // RULE: NEVER drop any table here — only CREATE IF NOT EXISTS and ALTER.
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print('⬆️ Upgrading DB from v$oldVersion to v$newVersion');

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id TEXT PRIMARY KEY, category TEXT NOT NULL,
          limit_amount REAL NOT NULL, start_date TEXT NOT NULL,
          end_date TEXT NOT NULL, is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL, updated_at TEXT
        )''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goals (
          id TEXT PRIMARY KEY, name TEXT NOT NULL,
          target_amount REAL NOT NULL, current_amount REAL NOT NULL DEFAULT 0,
          deadline TEXT, description TEXT,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL, updated_at TEXT, completed_at TEXT
        )''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_categories (
          id TEXT PRIMARY KEY, name TEXT NOT NULL,
          icon_code_point INTEGER NOT NULL, color_value INTEGER NOT NULL,
          type TEXT NOT NULL, created_at TEXT NOT NULL
        )''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_transactions (
          id TEXT PRIMARY KEY, name TEXT NOT NULL,
          amount REAL NOT NULL, category TEXT NOT NULL,
          type TEXT NOT NULL, paymentMethod TEXT NOT NULL,
          dayOfMonth INTEGER NOT NULL, nextDueDate TEXT NOT NULL,
          createdAt TEXT NOT NULL, updatedAt TEXT,
          isActive INTEGER NOT NULL DEFAULT 1, notes TEXT
        )''');
    }
    if (oldVersion < 6) {
      // Add profile_id column to all data tables
      for (final t in _dataTables) {
        try {
          await db.execute(
            "ALTER TABLE $t ADD COLUMN profile_id TEXT NOT NULL DEFAULT 'default'",
          );
        } catch (_) {
          // Column already exists — safe to ignore
        }
      }
    }
    if (oldVersion < 7) {
      // Create the profiles table if it doesn't exist yet,
      // OR if it exists from a broken v6 attempt, check its columns
      // and add 'ac' if missing. NEVER drop it.
      await db.execute(_profilesTableSQL);

      // If a broken profiles table existed without 'ac', add it
      try {
        await db.execute(
          'ALTER TABLE profiles ADD COLUMN ac INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {
        // 'ac' already exists — fine
      }
      // Also ensure email and phone columns exist
      try {
        await db.execute(
          "ALTER TABLE profiles ADD COLUMN email TEXT NOT NULL DEFAULT ''",
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE profiles ADD COLUMN phone TEXT NOT NULL DEFAULT ''",
        );
      } catch (_) {}
    }

    print('✅ DB upgrade complete');
  }

  // ── Table SQL constants ──
  static const _profilesTableSQL = '''
    CREATE TABLE IF NOT EXISTS profiles (
      id         TEXT    PRIMARY KEY,
      name       TEXT    NOT NULL,
      email      TEXT    NOT NULL DEFAULT '',
      phone      TEXT    NOT NULL DEFAULT '',
      ac         INTEGER NOT NULL DEFAULT 0,
      created_at TEXT    NOT NULL
    )
  ''';

  static const _transactionsTableSQL = '''
    CREATE TABLE IF NOT EXISTS transactions (
      id            TEXT PRIMARY KEY,
      profile_id    TEXT NOT NULL DEFAULT 'default',
      amount        REAL NOT NULL,
      category      TEXT NOT NULL,
      date          TEXT NOT NULL,
      type          TEXT NOT NULL,
      paymentMethod TEXT NOT NULL,
      notes         TEXT,
      createdAt     TEXT NOT NULL,
      updatedAt     TEXT
    )
  ''';

  static const _budgetsTableSQL = '''
    CREATE TABLE IF NOT EXISTS budgets (
      id           TEXT    PRIMARY KEY,
      profile_id   TEXT    NOT NULL DEFAULT 'default',
      category     TEXT    NOT NULL,
      limit_amount REAL    NOT NULL,
      start_date   TEXT    NOT NULL,
      end_date     TEXT    NOT NULL,
      is_active    INTEGER NOT NULL DEFAULT 1,
      created_at   TEXT    NOT NULL,
      updated_at   TEXT
    )
  ''';

  static const _goalsTableSQL = '''
    CREATE TABLE IF NOT EXISTS goals (
      id             TEXT    PRIMARY KEY,
      profile_id     TEXT    NOT NULL DEFAULT 'default',
      name           TEXT    NOT NULL,
      target_amount  REAL    NOT NULL,
      current_amount REAL    NOT NULL DEFAULT 0,
      deadline       TEXT,
      description    TEXT,
      is_completed   INTEGER NOT NULL DEFAULT 0,
      created_at     TEXT    NOT NULL,
      updated_at     TEXT,
      completed_at   TEXT
    )
  ''';

  static const _categoriesTableSQL = '''
    CREATE TABLE IF NOT EXISTS custom_categories (
      id              TEXT    PRIMARY KEY,
      profile_id      TEXT    NOT NULL DEFAULT 'default',
      name            TEXT    NOT NULL,
      icon_code_point INTEGER NOT NULL,
      color_value     INTEGER NOT NULL,
      type            TEXT    NOT NULL,
      created_at      TEXT    NOT NULL
    )
  ''';

  static const _recurringTableSQL = '''
    CREATE TABLE IF NOT EXISTS recurring_transactions (
      id            TEXT    PRIMARY KEY,
      profile_id    TEXT    NOT NULL DEFAULT 'default',
      name          TEXT    NOT NULL,
      amount        REAL    NOT NULL,
      category      TEXT    NOT NULL,
      type          TEXT    NOT NULL,
      paymentMethod TEXT    NOT NULL,
      dayOfMonth    INTEGER NOT NULL,
      nextDueDate   TEXT    NOT NULL,
      createdAt     TEXT    NOT NULL,
      updatedAt     TEXT,
      isActive      INTEGER NOT NULL DEFAULT 1,
      notes         TEXT
    )
  ''';

  static const _dataTables = [
    'transactions',
    'budgets',
    'goals',
    'custom_categories',
    'recurring_transactions',
  ];

  // ════════════════════════════════════════
  // PROFILES CRUD
  // ════════════════════════════════════════

  Future<void> createProfile(ProfileRecord p) async {
    final db = await database;
    await db.insert(
      'profiles',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('✅ Profile saved: ${p.name} (id=${p.id})');
  }

  Future<List<ProfileRecord>> getAllProfiles() async {
    try {
      final db = await database;
      final result = await db.query('profiles', orderBy: 'created_at ASC');
      print('📖 Loaded ${result.length} profiles');
      return result.map(ProfileRecord.fromMap).toList();
    } catch (e) {
      print('❌ getAllProfiles: $e');
      return [];
    }
  }

  Future<void> updateProfile(ProfileRecord p) async {
    final db = await database;
    await db.update('profiles', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
    print('✅ Profile updated: ${p.name}');
  }

  // Deletes the profile row AND all its data from every table
  Future<void> deleteProfile(String profileId) async {
    final db = await database;
    for (final t in _dataTables) {
      await db.delete(t, where: 'profile_id = ?', whereArgs: [profileId]);
    }
    await db.delete('profiles', where: 'id = ?', whereArgs: [profileId]);
    print('🗑️ Profile + all data deleted: $profileId');
  }

  // ════════════════════════════════════════
  // TRANSACTIONS
  // ════════════════════════════════════════

  Future<int> createTransaction(model.Transaction transaction) async {
    try {
      final db = await database;
      final data = transaction.toJson();
      data['profile_id'] = _activeProfileId;
      return await db.insert(
        'transactions',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('❌ createTransaction: $e');
      rethrow;
    }
  }

  Future<List<model.Transaction>> getAllTransactions() async {
    try {
      final db = await database;
      final result = await db.query(
        'transactions',
        where: 'profile_id = ?',
        whereArgs: [_activeProfileId],
        orderBy: 'date DESC',
      );
      return result.map((j) => model.Transaction.fromJson(j)).toList();
    } catch (e) {
      print('❌ getAllTransactions: $e');
      return [];
    }
  }

  Future<model.Transaction?> getTransaction(String id) async {
    try {
      final db = await database;
      final r = await db.query(
        'transactions',
        where: 'id = ? AND profile_id = ?',
        whereArgs: [id, _activeProfileId],
        limit: 1,
      );
      return r.isNotEmpty ? model.Transaction.fromJson(r.first) : null;
    } catch (_) {
      return null;
    }
  }

  Future<int> updateTransaction(model.Transaction t) async {
    try {
      final db = await database;
      return await db.update(
        'transactions',
        t.toJson(),
        where: 'id = ? AND profile_id = ?',
        whereArgs: [t.id, _activeProfileId],
      );
    } catch (e) {
      print('❌ updateTransaction: $e');
      rethrow;
    }
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return db.delete(
      'transactions',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, _activeProfileId],
    );
  }

  Future<int> deleteAllTransactions() async {
    final db = await database;
    return db.delete(
      'transactions',
      where: 'profile_id = ?',
      whereArgs: [_activeProfileId],
    );
  }

  Future<List<model.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await database;
      final r = await db.query(
        'transactions',
        where: 'profile_id = ? AND date BETWEEN ? AND ?',
        whereArgs: [
          _activeProfileId,
          start.toIso8601String(),
          end.toIso8601String(),
        ],
        orderBy: 'date DESC',
      );
      return r.map((j) => model.Transaction.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════
  // BUDGETS
  // ════════════════════════════════════════

  Future<int> createBudget(Budget b) async {
    try {
      final db = await database;
      final data = _budgetToMap(b);
      data['profile_id'] = _activeProfileId;
      return await db.insert(
        'budgets',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('❌ createBudget: $e');
      rethrow;
    }
  }

  Future<List<Budget>> getAllBudgets() async {
    try {
      final db = await database;
      final r = await db.query(
        'budgets',
        where: 'profile_id = ?',
        whereArgs: [_activeProfileId],
        orderBy: 'created_at DESC',
      );
      return r.map(_budgetFromMap).toList();
    } catch (e) {
      print('❌ getAllBudgets: $e');
      return [];
    }
  }

  Future<int> updateBudget(Budget b) async {
    try {
      final db = await database;
      final data = _budgetToMap(b);
      data['profile_id'] = _activeProfileId;
      return await db.update(
        'budgets',
        data,
        where: 'id = ? AND profile_id = ?',
        whereArgs: [b.id, _activeProfileId],
      );
    } catch (e) {
      print('❌ updateBudget: $e');
      rethrow;
    }
  }

  Future<int> deleteBudget(String id) async {
    final db = await database;
    return db.delete(
      'budgets',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, _activeProfileId],
    );
  }

  Future<Map<String, double>> getMonthlySpendingByCategory() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1).toIso8601String();
      final end = DateTime(
        now.year,
        now.month + 1,
        0,
        23,
        59,
        59,
      ).toIso8601String();
      final r = await db.rawQuery(
        '''
        SELECT category, SUM(amount) as total
        FROM transactions
        WHERE profile_id = ? AND type = 'expense' AND date BETWEEN ? AND ?
        GROUP BY category
      ''',
        [_activeProfileId, start, end],
      );
      return {
        for (final row in r)
          row['category'] as String: (row['total'] as num).toDouble(),
      };
    } catch (_) {
      return {};
    }
  }

  // ════════════════════════════════════════
  // GOALS
  // ════════════════════════════════════════

  Future<int> createGoal(Goal g) async {
    try {
      final db = await database;
      final data = _goalToMap(g);
      data['profile_id'] = _activeProfileId;
      return await db.insert(
        'goals',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('❌ createGoal: $e');
      rethrow;
    }
  }

  Future<List<Goal>> getAllGoals() async {
    try {
      final db = await database;
      final r = await db.query(
        'goals',
        where: 'profile_id = ?',
        whereArgs: [_activeProfileId],
        orderBy: 'created_at DESC',
      );
      return r.map(_goalFromMap).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> updateGoal(Goal g) async {
    final db = await database;
    final data = _goalToMap(g);
    data['profile_id'] = _activeProfileId;
    return db.update(
      'goals',
      data,
      where: 'id = ? AND profile_id = ?',
      whereArgs: [g.id, _activeProfileId],
    );
  }

  Future<int> deleteGoal(String id) async {
    final db = await database;
    return db.delete(
      'goals',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, _activeProfileId],
    );
  }

  // ════════════════════════════════════════
  // CUSTOM CATEGORIES
  // ════════════════════════════════════════

  Future<int> createCustomCategory(Category c) async {
    final db = await database;
    final data = _categoryToMap(c);
    data['profile_id'] = _activeProfileId;
    return db.insert(
      'custom_categories',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Category>> getCustomCategories({String? type}) async {
    try {
      final db = await database;
      final r = type != null
          ? await db.query(
              'custom_categories',
              where: 'profile_id = ? AND type = ?',
              whereArgs: [_activeProfileId, type],
              orderBy: 'created_at ASC',
            )
          : await db.query(
              'custom_categories',
              where: 'profile_id = ?',
              whereArgs: [_activeProfileId],
              orderBy: 'created_at ASC',
            );
      return r.map(_categoryFromMap).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> deleteCustomCategory(String id) async {
    final db = await database;
    return db.delete(
      'custom_categories',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, _activeProfileId],
    );
  }

  // ════════════════════════════════════════
  // RECURRING TRANSACTIONS
  // ════════════════════════════════════════

  Future<int> createRecurringTransaction(RecurringTransaction r) async {
    final db = await database;
    final data = r.toJson();
    data['profile_id'] = _activeProfileId;
    return db.insert(
      'recurring_transactions',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RecurringTransaction>> getAllRecurringTransactions() async {
    try {
      final db = await database;
      final r = await db.query(
        'recurring_transactions',
        where: 'profile_id = ? AND isActive = ?',
        whereArgs: [_activeProfileId, 1],
        orderBy: 'dayOfMonth ASC',
      );
      return r.map((m) => RecurringTransaction.fromJson(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RecurringTransaction>> getDueRecurringTransactions() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final today = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toIso8601String();
      final r = await db.query(
        'recurring_transactions',
        where: 'profile_id = ? AND isActive = ? AND nextDueDate <= ?',
        whereArgs: [_activeProfileId, 1, today],
      );
      return r.map((m) => RecurringTransaction.fromJson(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> updateRecurringTransaction(RecurringTransaction r) async {
    final db = await database;
    final data = r.toJson();
    data['profile_id'] = _activeProfileId;
    return db.update(
      'recurring_transactions',
      data,
      where: 'id = ? AND profile_id = ?',
      whereArgs: [r.id, _activeProfileId],
    );
  }

  Future<int> deleteRecurringTransaction(String id) async {
    final db = await database;
    return db.delete(
      'recurring_transactions',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, _activeProfileId],
    );
  }

  // ════════════════════════════════════════
  // MAP HELPERS
  // ════════════════════════════════════════

  Map<String, dynamic> _budgetToMap(Budget b) => {
    'id': b.id,
    'category': b.category,
    'limit_amount': b.limit,
    'start_date': b.startDate.toIso8601String(),
    'end_date': b.endDate.toIso8601String(),
    'is_active': b.isActive ? 1 : 0,
    'created_at': b.createdAt.toIso8601String(),
    'updated_at': b.updatedAt?.toIso8601String(),
  };

  Budget _budgetFromMap(Map<String, dynamic> m) => Budget(
    id: m['id'] as String,
    category: m['category'] as String,
    limit: (m['limit_amount'] as num).toDouble(),
    used: 0.0,
    startDate: DateTime.parse(m['start_date'] as String),
    endDate: DateTime.parse(m['end_date'] as String),
    isActive: (m['is_active'] as int) == 1,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: m['updated_at'] != null
        ? DateTime.parse(m['updated_at'] as String)
        : null,
  );

  Map<String, dynamic> _goalToMap(Goal g) => {
    'id': g.id,
    'name': g.name,
    'target_amount': g.targetAmount,
    'current_amount': g.currentAmount,
    'deadline': g.deadline?.toIso8601String(),
    'description': g.description,
    'is_completed': g.isCompleted ? 1 : 0,
    'created_at': g.createdAt.toIso8601String(),
    'updated_at': g.updatedAt?.toIso8601String(),
    'completed_at': g.completedAt?.toIso8601String(),
  };

  Goal _goalFromMap(Map<String, dynamic> m) => Goal(
    id: m['id'] as String,
    name: m['name'] as String,
    targetAmount: (m['target_amount'] as num).toDouble(),
    currentAmount: (m['current_amount'] as num).toDouble(),
    deadline: m['deadline'] != null
        ? DateTime.parse(m['deadline'] as String)
        : null,
    description: m['description'] as String?,
    isCompleted: (m['is_completed'] as int) == 1,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: m['updated_at'] != null
        ? DateTime.parse(m['updated_at'] as String)
        : null,
    completedAt: m['completed_at'] != null
        ? DateTime.parse(m['completed_at'] as String)
        : null,
  );

  Map<String, dynamic> _categoryToMap(Category c) => {
    'id': c.id,
    'name': c.name,
    'icon_code_point': c.icon.codePoint,
    'color_value': c.color.value,
    'type': c.type,
    'created_at': c.createdAt.toIso8601String(),
  };

  Category _categoryFromMap(Map<String, dynamic> m) => Category(
    id: m['id'] as String,
    name: m['name'] as String,
    icon: IconData(m['icon_code_point'] as int, fontFamily: 'MaterialIcons'),
    color: Color(m['color_value'] as int),
    type: m['type'] as String,
    isDefault: false,
    createdAt: DateTime.parse(m['created_at'] as String),
  );

  Future<void> close() async => (await database).close();

  Future<void> nukeDatabase() async {
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dbPath, 'spendwise.db'));
    _database = null;
    print('💣 DB wiped');
  }
}
