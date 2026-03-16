import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../Core/constants/app_colors.dart';
import '../../../Core/utils/currency_formatter.dart';
import '../../../Providers/transaction_provider.dart';

class SpendingTrendChart extends StatelessWidget {
  const SpendingTrendChart({Key? key}) : super(key: key);

  /// Build the last 6 months data from real transactions
  List<_MonthData> _buildMonthlyData(TransactionProvider provider) {
    final now = DateTime.now();
    final months = <_MonthData>[];

    for (int i = 5; i >= 0; i--) {
      // Calculate start and end of each month going back 6 months
      final monthDate = DateTime(now.year, now.month - i, 1);
      final startOfMonth = DateTime(monthDate.year, monthDate.month, 1);
      final endOfMonth = DateTime(
        monthDate.year,
        monthDate.month + 1,
        0,
        23,
        59,
        59,
      );

      final transactions = provider.getTransactionsByDateRange(
        startOfMonth,
        endOfMonth,
      );

      double income = 0;
      double expense = 0;

      for (final t in transactions) {
        if (t.isIncome) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }

      months.add(
        _MonthData(
          label: _monthLabel(monthDate.month),
          income: income,
          expense: expense,
        ),
      );
    }

    return months;
  }

  String _monthLabel(int month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final monthlyData = _buildMonthlyData(provider);

        // Check if there's any real data
        final hasData = monthlyData.any((m) => m.income > 0 || m.expense > 0);

        if (!hasData) {
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
                      Icons.show_chart,
                      size: 48,
                      color: AppColors.textLight,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Add transactions to see your trend',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Calculate max Y for chart scale
        final allValues = monthlyData
            .expand((m) => [m.income, m.expense])
            .where((v) => v > 0)
            .toList();
        final maxValue = allValues.isEmpty
            ? 10000.0
            : allValues.reduce((a, b) => a > b ? a : b);
        // Round up to next clean interval
        final maxY = _roundUpMax(maxValue);
        final interval = maxY / 4;

        final incomeSpots = monthlyData.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.income);
        }).toList();

        final expenseSpots = monthlyData.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.expense);
        }).toList();

        return Card(
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Last 6 Months',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        _buildLegendItem('Income', AppColors.income),
                        const SizedBox(width: 16),
                        _buildLegendItem('Expense', AppColors.expense),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: interval > 0 ? interval : 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withOpacity(0.06),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < monthlyData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    monthlyData[index].label,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: interval > 0 ? interval : 1,
                            reservedSize: 48,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) {
                                return const Text(
                                  '0',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                );
                              }
                              return Text(
                                _formatAxisValue(value),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 5,
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        // Income line
                        LineChartBarData(
                          spots: incomeSpots,
                          isCurved: true,
                          color: AppColors.income,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: spot.y > 0 ? 4 : 0,
                                  color: AppColors.income,
                                  strokeWidth: 2,
                                  strokeColor: AppColors.cardBackground,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.income.withOpacity(0.15),
                                AppColors.income.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        // Expense line
                        LineChartBarData(
                          spots: expenseSpots,
                          isCurved: true,
                          color: AppColors.expense,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: spot.y > 0 ? 4 : 0,
                                  color: AppColors.expense,
                                  strokeWidth: 2,
                                  strokeColor: AppColors.cardBackground,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.expense.withOpacity(0.15),
                                AppColors.expense.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surface,
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final isIncome = spot.barIndex == 0;
                              return LineTooltipItem(
                                '${isIncome ? 'Income' : 'Expense'}\n${CurrencyFormatter.formatCompact(spot.y)}',
                                TextStyle(
                                  color: isIncome
                                      ? AppColors.income
                                      : AppColors.expense,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Round up to a clean number for the Y axis max
  double _roundUpMax(double value) {
    if (value <= 0) return 10000;
    final magnitude = (value / 4).ceil();
    // Round to nearest 1000, 5000, 10000 etc.
    if (magnitude < 1000) return (magnitude / 100).ceil() * 100 * 4;
    if (magnitude < 10000) return (magnitude / 1000).ceil() * 1000 * 4;
    return (magnitude / 10000).ceil() * 10000 * 4;
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toInt()}K';
    return value.toInt().toString();
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _MonthData {
  final String label;
  final double income;
  final double expense;

  _MonthData({
    required this.label,
    required this.income,
    required this.expense,
  });
}
