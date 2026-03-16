import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendwise_2/Core/utils/date_formatter.dart';
import '../../Core/constants/app_strings.dart';
import '../../Core/constants/app_colors.dart';
//import '../../Core/widgets/input_widgets.dart';
import '../../Core/widgets/loading_indicator.dart';
import '../../Core/utils/currency_formatter.dart';
//import '../../Core/utils/data_formatter.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _getFilteredTransactions(TransactionProvider provider) {
    List<Transaction> transactions;

    // Apply date filter
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

    // Apply search filter
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
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final filteredTransactions = _getFilteredTransactions(provider);

          return Column(
            children: [
              const SizedBox(height: 100),

              // Modern Header Card with Stats
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

              const SizedBox(height: 20),

              // Filter Chips
              SizedBox(
                height: 50,
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

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
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
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchTransactions,
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search, color: AppColors.primary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // Transaction List
              Expanded(
                child: provider.isLoading
                    ? const Center(child: LoadingIndicator(size: 48))
                    : filteredTransactions.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: AppStrings.noTransactions,
                        description:
                            'Add your first transaction to get started',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 50,
                                height: 50,
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
                                ),
                              ),
                              title: Text(
                                transaction.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                DateFormatter.formatDate(transaction.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
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
                                      fontSize: 16,
                                      color: transaction.isIncome
                                          ? AppColors.income
                                          : AppColors.expense,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    transaction.paymentMethod,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // View transaction details or edit
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
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
