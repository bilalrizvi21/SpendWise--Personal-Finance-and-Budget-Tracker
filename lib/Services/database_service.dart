import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../Models/transaction.dart' as model;
import '../Models/budget.dart';
import '../Models/goal.dart';
import '../Models/category.dart';
import 'package:flutter/material.dart';

/// Database Service - Manages all database operations
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('spendwise.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    print('📁 Database path: $path');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) => print('✅ Database opened successfully!'),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0,
        deadline TEXT,
        description TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        completed_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    print('✅ All database tables created successfully!');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id TEXT PRIMARY KEY,
          category TEXT NOT NULL,
          limit_amount REAL NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');
      print('✅ Upgraded to v2 — budgets table added');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goals (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          target_amount REAL NOT NULL,
          current_amount REAL NOT NULL DEFAULT 0,
          deadline TEXT,
          description TEXT,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          completed_at TEXT
        )
      ''');
      print('✅ Upgraded to v3 — goals table added');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon_code_point INTEGER NOT NULL,
          color_value INTEGER NOT NULL,
          type TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      print('✅ Upgraded to v4 — custom_categories table added');
    }
  }

  // ========== TRANSACTIONS CRUD ==========

  Future<int> createTransaction(model.Transaction transaction) async {
    try {
      final db = await database;
      final id = await db.insert(
        'transactions',
        transaction.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Transaction created: $id');
      return id;
    } catch (e) {
      print('❌ Error in createTransaction: $e');
      rethrow;
    }
  }

  Future<List<model.Transaction>> getAllTransactions() async {
    try {
      final db = await database;
      final result = await db.query('transactions', orderBy: 'date DESC');
      print('📖 Loaded ${result.length} transactions');
      return result.map((json) => model.Transaction.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error in getAllTransactions: $e');
      return [];
    }
  }

  Future<model.Transaction?> getTransaction(String id) async {
    try {
      final db = await database;
      final result = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (result.isNotEmpty) return model.Transaction.fromJson(result.first);
      return null;
    } catch (e) {
      print('❌ Error in getTransaction: $e');
      return null;
    }
  }

  Future<int> updateTransaction(model.Transaction transaction) async {
    try {
      final db = await database;
      final count = await db.update(
        'transactions',
        transaction.toJson(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
      print('✅ Transaction updated: ${transaction.id}');
      return count;
    } catch (e) {
      print('❌ Error in updateTransaction: $e');
      rethrow;
    }
  }

  Future<int> deleteTransaction(String id) async {
    try {
      final db = await database;
      final count = await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('🗑️ Transaction deleted: $id');
      return count;
    } catch (e) {
      print('❌ Error in deleteTransaction: $e');
      rethrow;
    }
  }

  Future<int> deleteAllTransactions() async {
    try {
      final db = await database;
      final count = await db.delete('transactions');
      print('🗑️ Deleted all $count transactions');
      return count;
    } catch (e) {
      print('❌ Error in deleteAllTransactions: $e');
      return 0;
    }
  }

  Future<List<model.Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await database;
      final result = await db.query(
        'transactions',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'date DESC',
      );
      return result.map((json) => model.Transaction.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error in getTransactionsByDateRange: $e');
      return [];
    }
  }

  Future<List<model.Transaction>> getTransactionsByType(String type) async {
    try {
      final db = await database;
      final result = await db.query(
        'transactions',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'date DESC',
      );
      return result.map((json) => model.Transaction.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error in getTransactionsByType: $e');
      return [];
    }
  }

  // ========== BUDGETS CRUD ==========

  Future<int> createBudget(Budget budget) async {
    try {
      final db = await database;
      final id = await db.insert(
        'budgets',
        _budgetToMap(budget),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Budget created: ${budget.category}');
      return id;
    } catch (e) {
      print('❌ Error in createBudget: $e');
      rethrow;
    }
  }

  Future<List<Budget>> getAllBudgets() async {
    try {
      final db = await database;
      final result = await db.query('budgets', orderBy: 'created_at DESC');
      print('📖 Loaded ${result.length} budgets');
      return result.map((map) => _budgetFromMap(map)).toList();
    } catch (e) {
      print('❌ Error in getAllBudgets: $e');
      return [];
    }
  }

  Future<int> updateBudget(Budget budget) async {
    try {
      final db = await database;
      final count = await db.update(
        'budgets',
        _budgetToMap(budget),
        where: 'id = ?',
        whereArgs: [budget.id],
      );
      print('✅ Budget updated: ${budget.category}');
      return count;
    } catch (e) {
      print('❌ Error in updateBudget: $e');
      rethrow;
    }
  }

  Future<int> deleteBudget(String id) async {
    try {
      final db = await database;
      final count = await db.delete(
        'budgets',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('🗑️ Budget deleted: $id');
      return count;
    } catch (e) {
      print('❌ Error in deleteBudget: $e');
      rethrow;
    }
  }

  Future<Map<String, double>> getMonthlySpendingByCategory() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      final endOfMonth = DateTime(
        now.year,
        now.month + 1,
        0,
        23,
        59,
        59,
      ).toIso8601String();

      final result = await db.rawQuery(
        '''
        SELECT category, SUM(amount) as total
        FROM transactions
        WHERE type = 'expense'
          AND date BETWEEN ? AND ?
        GROUP BY category
      ''',
        [startOfMonth, endOfMonth],
      );

      final Map<String, double> spending = {};
      for (final row in result) {
        spending[row['category'] as String] = (row['total'] as num).toDouble();
      }
      print('📊 Monthly spending: $spending');
      return spending;
    } catch (e) {
      print('❌ Error in getMonthlySpendingByCategory: $e');
      return {};
    }
  }

  // ========== GOALS CRUD ==========

  Future<int> createGoal(Goal goal) async {
    try {
      final db = await database;
      final id = await db.insert(
        'goals',
        _goalToMap(goal),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Goal created: ${goal.name}');
      return id;
    } catch (e) {
      print('❌ Error in createGoal: $e');
      rethrow;
    }
  }

  Future<List<Goal>> getAllGoals() async {
    try {
      final db = await database;
      final result = await db.query('goals', orderBy: 'created_at DESC');
      print('📖 Loaded ${result.length} goals');
      return result.map((map) => _goalFromMap(map)).toList();
    } catch (e) {
      print('❌ Error in getAllGoals: $e');
      return [];
    }
  }

  Future<int> updateGoal(Goal goal) async {
    try {
      final db = await database;
      final count = await db.update(
        'goals',
        _goalToMap(goal),
        where: 'id = ?',
        whereArgs: [goal.id],
      );
      print('✅ Goal updated: ${goal.name}');
      return count;
    } catch (e) {
      print('❌ Error in updateGoal: $e');
      rethrow;
    }
  }

  Future<int> deleteGoal(String id) async {
    try {
      final db = await database;
      final count = await db.delete('goals', where: 'id = ?', whereArgs: [id]);
      print('🗑️ Goal deleted: $id');
      return count;
    } catch (e) {
      print('❌ Error in deleteGoal: $e');
      rethrow;
    }
  }

  // ========== CUSTOM CATEGORIES CRUD ==========

  Future<int> createCustomCategory(Category category) async {
    try {
      final db = await database;
      final id = await db.insert(
        'custom_categories',
        _categoryToMap(category),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Custom category created: ${category.name}');
      return id;
    } catch (e) {
      print('❌ Error in createCustomCategory: $e');
      rethrow;
    }
  }

  Future<List<Category>> getCustomCategories({String? type}) async {
    try {
      final db = await database;
      final result = type != null
          ? await db.query(
              'custom_categories',
              where: 'type = ?',
              whereArgs: [type],
              orderBy: 'created_at ASC',
            )
          : await db.query('custom_categories', orderBy: 'created_at ASC');
      print('📖 Loaded ${result.length} custom categories');
      return result.map((map) => _categoryFromMap(map)).toList();
    } catch (e) {
      print('❌ Error in getCustomCategories: $e');
      return [];
    }
  }

  Future<int> deleteCustomCategory(String id) async {
    try {
      final db = await database;
      final count = await db.delete(
        'custom_categories',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('🗑️ Custom category deleted: $id');
      return count;
    } catch (e) {
      print('❌ Error in deleteCustomCategory: $e');
      rethrow;
    }
  }

  // ========== HELPERS ==========

  Map<String, dynamic> _budgetToMap(Budget budget) => {
    'id': budget.id,
    'category': budget.category,
    'limit_amount': budget.limit,
    'start_date': budget.startDate.toIso8601String(),
    'end_date': budget.endDate.toIso8601String(),
    'is_active': budget.isActive ? 1 : 0,
    'created_at': budget.createdAt.toIso8601String(),
    'updated_at': budget.updatedAt?.toIso8601String(),
  };

  Budget _budgetFromMap(Map<String, dynamic> map) => Budget(
    id: map['id'] as String,
    category: map['category'] as String,
    limit: (map['limit_amount'] as num).toDouble(),
    used: 0.0,
    startDate: DateTime.parse(map['start_date'] as String),
    endDate: DateTime.parse(map['end_date'] as String),
    isActive: (map['is_active'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: map['updated_at'] != null
        ? DateTime.parse(map['updated_at'] as String)
        : null,
  );

  Map<String, dynamic> _goalToMap(Goal goal) => {
    'id': goal.id,
    'name': goal.name,
    'target_amount': goal.targetAmount,
    'current_amount': goal.currentAmount,
    'deadline': goal.deadline?.toIso8601String(),
    'description': goal.description,
    'is_completed': goal.isCompleted ? 1 : 0,
    'created_at': goal.createdAt.toIso8601String(),
    'updated_at': goal.updatedAt?.toIso8601String(),
    'completed_at': goal.completedAt?.toIso8601String(),
  };

  Goal _goalFromMap(Map<String, dynamic> map) => Goal(
    id: map['id'] as String,
    name: map['name'] as String,
    targetAmount: (map['target_amount'] as num).toDouble(),
    currentAmount: (map['current_amount'] as num).toDouble(),
    deadline: map['deadline'] != null
        ? DateTime.parse(map['deadline'] as String)
        : null,
    description: map['description'] as String?,
    isCompleted: (map['is_completed'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: map['updated_at'] != null
        ? DateTime.parse(map['updated_at'] as String)
        : null,
    completedAt: map['completed_at'] != null
        ? DateTime.parse(map['completed_at'] as String)
        : null,
  );

  Map<String, dynamic> _categoryToMap(Category category) => {
    'id': category.id,
    'name': category.name,
    'icon_code_point': category.icon.codePoint,
    'color_value': category.color.value,
    'type': category.type,
    'created_at': category.createdAt.toIso8601String(),
  };

  Category _categoryFromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as String,
    name: map['name'] as String,
    icon: IconData(map['icon_code_point'] as int, fontFamily: 'MaterialIcons'),
    color: Color(map['color_value'] as int),
    type: map['type'] as String,
    isDefault: false,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Future close() async {
    final db = await database;
    await db.close();
    print('🔒 Database closed');
  }

  Future deleteDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'spendwise.db');
      await databaseFactory.deleteDatabase(path);
      _database = null;
      print('🗑️ Database deleted completely');
    } catch (e) {
      print('❌ Error deleting database: $e');
    }
  }
}
