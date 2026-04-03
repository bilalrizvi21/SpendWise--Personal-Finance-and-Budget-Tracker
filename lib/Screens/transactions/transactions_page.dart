import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendwise_2/Core/utils/date_formatter.dart';
import '../../Core/constants/app_strings.dart';
import '../../Core/constants/app_colors.dart';
import '../../Core/widgets/loading_indicator.dart';
import '../../Core/utils/currency_formatter.dart';
import '../../Providers/transaction_provider.dart';
import '../../Models/transaction.dart';
import 'recurring/recurring_transactions_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({Key? key}) : super(key: key);

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = AppStrings.filterThisMonth;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
      default:
        transactions = provider.transactions;
    }

    if (_searchQuery.isNotEmpty) {
      transactions = transactions.where((t) {
        return t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ==
                true ||
            t.amount.toString().contains(_searchQuery);
      }).toList();
    }

    return transactions;
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'All Transactions'),
                Tab(text: '🔄 Recurring'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: All Transactions ──
          _buildAllTransactions(),

          // ── Tab 2: Recurring ──
          const RecurringTransactionsPage(),
        ],
      ),
    );
  }

  Widget _buildAllTransactions() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final filteredTransactions = _getFilteredTransactions(provider);

        return Column(
          children: [
            // Space for app bar + tab bar
            const SizedBox(height: 160),

            // Stats header card
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

            // Filter chips
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
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFilter = filter);
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
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: AppStrings.searchTransactions,
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.search, color: AppColors.primary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Transaction list
            Expanded(
              child: provider.isLoading
                  ? const Center(child: LoadingIndicator(size: 48))
                  : filteredTransactions.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: AppStrings.noTransactions,
                      description: 'Add your first transaction to get started',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
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
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    // Check if this was auto-generated by recurring (notes starts with "Auto:")
    final isRecurring = transaction.notes?.startsWith('Auto:') ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecurring
              ? AppColors.primary.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
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
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: transaction.isIncome
                    ? AppColors.incomeGradient
                    : AppColors.expenseGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                transaction.isIncome
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: Colors.white,
                size: 20,
              ),
            ),
            // Recurring badge
            if (isRecurring)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cardBackground,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.repeat, color: Colors.black, size: 9),
                ),
              ),
          ],
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
            if (isRecurring)
              Text(
                '🔄 Recurring',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
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
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
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
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
        ),
      ],
    );
  }
}
