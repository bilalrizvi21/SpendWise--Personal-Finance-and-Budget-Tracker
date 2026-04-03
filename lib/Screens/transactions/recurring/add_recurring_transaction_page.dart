import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Core/constants/app_colors.dart';
import '../../../Models/recurring_transaction.dart';
import '../../../Models/category.dart';
import '../../../Providers/recurring_transaction_provider.dart';
import '../../../Services/database_service.dart';

class AddRecurringTransactionPage extends StatefulWidget {
  final RecurringTransaction? existing; // null = add, non-null = edit

  const AddRecurringTransactionPage({Key? key, this.existing})
    : super(key: key);

  @override
  State<AddRecurringTransactionPage> createState() =>
      _AddRecurringTransactionPageState();
}

class _AddRecurringTransactionPageState
    extends State<AddRecurringTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'expense';
  String? _selectedCategory;
  String _paymentMethod = 'cash';
  int _dayOfMonth = 1;
  bool _isSaving = false;

  List<Category> _customCategories = [];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.existing!;
      _nameController.text = e.name;
      _amountController.text = e.amount.toStringAsFixed(0);
      _notesController.text = e.notes ?? '';
      _type = e.type;
      _selectedCategory = e.category;
      _paymentMethod = e.paymentMethod;
      _dayOfMonth = e.dayOfMonth;
    }
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final cats = await DatabaseService.instance.getCustomCategories(
      type: _type,
    );
    if (mounted) setState(() => _customCategories = cats);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _categories {
    final defaults = _type == 'income'
        ? DefaultCategories.incomeCategories
        : DefaultCategories.expenseCategories;
    return [
      ...defaults,
      ..._customCategories,
    ].map((c) => {'name': c.name, 'icon': c.icon, 'color': c.color}).toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnackbar('Please select a category', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<RecurringTransactionProvider>(
        context,
        listen: false,
      );

      // Calculate first next due date
      final now = DateTime.now();
      DateTime nextDue = DateTime(now.year, now.month, _dayOfMonth);
      // If the day has already passed this month, set to next month
      if (nextDue.isBefore(now) || nextDue.isAtSameMomentAs(now)) {
        nextDue = DateTime(now.year, now.month + 1, _dayOfMonth);
      }

      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          name: _nameController.text.trim(),
          amount: double.parse(_amountController.text),
          category: _selectedCategory,
          type: _type,
          paymentMethod: _paymentMethod,
          dayOfMonth: _dayOfMonth,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          updatedAt: DateTime.now(),
          // Keep existing nextDueDate if day hasn't changed
          nextDueDate: _dayOfMonth == widget.existing!.dayOfMonth
              ? widget.existing!.nextDueDate
              : nextDue,
        );
        await provider.updateRecurring(updated);
        _showSnackbar('Recurring transaction updated!');
      } else {
        final recurring = RecurringTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          amount: double.parse(_amountController.text),
          category: _selectedCategory!,
          type: _type,
          paymentMethod: _paymentMethod,
          dayOfMonth: _dayOfMonth,
          nextDueDate: nextDue,
          createdAt: DateTime.now(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        await provider.addRecurring(recurring);
        _showSnackbar('Recurring transaction added!');
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackbar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Recurring' : 'Add Recurring',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Type toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: ['expense', 'income'].map((t) {
                  final isSelected = _type == t;
                  final color = t == 'expense'
                      ? AppColors.expense
                      : AppColors.income;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        setState(() {
                          _type = t;
                          _selectedCategory = null;
                        });
                        await _loadCustomCategories();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            t == 'expense' ? 'Expense' : 'Income',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Name
            _buildLabel('Name (e.g. Netflix, Salary)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDeco('e.g. Netflix Subscription'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a name' : null,
            ),

            const SizedBox(height: 16),

            // Amount
            _buildLabel('Amount (PKR)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: _inputDeco('0').copyWith(
                prefixText: 'PKR  ',
                prefixStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                if (double.tryParse(v) == null || double.parse(v) <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Day of month
            _buildLabel('Day of Month'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _dayOfMonth,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        items: List.generate(28, (i) => i + 1)
                            .map(
                              (day) => DropdownMenuItem(
                                value: day,
                                child: Text(
                                  day == 1
                                      ? '1st of every month'
                                      : day == 2
                                      ? '2nd of every month'
                                      : day == 3
                                      ? '3rd of every month'
                                      : '${day}th of every month',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _dayOfMonth = v ?? 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Category
            _buildLabel('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                final color = cat['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['name']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          color: isSelected ? color : AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            color: isSelected ? color : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Payment method
            _buildLabel('Payment Method'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _paymentMethod,
                  dropdownColor: AppColors.cardBackground,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(
                      value: 'wallet',
                      child: Text('Digital Wallet'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _paymentMethod = v ?? 'cash'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            _buildLabel('Notes (Optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 2,
              decoration: _inputDeco('Optional notes...'),
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == 'expense'
                      ? AppColors.expense
                      : AppColors.income,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? 'Update Recurring'
                            : 'Add Recurring Transaction',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.5)),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
