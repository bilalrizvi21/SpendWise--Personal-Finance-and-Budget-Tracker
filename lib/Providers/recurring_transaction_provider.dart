import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../Models/recurring_transaction.dart';
import '../Models/transaction.dart';
import '../Services/database_service.dart';
import '../Services/notification_service.dart';
import 'transaction_provider.dart';
import 'budget_provider.dart';

class RecurringTransactionProvider extends ChangeNotifier {
  List<RecurringTransaction> _recurring = [];
  bool _isLoading = false;
  String? _error;
  int _processedCount = 0; // How many were auto-processed on last launch

  final DatabaseService _dbService = DatabaseService.instance;

  List<RecurringTransaction> get recurring => _recurring;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get processedCount => _processedCount;

  List<RecurringTransaction> get activeRecurring =>
      _recurring.where((r) => r.isActive).toList();

  List<RecurringTransaction> get upcomingThisMonth {
    final now = DateTime.now();
    return _recurring.where((r) {
      return r.isActive &&
          r.nextDueDate.month == now.month &&
          r.nextDueDate.year == now.year;
    }).toList()..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  // ========== LOAD ==========

  Future<void> loadRecurring() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _recurring = await _dbService.getAllRecurringTransactions();
      print('✅ Loaded ${_recurring.length} recurring transactions');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('❌ Error loading recurring: $e');
      notifyListeners();
    }
  }

  // ========== AUTO-PROCESS ON APP LAUNCH ==========

  /// Called on every app open. Checks for due recurring transactions,
  /// creates real transactions, updates budgets, and sends notifications.
  Future<void> processDueTransactions(BuildContext context) async {
    try {
      final due = await _dbService.getDueRecurringTransactions();
      if (due.isEmpty) {
        print('✅ No recurring transactions due');
        return;
      }

      print('📅 Processing ${due.length} due recurring transactions...');
      _processedCount = 0;

      final txProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final budgetProvider = Provider.of<BudgetProvider>(
        context,
        listen: false,
      );

      for (final recurring in due) {
        // 1. Create a real transaction
        final transaction = Transaction(
          id: '${recurring.id}_${DateTime.now().millisecondsSinceEpoch}',
          amount: recurring.amount,
          category: recurring.category,
          date: DateTime.now(),
          type: recurring.type,
          paymentMethod: recurring.paymentMethod,
          notes: recurring.notes ?? 'Auto: ${recurring.name}',
          createdAt: DateTime.now(),
        );

        await _dbService.createTransaction(transaction);
        txProvider.addTransactionToList(transaction);

        // 2. Sync budget if it's an expense
        if (recurring.isExpense) {
          await budgetProvider.syncWithTransactions();
        }

        // 3. Advance the next due date to next month
        final updated = recurring.copyWith(
          nextDueDate: recurring.nextMonthDueDate,
          updatedAt: DateTime.now(),
        );
        await _dbService.updateRecurringTransaction(updated);

        // 4. Update local list
        final index = _recurring.indexWhere((r) => r.id == recurring.id);
        if (index != -1) _recurring[index] = updated;

        // 5. Send notification
        await NotificationService.instance.showRecurringTransactionNotification(
          name: recurring.name,
          amount: recurring.amount,
          type: recurring.type,
          category: recurring.category,
        );

        _processedCount++;
        print('✅ Processed: ${recurring.name}');
      }

      notifyListeners();
      print('✅ Done processing $_processedCount recurring transactions');
    } catch (e) {
      print('❌ Error processing due recurring: $e');
    }
  }

  // ========== ADD ==========

  Future<void> addRecurring(RecurringTransaction recurring) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.createRecurringTransaction(recurring);
      _recurring.add(recurring);
      _recurring.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========== UPDATE ==========

  Future<void> updateRecurring(RecurringTransaction recurring) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.updateRecurringTransaction(recurring);
      final index = _recurring.indexWhere((r) => r.id == recurring.id);
      if (index != -1) _recurring[index] = recurring;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========== DELETE ==========

  Future<void> deleteRecurring(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.deleteRecurringTransaction(id);
      _recurring.removeWhere((r) => r.id == id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearRecurring() {
    _recurring = [];
    notifyListeners();
  }
}
