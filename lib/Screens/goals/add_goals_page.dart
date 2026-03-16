import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/constants/app_colors.dart';
import '../../Models/goal.dart';
import '../../Providers/goal_provider.dart';

class AddGoalPage extends StatefulWidget {
  final Goal? existingGoal; // null = add mode, non-null = edit mode

  const AddGoalPage({Key? key, this.existingGoal}) : super(key: key);

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDeadline;
  bool _isSaving = false;

  bool get _isEditing => widget.existingGoal != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.existingGoal!.name;
      _targetController.text = widget.existingGoal!.targetAmount
          .toStringAsFixed(0);
      _descriptionController.text = widget.existingGoal!.description ?? '';
      _selectedDeadline = widget.existingGoal!.deadline;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<GoalProvider>(context, listen: false);

      if (_isEditing) {
        final updated = widget.existingGoal!.copyWith(
          name: _nameController.text.trim(),
          targetAmount: double.parse(_targetController.text),
          deadline: _selectedDeadline,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await provider.updateGoal(updated);
        _showSnackbar('Goal updated!');
      } else {
        final newGoal = Goal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          targetAmount: double.parse(_targetController.text),
          currentAmount: 0.0,
          deadline: _selectedDeadline,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          createdAt: DateTime.now(),
        );
        await provider.addGoal(newGoal);
        _showSnackbar('Goal created!');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Goal' : 'New Goal',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Goal name
            _buildLabel('Goal Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('e.g. New Laptop, Vacation Trip'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter a goal name'
                  : null,
            ),

            const SizedBox(height: 20),

            // Target amount
            _buildLabel('Target Amount (PKR)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: _inputDecoration('0').copyWith(
                prefixText: 'PKR  ',
                prefixStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty)
                  return 'Please enter a target amount';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0)
                  return 'Enter a valid amount';
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Deadline (optional)
            _buildLabel('Deadline (Optional)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDeadline == null
                            ? 'No deadline — save at your own pace'
                            : _selectedDeadline!.toString().split(' ')[0],
                        style: TextStyle(
                          color: _selectedDeadline == null
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (_selectedDeadline != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedDeadline = null),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textLight,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Description (optional)
            _buildLabel('Description (Optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 3,
              decoration: _inputDecoration('Add a note about this goal...'),
            ),

            const SizedBox(height: 36),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
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
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Goal' : 'Create Goal',
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
