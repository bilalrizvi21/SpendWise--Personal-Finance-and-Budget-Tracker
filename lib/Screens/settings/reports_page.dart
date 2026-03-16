import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/constants/app_colors.dart';
import '../../Core/utils/currency_formatter.dart';
import '../../Providers/transaction_provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int _selectedMonthOffset = 0; // 0 = current, 1 = last month, etc.

  DateTime get _selectedMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month - _selectedMonthOffset, 1);
  }

  String get _monthLabel {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Monthly Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final startOfMonth = _selectedMonth;
          final endOfMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month + 1,
            0,
            23,
            59,
            59,
          );

          final transactions = provider.getTransactionsByDateRange(
            startOfMonth,
            endOfMonth,
          );
          final summary = provider.getTransactionSummary(
            startDate: startOfMonth,
            endDate: endOfMonth,
          );
          final categories = provider.getCategorySummary(
            startDate: startOfMonth,
            endDate: endOfMonth,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month selector
                _buildMonthSelector(),

                const SizedBox(height: 20),

                // Summary card
                _buildSummaryCard(
                  summary.totalIncome,
                  summary.totalExpense,
                  summary.balance,
                ),

                const SizedBox(height: 20),

                // Transaction count
                _buildStatRow([
                  _StatItem(
                    'Total Transactions',
                    '${transactions.length}',
                    Icons.receipt_long_outlined,
                  ),
                  _StatItem(
                    'Income Entries',
                    '${transactions.where((t) => t.isIncome).length}',
                    Icons.arrow_downward,
                    color: AppColors.income,
                  ),
                  _StatItem(
                    'Expense Entries',
                    '${transactions.where((t) => t.isExpense).length}',
                    Icons.arrow_upward,
                    color: AppColors.expense,
                  ),
                ]),

                const SizedBox(height: 20),

                // Category breakdown
                if (categories.isNotEmpty) ...[
                  const Text(
                    'Spending by Category',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...categories.map(
                    (cat) => _buildCategoryRow(
                      cat.category,
                      cat.amount,
                      summary.totalExpense,
                    ),
                  ),
                ],

                if (categories.isEmpty && transactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assessment_outlined,
                            size: 56,
                            color: AppColors.textLight.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No transactions this month',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => setState(() => _selectedMonthOffset++),
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
        ),
        Text(
          _monthLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: _selectedMonthOffset > 0
              ? () => setState(() => _selectedMonthOffset--)
              : null,
          icon: Icon(
            Icons.chevron_right,
            color: _selectedMonthOffset > 0
                ? AppColors.textPrimary
                : AppColors.textLight.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double income, double expense, double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthLabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              const Text(
                'Monthly Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.formatCompact(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Net Balance',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildCardStat(
                  'Income',
                  income,
                  AppColors.income,
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCardStat(
                  'Expenses',
                  expense,
                  AppColors.expense,
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardStat(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  CurrencyFormatter.formatCompact(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(List<_StatItem> items) {
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: items.last == item ? 0 : 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Icon(
                  item.icon,
                  color: item.color ?? AppColors.primary,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryRow(String category, double amount, double total) {
    final percentage = total > 0 ? (amount / total) : 0.0;
    final color = AppColors.getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.formatCompact(amount),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  _StatItem(this.label, this.value, this.icon, {this.color});
}
