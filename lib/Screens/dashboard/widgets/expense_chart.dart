import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../Core/constants/app_colors.dart';
import '../../../Core/utils/currency_formatter.dart';
import '../../../Providers/transaction_provider.dart';

class ExpenseChart extends StatefulWidget {
  const ExpenseChart({Key? key}) : super(key: key);

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  int? _touchedIndex;

  // Fixed color palette per category — matches AppColors
  static const Map<String, Color> _categoryColors = {
    'food': Color(0xFF00D9FF),
    'transport': Color(0xFF10B981),
    'bills': Color(0xFFB794F6),
    'entertainment': Color(0xFFEC4899),
    'shopping': Color(0xFFF59E0B),
    'health': Color(0xFF06B6D4),
    'education': Color(0xFF6366F1),
    'other': Color(0xFF64748B),
  };

  Color _colorForCategory(String category) {
    return _categoryColors[category.toLowerCase()] ?? const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final categories = provider.getCategorySummary();
        final totalExpense = categories.fold(0.0, (sum, c) => sum + c.amount);

        // No expenses yet
        if (categories.isEmpty || totalExpense == 0) {
          return Card(
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 48,
                      color: AppColors.textLight,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No expenses this month',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final sections = categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          final isTouched = index == _touchedIndex;
          final percentage = (cat.amount / totalExpense * 100);
          final color = _colorForCategory(cat.category);

          return PieChartSectionData(
            value: cat.amount,
            color: color,
            title: isTouched ? '${percentage.toInt()}%' : '',
            radius: isTouched ? 70 : 60,
            titleStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: isTouched ? null : null,
          );
        }).toList();

        return Card(
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 52,
                          sections: sections,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = null;
                                  return;
                                }
                                final index = pieTouchResponse
                                    .touchedSection!
                                    .touchedSectionIndex;
                                // Guard against -1 (background touch) or out of range
                                _touchedIndex =
                                    (index >= 0 && index < categories.length)
                                    ? index
                                    : null;
                              });
                            },
                          ),
                        ),
                      ),
                      // Center label
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _touchedIndex != null &&
                                    _touchedIndex! < categories.length
                                ? categories[_touchedIndex!].category
                                : 'Total',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _touchedIndex != null &&
                                    _touchedIndex! < categories.length
                                ? CurrencyFormatter.formatCompact(
                                    categories[_touchedIndex!].amount,
                                  )
                                : CurrencyFormatter.formatCompact(totalExpense),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Legend with real data
                ...categories.map((cat) {
                  final percentage = (cat.amount / totalExpense * 100);
                  final color = _colorForCategory(cat.category);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat.category,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${percentage.toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          CurrencyFormatter.formatCompact(cat.amount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
