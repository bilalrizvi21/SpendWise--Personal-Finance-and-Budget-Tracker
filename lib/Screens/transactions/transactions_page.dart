import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendwise_2/Core/utils/date_formatter.dart';
import '../../Core/constants/app_strings.dart';
import '../../Core/constants/app_colors.dart';
import '../../Core/widgets/loading_indicator.dart';
import '../../Core/utils/currency_formatter.dart';
import '../../Providers/transaction_provider.dart';
import '../../Models/transaction.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({Key? key}) : super(key: key);

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = AppStrings.filterThisMonth;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Custom date range — only set when user picks Custom
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filter logic ──
  List<Transaction> _getFilteredTransactions(TransactionProvider provider) {
    List<Transaction> transactions;

    switch (_selectedFilter) {
      case AppStrings.filterToday:
        transactions = provider.todayTransactions;
        break;
      case AppStrings.filterThisWeek:
        transactions = provider.thisWeekTransactions;
        break;
      case AppStrings.filterThisMonth:
        transactions = provider.thisMonthTransactions;
        break;
      case AppStrings.filterCustom:
        // If a custom range is set, use it; otherwise show all
        if (_customStart != null && _customEnd != null) {
          transactions = provider.getTransactionsByDateRange(
            _customStart!,
            _customEnd!,
          );
        } else {
          transactions = provider.transactions;
        }
        break;
      default:
        transactions = provider.transactions;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      transactions = transactions.where((t) {
        return t.category.toLowerCase().contains(q) ||
            t.notes?.toLowerCase().contains(q) == true ||
            t.amount.toString().contains(_searchQuery);
      }).toList();
    }

    return transactions;
  }

  // ── Open date range picker for Custom filter ──
  Future<void> _openCustomDatePicker() async {
    // First pick: start date
    final start = await showDatePicker(
      context: context,
      initialDate: _customStart ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select start date',
      builder: (context, child) => _datePickerTheme(child),
    );
    if (start == null || !mounted) return;

    // Second pick: end date (must be >= start)
    final end = await showDatePicker(
      context: context,
      initialDate: _customEnd != null && !_customEnd!.isBefore(start)
          ? _customEnd!
          : start,
      firstDate: start,
      lastDate: DateTime.now(),
      helpText: 'Select end date',
      builder: (context, child) => _datePickerTheme(child),
    );
    if (end == null || !mounted) return;

    setState(() {
      _customStart = start;
      _customEnd = end;
      _selectedFilter = AppStrings.filterCustom;
    });
  }

  Widget _datePickerTheme(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: Colors.black,
          surface: AppColors.cardBackground,
          onSurface: AppColors.textPrimary,
        ),
        dialogBackgroundColor: AppColors.background,
      ),
      child: child!,
    );
  }

  // ── Label shown on the Custom chip ──
  String get _customChipLabel {
    if (_selectedFilter == AppStrings.filterCustom &&
        _customStart != null &&
        _customEnd != null) {
      final s = DateFormatter.formatDateCompact(_customStart!);
      final e = DateFormatter.formatDateCompact(_customEnd!);
      return '$s – $e';
    }
    return AppStrings.filterCustom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          AppStrings.transactions,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final filteredTransactions = _getFilteredTransactions(provider);

          return Column(
            children: [
              const SizedBox(height: 100),

              // ── Stats header card ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF11998E).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total',
                      filteredTransactions.length.toString(),
                      Icons.receipt_long,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildStatItem(
                      'Income',
                      filteredTransactions
                          .where((t) => t.isIncome)
                          .length
                          .toString(),
                      Icons.arrow_downward,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildStatItem(
                      'Expense',
                      filteredTransactions
                          .where((t) => t.isExpense)
                          .length
                          .toString(),
                      Icons.arrow_upward,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Filter chips ──
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children:
                      [
                        AppStrings.filterToday,
                        AppStrings.filterThisWeek,
                        AppStrings.filterThisMonth,
                        AppStrings.filterCustom,
                      ].map((filter) {
                        final isCustom = filter == AppStrings.filterCustom;
                        final isSelected = _selectedFilter == filter;
                        final label = isCustom ? _customChipLabel : filter;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCustom)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.date_range,
                                      size: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                Text(label),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (isCustom) {
                                // Always open the picker when tapping Custom
                                _openCustomDatePicker();
                              } else if (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                  // Clear custom range when switching away
                                  _customStart = null;
                                  _customEnd = null;
                                });
                              }
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.cardBackground,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            elevation: isSelected ? 4 : 0,
                            shadowColor: AppColors.primary.withOpacity(0.5),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),

              // ── Custom range active indicator ──
              if (_selectedFilter == AppStrings.filterCustom &&
                  _customStart != null &&
                  _customEnd != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Showing: ${DateFormatter.formatDate(_customStart!)} → '
                        '${DateFormatter.formatDate(_customEnd!)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() {
                          _customStart = null;
                          _customEnd = null;
                          _selectedFilter = AppStrings.filterThisMonth;
                        }),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Search bar ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchTransactions,
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Transaction list ──
              Expanded(
                child: provider.isLoading
                    ? const Center(child: LoadingIndicator(size: 48))
                    : filteredTransactions.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title:
                            _selectedFilter == AppStrings.filterCustom &&
                                _customStart != null
                            ? 'No transactions in this range'
                            : AppStrings.noTransactions,
                        description:
                            _selectedFilter == AppStrings.filterCustom &&
                                _customStart != null
                            ? 'Try selecting a different date range'
                            : 'Add your first transaction to get started',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          return _buildTransactionCard(transaction);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: transaction.isIncome
                ? AppColors.incomeGradient
                : AppColors.expenseGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          transaction.category,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormatter.formatDate(transaction.date),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            if (transaction.notes != null && transaction.notes!.isNotEmpty)
              Text(
                transaction.notes!,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatWithSign(
                transaction.amount,
                showPlus: transaction.isIncome,
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: transaction.isIncome
                    ? AppColors.income
                    : AppColors.expense,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              transaction.paymentMethod,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
        ),
      ],
    );
  }
}
