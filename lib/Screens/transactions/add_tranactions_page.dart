import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spendwise_2/Providers/transaction_provider.dart';
import '../../Core/constants/app_strings.dart';
import '../../Core/constants/app_colors.dart';
import '../../Core/widgets/input_widgets.dart';
import '../../Core/widgets/custom_button.dart';
import '../../Models/category.dart';
import '../../Models/transaction.dart' as model;
import '../../Services/database_service.dart';

class AddTransactionPage extends StatefulWidget {
  final String type; // 'income' or 'expense'

  const AddTransactionPage({Key? key, required this.type}) : super(key: key);

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedCategory;
  String? _selectedPaymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  // Custom categories loaded from DB
  List<Category> _customCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final custom = await DatabaseService.instance.getCustomCategories(
      type: widget.type,
    );
    if (mounted) setState(() => _customCategories = custom);
  }

  // Merge default + custom categories
  List<Map<String, dynamic>> get _categories {
    final defaults = widget.type == 'income'
        ? DefaultCategories.incomeCategories
        : DefaultCategories.expenseCategories;

    final all = [...defaults, ..._customCategories];

    return all
        .map((c) => {'name': c.name, 'icon': c.icon, 'color': c.color})
        .toList();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.selectCategory)));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final transaction = model.Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory!,
        date: _selectedDate,
        type: widget.type,
        paymentMethod: _selectedPaymentMethod!,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: DateTime.now(),
      );

      await context.read<TransactionProvider>().addTransaction(
        transaction,
        context: context,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.type} ${AppStrings.transactionAdded}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Show bottom sheet to create a custom category on the fly
  void _showAddCustomCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickAddCategorySheet(
        type: widget.type,
        onSaved: (Category newCat) async {
          await _loadCustomCategories();
          setState(() => _selectedCategory = newCat.name);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == 'income';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Add ${isIncome ? 'Income' : 'Expense'}',
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
          padding: const EdgeInsets.all(16),
          children: [
            AmountInputField(
              controller: _amountController,
              label: AppStrings.amount,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.enterAmount;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category selector with custom option
            CategorySelector(
              selectedCategory: _selectedCategory,
              categories: _categories,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),

            // ＋ Add Custom Category button
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showAddCustomCategorySheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Add Custom Category',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            DatePickerField(
              label: AppStrings.date,
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 16),
            CustomDropdown<String>(
              label: AppStrings.paymentMethod,
              value: _selectedPaymentMethod,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text(AppStrings.cash)),
                DropdownMenuItem(value: 'card', child: Text(AppStrings.card)),
                DropdownMenuItem(
                  value: 'wallet',
                  child: Text(AppStrings.digitalWallet),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _notesController,
              label: AppStrings.notes,
              hint: 'Optional notes...',
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: AppStrings.save,
              onPressed: _isSaving ? null : _saveTransaction,
              isLoading: _isSaving,
              color: isIncome ? AppColors.income : AppColors.expense,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Add Category Sheet (used inline from add transaction page) ──
class _QuickAddCategorySheet extends StatefulWidget {
  final String type;
  final Function(Category) onSaved;

  const _QuickAddCategorySheet({required this.type, required this.onSaved});

  @override
  State<_QuickAddCategorySheet> createState() => _QuickAddCategorySheetState();
}

class _QuickAddCategorySheetState extends State<_QuickAddCategorySheet> {
  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = AppColors.primary;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final category = Category(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        type: widget.type,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      await DatabaseService.instance.createCustomCategory(category);
      widget.onSaved(category);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_selectedIcon, color: _selectedColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'New ${widget.type == 'income' ? 'Income' : 'Expense'} Category',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name
            TextField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Category Name',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Icon picker
            const Text(
              'Icon',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: CategoryIcons.icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withOpacity(0.2)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? _selectedColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? _selectedColor
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Color picker
            const Text(
              'Color',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: CategoryColors.colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Create & Select',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
