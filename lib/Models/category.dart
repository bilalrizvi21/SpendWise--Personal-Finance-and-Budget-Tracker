import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String type; // 'expense' or 'income' or 'both'
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.type = 'expense',
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Copy with method
  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    String? type,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'type': type,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      color: Color(json['colorValue'] as int),
      type: json['type'] as String? ?? 'expense',
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Default Categories Helper Class
class DefaultCategories {
  // Expense Categories
  static List<Category> get expenseCategories => [
    Category(
      id: 'food',
      name: 'Food',
      icon: Icons.restaurant,
      color: const Color(0xFF2196F3),
      type: 'expense',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car,
      color: const Color(0xFF4CAF50),
      type: 'expense',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'bills',
      name: 'Bills',
      icon: Icons.receipt,
      color: const Color(0xFFFF9800),
      type: 'expense',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie,
      color: const Color(0xFF9C27B0),
      type: 'expense',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: const Color(0xFFE91E63),
      type: 'expense',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'health',
      name: 'Health',
      icon: Icons.health_and_safety,
      color: const Color(0xFF00BCD4),
      type: 'expense',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'education',
      name: 'Education',
      icon: Icons.school,
      color: const Color(0xFF3F51B5),
      type: 'expense',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'other',
      name: 'Other',
      icon: Icons.more_horiz,
      color: const Color(0xFF607D8B),
      type: 'expense',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
  ];

  // Income Categories
  static List<Category> get incomeCategories => [
    Category(
      id: 'salary',
      name: 'Salary',
      icon: Icons.attach_money,
      color: const Color(0xFF4CAF50),
      type: 'income',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'freelance',
      name: 'Freelance',
      icon: Icons.work,
      color: const Color(0xFF2196F3),
      type: 'income',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'investment',
      name: 'Investment',
      icon: Icons.trending_up,
      color: const Color(0xFF9C27B0),
      type: 'income',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'gift',
      name: 'Gift',
      icon: Icons.card_giftcard,
      color: const Color(0xFFE91E63),
      type: 'income',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    Category(
      id: 'other_income',
      name: 'Other',
      icon: Icons.more_horiz,
      color: const Color(0xFF607D8B),
      type: 'income',
      isDefault: true,
      createdAt: DateTime.now(),
    ),
  ];

  // Get all default categories
  static List<Category> get allCategories => [
    ...expenseCategories,
    ...incomeCategories,
  ];

  // Get categories by type
  static List<Category> getCategoriesByType(String type) {
    if (type.toLowerCase() == 'income') return incomeCategories;
    if (type.toLowerCase() == 'expense') return expenseCategories;
    return allCategories;
  }

  // Get category by name
  static Category? getCategoryByName(String name) {
    try {
      return allCategories.firstWhere(
        (cat) => cat.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Get category by id
  static Category? getCategoryById(String id) {
    try {
      return allCategories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}

// Available Icons for Category Selection
class CategoryIcons {
  static List<IconData> get icons => [
    Icons.restaurant,
    Icons.directions_car,
    Icons.receipt,
    Icons.movie,
    Icons.shopping_bag,
    Icons.health_and_safety,
    Icons.school,
    Icons.home,
    Icons.phone,
    Icons.local_gas_station,
    Icons.fitness_center,
    Icons.sports_soccer,
    Icons.pets,
    Icons.child_care,
    Icons.flight,
    Icons.hotel,
    Icons.local_cafe,
    Icons.fastfood,
    Icons.liquor,
    Icons.local_taxi,
    Icons.directions_bus,
    Icons.train,
    Icons.local_hospital,
    Icons.local_pharmacy,
    Icons.book,
    Icons.computer,
    Icons.smartphone,
    Icons.tv,
    Icons.games,
    Icons.music_note,
    Icons.palette,
    Icons.camera_alt,
  ];
}

// Available Colors for Category Selection
class CategoryColors {
  static List<Color> get colors => [
    const Color(0xFF2196F3), // Blue
    const Color(0xFF4CAF50), // Green
    const Color(0xFFFF9800), // Orange
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFE91E63), // Pink
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFFF44336), // Red
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF795548), // Brown
  ];
}
