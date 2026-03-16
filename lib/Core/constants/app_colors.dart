import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// DARK THEME COLORS (unchanged)
// ─────────────────────────────────────────────
class AppColors {
  // Primary
  static const Color primary = Color(0xFF00D9FF);
  static const Color primaryLight = Color(0xFF64E9FF);
  static const Color primaryDark = Color(0xFF00A8CC);

  // Accent
  static const Color accent = Color(0xFFB794F6);
  static const Color accentLight = Color(0xFFD4BBFF);

  // Backgrounds
  static const Color background = Color(0xFF0F0F1E);
  static const Color cardBackground = Color(0xFF1A1A2E);
  static const Color darkBackground = Color(0xFF0F0F1E);
  static const Color darkCardBackground = Color(0xFF1A1A2E);

  // Surfaces
  static const Color surface = Color(0xFF16213E);
  static const Color surfaceLight = Color(0xFF1F2937);

  // Glassmorphism
  static final Color glassBackground = Colors.white.withOpacity(0.05);
  static final Color glassBorder = Colors.white.withOpacity(0.1);

  // Text
  static const Color textPrimary = Color(0xFFE8E8F0);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFF6B7280);
  static const Color textDark = Color(0xFFECF0F1);

  // Income & Expense
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFEF4444);
  static const Color incomeLight = Color(0xFF34D399);
  static const Color expenseLight = Color(0xFFF87171);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Category Colors
  static const Color foodColor = Color(0xFF3B82F6);
  static const Color transportColor = Color(0xFF10B981);
  static const Color billsColor = Color(0xFFF59E0B);
  static const Color entertainmentColor = Color(0xFFA855F7);
  static const Color shoppingColor = Color(0xFFEC4899);
  static const Color healthColor = Color(0xFF06B6D4);
  static const Color educationColor = Color(0xFF6366F1);
  static const Color otherColor = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D9FF), Color(0xFF7B2FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient modernBlue = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient modernGreen = LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient modernPurple = LinearGradient(
    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient neonPink = LinearGradient(
    colors: [Color(0xFFFF006E), Color(0xFFFFBE0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient neonBlue = LinearGradient(
    colors: [Color(0xFF00D9FF), Color(0xFF7B2FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient neonPurple = LinearGradient(
    colors: [Color(0xFFB794F6), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static final Color shadowLight = Colors.black.withOpacity(0.3);
  static final Color shadowDark = Colors.black.withOpacity(0.5);

  // Dividers
  static const Color divider = Color(0xFF374151);
  static const Color dividerDark = Color(0xFF1F2937);

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return foodColor;
      case 'transport':
        return transportColor;
      case 'bills':
        return billsColor;
      case 'entertainment':
        return entertainmentColor;
      case 'shopping':
        return shoppingColor;
      case 'health':
        return healthColor;
      case 'education':
        return educationColor;
      default:
        return otherColor;
    }
  }
}

// ─────────────────────────────────────────────
// LIGHT THEME COLORS
// Clean, modern, professional — inspired by
// Revolut / Linear / Notion light aesthetics
// ─────────────────────────────────────────────
class LightColors {
  // Primary — slightly deeper teal for readability on white
  static const Color primary = Color(0xFF0EA5E9); // Sky blue
  static const Color primaryLight = Color(0xFF38BDF8);
  static const Color primaryDark = Color(0xFF0284C7);

  // Accent
  static const Color accent = Color(0xFF8B5CF6); // Violet
  static const Color accentLight = Color(0xFFA78BFA);

  // Backgrounds — warm white, not pure white
  static const Color background = Color(0xFFF8F9FC); // Off-white
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure white cards
  static const Color surface = Color(0xFFF1F4F9); // Slightly grey
  static const Color surfaceLight = Color(0xFFE8EDF5);

  // Text
  static const Color textPrimary = Color(0xFF0F172A); // Near black
  static const Color textSecondary = Color(0xFF475569); // Slate
  static const Color textLight = Color(0xFF94A3B8); // Light slate
  static const Color textHint = Color(0xFFCBD5E1);

  // Income & Expense (same as dark — universally understood)
  static const Color income = Color(
    0xFF059669,
  ); // Slightly darker green for light bg
  static const Color expense = Color(
    0xFFDC2626,
  ); // Slightly darker red for light bg
  static const Color incomeLight = Color(0xFF10B981);
  static const Color expenseLight = Color(0xFFEF4444);

  // Status
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Category colors — slightly deeper for light background readability
  static const Color foodColor = Color(0xFF2563EB);
  static const Color transportColor = Color(0xFF059669);
  static const Color billsColor = Color(0xFFD97706);
  static const Color entertainmentColor = Color(0xFF7C3AED);
  static const Color shoppingColor = Color(0xFFDB2777);
  static const Color healthColor = Color(0xFF0891B2);
  static const Color educationColor = Color(0xFF4F46E5);
  static const Color otherColor = Color(0xFF475569);

  // Dividers & borders
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // Shadows — subtle for light theme
  static final Color shadowLight = Colors.black.withOpacity(0.06);
  static final Color shadowMedium = Colors.black.withOpacity(0.10);

  // Gradients — softer for light theme
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return foodColor;
      case 'transport':
        return transportColor;
      case 'bills':
        return billsColor;
      case 'entertainment':
        return entertainmentColor;
      case 'shopping':
        return shoppingColor;
      case 'health':
        return healthColor;
      case 'education':
        return educationColor;
      default:
        return otherColor;
    }
  }
}
