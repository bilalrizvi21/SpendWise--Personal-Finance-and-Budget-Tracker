import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Core/constants/app_colors.dart';
import '../../Providers/transaction_provider.dart';
import '../../Providers/budget_provider.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // Conversation history — last 3 exchanges for context awareness
  final List<_Exchange> _history = [];

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hi! I'm SpendWise Assistant 👋\n\n"
          'I can help you with:\n'
          "• Your spending data ('How much did I spend on food?')\n"
          "• Budget tracking ('Am I over budget on food?')\n"
          '• Budgeting & saving tips\n'
          "• Month comparisons ('Compare this month vs last month')\n\n"
          'What would you like to know?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  final List<String> _suggestions = [
    'How much did I spend this month?',
    'What is my highest expense category?',
    'Am I over budget on anything?',
    'Compare this month vs last month',
    'Tips to save money',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    final query = text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: query, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final response = _getResponse(query, context);

      // Keep last 3 exchanges for context
      _history.add(_Exchange(query, response));
      if (_history.length > 3) _history.removeAt(0);

      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        );
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ══════════════════════════════════════════
  // Data access helpers
  // ══════════════════════════════════════════

  List<_TxSummary> _getMonthData(BuildContext ctx, int monthOffset) {
    final provider = ctx.read<TransactionProvider>();
    final now = DateTime.now();
    int year = now.year;
    int month = now.month - monthOffset;
    while (month <= 0) {
      month += 12;
      year--;
    }
    final txns = provider.getTransactionsByDateRange(
      DateTime(year, month, 1),
      DateTime(year, month + 1, 0, 23, 59, 59),
    );
    return txns.map((t) => _TxSummary(t.category, t.amount, t.type)).toList();
  }

  List<_TxSummary> _thisMonth(BuildContext ctx) => _getMonthData(ctx, 0);
  List<_TxSummary> _lastMonth(BuildContext ctx) => _getMonthData(ctx, 1);

  // Get all real category names from user's transaction history
  Set<String> _userCategories(BuildContext ctx) {
    final provider = ctx.read<TransactionProvider>();
    return provider.transactions.map((t) => t.category).toSet();
  }

  // Fuzzy match: find a real category from user's data that the query refers to
  String? _detectCategory(String q, BuildContext ctx) {
    final categories = _userCategories(ctx);

    // Direct substring match against real categories
    for (final cat in categories) {
      if (q.contains(cat.toLowerCase())) return cat;
    }

    // Alias map — common synonyms → normalized names
    final aliases = {
      'food': [
        'food',
        'groceries',
        'eating',
        'restaurant',
        'dining',
        'meal',
        'lunch',
        'dinner',
        'breakfast',
        'khaana',
        'khana',
      ],
      'transport': [
        'transport',
        'travel',
        'fuel',
        'petrol',
        'car',
        'bus',
        'uber',
        'careem',
        'commute',
        'ride',
      ],
      'shopping': [
        'shopping',
        'clothes',
        'clothing',
        'fashion',
        'mall',
        'amazon',
        'daraz',
      ],
      'entertainment': [
        'entertainment',
        'movies',
        'cinema',
        'games',
        'fun',
        'netflix',
        'youtube',
        'streaming',
      ],
      'bills': [
        'bills',
        'utilities',
        'electricity',
        'gas',
        'water',
        'internet',
        'phone',
        'bill',
      ],
      'health': [
        'health',
        'medical',
        'doctor',
        'medicine',
        'pharmacy',
        'hospital',
        'clinic',
      ],
      'education': [
        'education',
        'tuition',
        'school',
        'university',
        'books',
        'course',
        'fees',
      ],
      'salary': ['salary', 'income', 'pay', 'wages', 'earning', 'tنخواہ'],
    };

    for (final entry in aliases.entries) {
      if (entry.value.any((alias) => q.contains(alias))) {
        // Find the closest real category
        for (final cat in categories) {
          if (cat.toLowerCase().contains(entry.key) ||
              entry.key.contains(cat.toLowerCase())) {
            return cat;
          }
        }
        // Return the normalized alias key as fallback
        return entry.key[0].toUpperCase() + entry.key.substring(1);
      }
    }
    return null;
  }

  // Detect month offset from query (0 = this month, 1 = last month)
  int _detectMonthOffset(String q) {
    if (_matches(q, [
      'last month',
      'previous month',
      'pichle mahine',
      'past month',
    ]))
      return 1;
    if (_matches(q, ['2 months ago', 'two months ago', 'month before last']))
      return 2;
    return 0; // default: this month
  }

  // Get the last topic discussed (for follow-up resolution)
  String? _lastCategory() {
    for (final ex in _history.reversed) {
      final match = RegExp(
        r'PKR.*?on (\w+)|(\w+) spending|(\w+) expenses',
      ).firstMatch(ex.botReply);
      if (match != null) {
        return match.group(1) ?? match.group(2) ?? match.group(3);
      }
    }
    return null;
  }

  // ══════════════════════════════════════════
  // Spending data methods
  // ══════════════════════════════════════════

  String _totalSpending(BuildContext ctx, int offset) {
    final data = offset == 0 ? _thisMonth(ctx) : _lastMonth(ctx);
    final label = offset == 0 ? 'This month' : 'Last month';
    final expenses = data.where((t) => t.type == 'expense').toList();
    final total = expenses.fold(0.0, (s, t) => s + t.amount);
    if (total == 0)
      return '$label: no expenses recorded yet. Start adding transactions! 💡';
    return "💸 ${label}'s total spending:\n\n"
        'PKR ${total.toStringAsFixed(0)}\n\n'
        'across ${expenses.length} expense transactions.\n\n'
        "Want to know which category cost the most? Just say 'yes'! 📊";
  }

  String _totalIncome(BuildContext ctx, int offset) {
    final data = offset == 0 ? _thisMonth(ctx) : _lastMonth(ctx);
    final label = offset == 0 ? 'This month' : 'Last month';
    final incomes = data.where((t) => t.type == 'income').toList();
    final total = incomes.fold(0.0, (s, t) => s + t.amount);
    if (total == 0)
      return '$label: no income recorded yet. Add your salary in the Transactions tab! 💰';
    return "💰 ${label}'s total income:\n\n"
        'PKR ${total.toStringAsFixed(0)}\n\n'
        'across ${incomes.length} income transaction${incomes.length == 1 ? '' : 's'}.';
  }

  String _topExpenseCategory(BuildContext ctx, int offset) {
    final data = offset == 0 ? _thisMonth(ctx) : _lastMonth(ctx);
    final label = offset == 0 ? 'this month' : 'last month';
    final expenses = data.where((t) => t.type == 'expense').toList();
    if (expenses.isEmpty) return 'No expenses recorded $label yet! 🎉';

    final Map<String, double> totals = {};
    for (final t in expenses) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();
    final ranks = ['🥇', '🥈', '🥉'];

    final buf = StringBuffer('📊 Top expense categories $label:\n\n');
    for (int i = 0; i < top3.length; i++) {
      buf.writeln(
        '${ranks[i]} ${top3[i].key}: PKR ${top3[i].value.toStringAsFixed(0)}',
      );
    }
    buf.writeln('\n${top3[0].key} is your biggest expense $label.');
    buf.write(_categoryTip(top3[0].key));
    return buf.toString();
  }

  String _topIncomeCategory(BuildContext ctx, int offset) {
    final data = offset == 0 ? _thisMonth(ctx) : _lastMonth(ctx);
    final label = offset == 0 ? 'this month' : 'last month';
    final incomes = data.where((t) => t.type == 'income').toList();
    if (incomes.isEmpty)
      return 'No income recorded $label yet. Add your income! 💰';

    final Map<String, double> totals = {};
    for (final t in incomes) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buf = StringBuffer('💰 Income sources $label:\n\n');
    int i = 1;
    for (final e in sorted.take(3)) {
      buf.writeln('$i. ${e.key}: PKR ${e.value.toStringAsFixed(0)}');
      i++;
    }
    return buf.toString();
  }

  String _categorySpending(BuildContext ctx, String category, int offset) {
    final data = offset == 0 ? _thisMonth(ctx) : _lastMonth(ctx);
    final label = offset == 0 ? 'this month' : 'last month';
    final catTxns = data
        .where(
          (t) =>
              t.type == 'expense' &&
              t.category.toLowerCase() == category.toLowerCase(),
        )
        .toList();
    final total = catTxns.fold(0.0, (s, t) => s + t.amount);
    if (total == 0) {
      return 'No $category expenses recorded $label. 👍\n\n'
          "Either you haven't spent on $category yet, "
          "or it's recorded under a different category name.\n\n"
          'Your categories: ${_userCategories(ctx).join(', ')}';
    }
    final suggestion = _categoryTip(category);
    return '🧾 $category spending $label:\n\n'
        'PKR ${total.toStringAsFixed(0)}\n\n'
        'across ${catTxns.length} transaction${catTxns.length == 1 ? '' : 's'}.\n\n'
        '$suggestion';
  }

  String _netBalance(BuildContext ctx, int offset) {
    final data = offset == 0 ? _thisMonth(ctx) : _lastMonth(ctx);
    final label = offset == 0 ? 'this month' : 'last month';
    final income = data
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final expense = data
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    if (income == 0 && expense == 0)
      return 'No transactions recorded $label yet. Start tracking! 📊';
    final net = income - expense;
    final tip = net >= 0
        ? "Great job! You're saving money $label. 🎉"
        : 'Your expenses exceeded income $label. Consider reducing discretionary spending. 💡';
    return '${net >= 0 ? '✅' : '⚠️'} Net balance $label:\n\n'
        'Income:   PKR ${income.toStringAsFixed(0)}\n'
        'Expenses: PKR ${expense.toStringAsFixed(0)}\n'
        '─────────────────\n'
        'Net: PKR ${net.abs().toStringAsFixed(0)} ${net >= 0 ? 'saved' : 'deficit'}\n\n'
        '$tip';
  }

  // ── 5. Month comparison
  String _compareMonths(BuildContext ctx) {
    final thisData = _thisMonth(ctx);
    final lastData = _lastMonth(ctx);

    final thisExpense = thisData
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final lastExpense = lastData
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final thisIncome = thisData
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final lastIncome = lastData
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);

    if (lastExpense == 0 && lastIncome == 0) {
      return 'No data from last month to compare. '
          "Keep tracking this month and you'll see a comparison next month! 📊";
    }

    final expenseDiff = thisExpense - lastExpense;
    final incomeDiff = thisIncome - lastIncome;
    final expenseChange = lastExpense > 0
        ? (expenseDiff / lastExpense * 100)
        : 0.0;
    final incomeChange = lastIncome > 0 ? (incomeDiff / lastIncome * 100) : 0.0;

    final buf = StringBuffer('📊 This Month vs Last Month:\n\n');
    buf.writeln('💸 Expenses:');
    buf.writeln('  This month: PKR ${thisExpense.toStringAsFixed(0)}');
    buf.writeln('  Last month: PKR ${lastExpense.toStringAsFixed(0)}');
    if (expenseDiff != 0) {
      final arrow = expenseDiff > 0 ? '📈 +' : '📉 ';
      buf.writeln(
        '  Change: $arrow${expenseDiff.abs().toStringAsFixed(0)} '
        '(${expenseChange.toStringAsFixed(1)}%)',
      );
    }
    buf.writeln('');
    buf.writeln('💰 Income:');
    buf.writeln('  This month: PKR ${thisIncome.toStringAsFixed(0)}');
    buf.writeln('  Last month: PKR ${lastIncome.toStringAsFixed(0)}');
    if (incomeDiff != 0) {
      final arrow = incomeDiff > 0 ? '📈 +' : '📉 ';
      buf.writeln(
        '  Change: $arrow${incomeDiff.abs().toStringAsFixed(0)} '
        '(${incomeChange.toStringAsFixed(1)}%)',
      );
    }
    buf.writeln('');
    if (expenseDiff > 0) {
      buf.write(
        '⚠️ Spending increased this month. '
        'Check the AI Insights tab for anomaly analysis.',
      );
    } else if (expenseDiff < 0) {
      buf.write('✅ Great! You spent less this month vs last month.');
    } else {
      buf.write('Your spending is consistent with last month.');
    }
    return buf.toString();
  }

  // ── 6. Budget comparison (cross-references BudgetProvider)
  String _budgetStatus(BuildContext ctx, String? specificCategory) {
    final budgetProvider = ctx.read<BudgetProvider>();
    final budgets = budgetProvider.currentMonthBudgets;

    if (budgets.isEmpty) {
      return "You haven't set any budgets yet.\n\n"
          'Go to the Budget Planner tab to set monthly spending limits. '
          "SpendWise will alert you when you're close to exceeding them! 🎯";
    }

    if (specificCategory != null) {
      // Check budget for a specific category
      final budget = budgets.firstWhere(
        (b) => b.category.toLowerCase() == specificCategory.toLowerCase(),
        orElse: () => budgets.first,
      );
      final found = budgets.any(
        (b) => b.category.toLowerCase() == specificCategory.toLowerCase(),
      );
      if (!found) {
        return 'No budget set for $specificCategory.\n\n'
            'Add one in the Budget Planner tab! '
            'You can set a monthly limit and get alerts at 80%. 🎯';
      }
      final pct = budget.percentageUsed;
      final status = pct >= 100
          ? '🚨 EXCEEDED'
          : pct >= 80
          ? '⚠️ NEAR LIMIT'
          : '✅ ON TRACK';
      return '$status — ${budget.category} budget:\n\n'
          'Spent:  PKR ${budget.used.toStringAsFixed(0)}\n'
          'Limit:  PKR ${budget.limit.toStringAsFixed(0)}\n'
          'Used:   ${pct.toInt()}%\n\n'
          '${pct >= 100
              ? "You've exceeded this budget! Reduce ${budget.category} spending."
              : pct >= 80
              ? "You're close to the limit. Be careful!"
              : "You're within budget. Keep it up!"}';
    }

    // Show all budgets overview
    final exceeded = budgets.where((b) => b.percentageUsed >= 100).toList();
    final warning = budgets
        .where((b) => b.percentageUsed >= 80 && b.percentageUsed < 100)
        .toList();
    final ok = budgets.where((b) => b.percentageUsed < 80).toList();

    final buf = StringBuffer('📊 Budget Status — This Month:\n\n');
    if (exceeded.isNotEmpty) {
      buf.writeln('🚨 Exceeded:');
      for (final b in exceeded) {
        buf.writeln(
          '  • ${b.category}: PKR ${b.used.toStringAsFixed(0)} / ${b.limit.toStringAsFixed(0)} (${b.percentageUsed.toInt()}%)',
        );
      }
      buf.writeln('');
    }
    if (warning.isNotEmpty) {
      buf.writeln('⚠️ Near Limit:');
      for (final b in warning) {
        buf.writeln('  • ${b.category}: ${b.percentageUsed.toInt()}% used');
      }
      buf.writeln('');
    }
    if (ok.isNotEmpty) {
      buf.writeln('✅ On Track:');
      for (final b in ok) {
        buf.writeln('  • ${b.category}: ${b.percentageUsed.toInt()}% used');
      }
    }
    if (exceeded.isEmpty && warning.isEmpty) {
      buf.write('\nAll budgets are within limits. Excellent! 🌟');
    }
    return buf.toString();
  }

  String _monthSummary(BuildContext ctx, int offset) {
    final data = offset == 0 ? _thisMonth(ctx) : _lastMonth(ctx);
    final label = offset == 0 ? 'This Month' : 'Last Month';
    if (data.isEmpty)
      return 'No transactions for $label yet. Start tracking! 📊';

    final income = data
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final expense = data
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final net = income - expense;

    final Map<String, double> catTotals = {};
    for (final t in data.where((t) => t.type == 'expense')) {
      catTotals[t.category] = (catTotals[t.category] ?? 0) + t.amount;
    }
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buf = StringBuffer('📊 $label Financial Summary:\n\n');
    buf.writeln('💰 Income:   PKR ${income.toStringAsFixed(0)}');
    buf.writeln('💸 Expenses: PKR ${expense.toStringAsFixed(0)}');
    buf.writeln(
      '📈 Net: PKR ${net.abs().toStringAsFixed(0)} ${net >= 0 ? '(saved)' : '(deficit)'}',
    );
    if (sorted.isNotEmpty) {
      buf.writeln('\n🏆 Top Expense Categories:');
      for (final e in sorted.take(3)) {
        buf.writeln('  • ${e.key}: PKR ${e.value.toStringAsFixed(0)}');
      }
    }
    buf.write(
      net >= 0
          ? "\n✅ You're on track!"
          : '\n⚠️ Consider reducing expenses to stay on budget.',
    );
    return buf.toString();
  }

  // ── Resolve affirmative replies using last bot message context ──
  // Looks at the last bot reply to figure out what "yes" refers to
  String _resolveAffirmative(BuildContext ctx) {
    if (_history.isEmpty) {
      return 'Sure! What would you like to know? You can ask things like:\n\n'
          '• "How much did I spend this month?"\n'
          '• "What is my highest expense category?"\n'
          '• "Am I over budget on anything?"';
    }

    final lastReply = _history.last.botReply.toLowerCase();

    // Bot asked about highest expense category
    if (lastReply.contains('which category cost the most') ||
        lastReply.contains('want to know which category') ||
        lastReply.contains('category you spent the most')) {
      return _topExpenseCategory(ctx, 0);
    }

    // Bot asked about budget
    if (lastReply.contains('budget planner') ||
        lastReply.contains('set a budget') ||
        lastReply.contains('budget limit')) {
      return _budgetStatus(ctx, null);
    }

    // Bot asked about monthly summary
    if (lastReply.contains('monthly summary') ||
        lastReply.contains('full report') ||
        lastReply.contains('summary')) {
      return _monthSummary(ctx, 0);
    }

    // Bot asked about comparison
    if (lastReply.contains('last month') || lastReply.contains('compare')) {
      return _compareMonths(ctx);
    }

    // Bot was talking about a specific category — show that category's tips
    final detectedCat = _detectCategory(lastReply, ctx);
    if (detectedCat != null) {
      return '💡 Tips to reduce $detectedCat expenses:\n\n'
          '${_categoryTip(detectedCat)}\n\n'
          'You can also set a budget limit for $detectedCat '
          'in the Budget Planner tab to get automatic alerts at 80%! 🎯';
    }

    // Generic affirmative — show full summary
    return _monthSummary(ctx, 0);
  }

  // ── Category-specific saving tip
  String _categoryTip(String category) {
    final c = category.toLowerCase();
    if (c.contains('food') || c.contains('groceries'))
      return 'Tip: Meal planning can reduce food costs by 30%! 🍱';
    if (c.contains('transport') || c.contains('travel'))
      return 'Tip: Carpooling can halve your transport costs! 🚗';
    if (c.contains('entertainment'))
      return 'Tip: Review your subscriptions — cancel ones you rarely use! 📺';
    if (c.contains('shopping') || c.contains('clothes'))
      return 'Tip: Wait 48 hours before non-essential purchases! 🛍️';
    if (c.contains('health') || c.contains('medical'))
      return 'Tip: Preventive care is cheaper than treatment! 💊';
    return 'Tip: Set a budget limit for $category in the Budget Planner! 🎯';
  }

  // ══════════════════════════════════════════
  // Main response engine
  // ══════════════════════════════════════════

  String _getResponse(String query, BuildContext ctx) {
    final q = query.toLowerCase().trim();
    final offset = _detectMonthOffset(q);

    // ── Affirmative/negative replies — resolve using last bot message context ──
    if (_matches(q, [
      'yes',
      'yeah',
      'yep',
      'sure',
      'ok',
      'okay',
      'please',
      'yes please',
      'yes pls',
      'yep please',
      'go ahead',
      'show me',
      'tell me',
      'of course',
      'definitely',
    ])) {
      return _resolveAffirmative(ctx);
    }

    if (_matches(q, ['no', 'nope', 'nah', 'not now', 'no thanks', 'skip'])) {
      return 'No problem! 😊 Is there anything else I can help you with?';
    }

    // ── Context-aware follow-ups ──
    // "is that too much?" / "what about last month?" etc.
    if (_matches(q, [
      'is that too much',
      'is that high',
      'is that normal',
      'should i reduce',
      'too expensive',
      'that a lot',
    ])) {
      final lastCat = _lastCategory();
      if (lastCat != null) {
        return "Based on your $lastCat spending, here's some context:\n\n"
            '${_categoryTip(lastCat)}\n\n'
            'You can also set a monthly budget limit for $lastCat in the '
            'Budget Planner tab to get automatic alerts! 🎯';
      }
      return 'It depends on your income and financial goals. '
          'The 50/30/20 rule suggests keeping total expenses under 80% of income. '
          'Would you like your monthly summary to check?';
    }

    if (_matches(q, [
      'what about last month',
      'and last month',
      'vs last month',
      'last month though',
      'last month also',
    ])) {
      final lastCat = _lastCategory();
      if (lastCat != null) return _categorySpending(ctx, lastCat, 1);
      return _totalSpending(ctx, 1);
    }

    if (_matches(q, [
      'what about income',
      'and income',
      'how about income',
      'what about earnings',
      'my earnings',
    ])) {
      return _totalIncome(ctx, offset);
    }

    // ── Budget queries (cross-references BudgetProvider) ──
    if (_matches(q, [
      'over budget',
      'budget status',
      'budget check',
      'am i over',
      'within budget',
      'budget exceeded',
      'near limit',
      'budget left',
      'remaining budget',
      'how much budget',
    ])) {
      final detectedCat = _detectCategory(q, ctx);
      return _budgetStatus(ctx, detectedCat);
    }

    // ── Comparison — checked FIRST before spending to avoid false matches ──
    if (_matches(q, [
      'compare',
      'comparison',
      'vs last month',
      'this month vs',
      'vs last',
      'difference between',
      'more or less than last',
      'increased',
      'decreased',
      'change since last',
    ])) {
      return _compareMonths(ctx);
    }

    // ── Total spending ──
    if (_matches(q, [
      'how much did i spend',
      'total expense',
      'total spending',
      'spent this month',
      'my expenses',
      'total spent',
      'spent last month',
      'how much spent',
    ])) {
      return _totalSpending(ctx, offset);
    }

    // ── Total income ──
    if (_matches(q, [
      'how much did i earn',
      'total income',
      'my income',
      'earned this month',
      'income this month',
      'salary this month',
      'earned last month',
    ])) {
      return _totalIncome(ctx, offset);
    }

    // ── Top expense category ──
    if (_matches(q, [
      'highest expense',
      'most spent',
      'biggest expense',
      'top category',
      'where did i spend most',
      'most spending',
      'most expensive category',
    ])) {
      return _topExpenseCategory(ctx, offset);
    }

    // ── Top income category ──
    if (_matches(q, [
      'highest income',
      'most income',
      'biggest income',
      'top income',
      'income category',
      'income source',
    ])) {
      return _topIncomeCategory(ctx, offset);
    }

    // ── Net balance ──
    if (_matches(q, [
      'my balance',
      'net balance',
      'how much saved',
      'savings this month',
      'net savings',
      'profit this month',
      'did i save',
      'how much left',
    ])) {
      return _netBalance(ctx, offset);
    }

    // ── Summary ──
    if (_matches(q, [
      'summary',
      'monthly summary',
      'overview',
      'my report',
      'how am i doing this month',
      'financial summary',
      'full report',
    ])) {
      return _monthSummary(ctx, offset);
    }

    // ── Dynamic category detection (fuzzy matching) ──
    // This catches "how much on groceries?", "khaana ka kharcha", etc.
    final detectedCat = _detectCategory(q, ctx);
    if (detectedCat != null &&
        _matches(q, [
          'spend',
          'spent',
          'cost',
          'expense',
          'kharcha',
          'how much',
          'kitna',
          'used on',
          'paid for',
        ])) {
      return _categorySpending(ctx, detectedCat, offset);
    }

    // ── Finance advice topics ──

    if (_matches(q, [
      'budget',
      'budgeting',
      'plan my money',
      'spending plan',
    ])) {
      return "📊 Here's how to create an effective budget:\n\n"
          '1. Track all income sources first\n'
          '2. List all monthly expenses\n'
          '3. Categorize them (needs vs wants)\n'
          '4. Set limits per category\n'
          '5. Review weekly and adjust\n\n'
          "Use the Budget Planner tab to set limits — you'll get alerts at 80%! 🎯";
    }

    if (_matches(q, [
      'save money',
      'saving tips',
      'how to save',
      'save more',
      'bachat',
    ])) {
      return '💰 Top strategies to save more money:\n\n'
          '• Pay yourself first — save before spending\n'
          '• Use the 50/30/20 rule\n'
          '• Cancel unused subscriptions\n'
          '• Cook at home more often\n'
          '• Avoid impulse purchases (wait 48 hours)\n'
          '• Set specific savings goals with deadlines\n\n'
          "Use SpendWise's Goals tab to track your savings targets! 🚀";
    }

    if (_matches(q, ['50/30/20', '50 30 20', 'rule', 'income split'])) {
      return '📐 The 50/30/20 Rule:\n\n'
          '• 50% → Needs (rent, food, bills, transport)\n'
          '• 30% → Wants (dining out, entertainment, shopping)\n'
          '• 20% → Savings & debt repayment\n\n'
          'Example — PKR 80,000/month:\n'
          '• Needs: PKR 40,000\n'
          '• Wants: PKR 24,000\n'
          '• Savings: PKR 16,000\n\n'
          'Adjust the split based on your situation! 💡';
    }

    if (_matches(q, [
      'emergency fund',
      'emergency savings',
      'rainy day',
      'backup money',
    ])) {
      return '🛡️ Building an Emergency Fund:\n\n'
          'Target: 3–6 months of living expenses\n\n'
          'Steps:\n'
          '1. Calculate monthly expenses\n'
          '2. Set goal = 3× that amount (minimum)\n'
          '3. Save a fixed amount every month\n'
          '4. Keep it in a separate account\n'
          '5. Only use for genuine emergencies\n\n'
          'Create an emergency fund goal in the Goals tab! 💪';
    }

    if (_matches(q, [
      'debt',
      'loan',
      'credit',
      'owe',
      'borrowed',
      'pay off',
      'qarz',
    ])) {
      return '💳 Strategies to manage debt:\n\n'
          'Avalanche Method (saves more money):\n'
          '→ Pay minimums on all, extra on highest-interest debt\n\n'
          'Snowball Method (more motivating):\n'
          '→ Pay minimums on all, extra on smallest debt first\n\n'
          'General tips:\n'
          '• Never miss minimum payments\n'
          '• Avoid taking new debt while paying off\n'
          '• Track debt payments as expenses in SpendWise! 📉';
    }

    if (_matches(q, [
      'inflation',
      'prices rising',
      'cost of living',
      'mehngai',
    ])) {
      return '📈 Managing finances during inflation:\n\n'
          '• Review and adjust your budget monthly\n'
          '• Focus on reducing discretionary spending\n'
          '• Buy in bulk to lock in current prices\n'
          '• Avoid lifestyle inflation\n'
          '• Invest savings to beat inflation\n\n'
          "SpendWise's AI Insights shows Pakistan's current inflation rate "
          'and factors it into your spending predictions! 🇵🇰';
    }

    if (_matches(q, [
      'invest',
      'investment',
      'stocks',
      'mutual fund',
      'returns',
      'grow money',
    ])) {
      return '📊 Basic investment guidance for Pakistan:\n\n'
          '• Start with an emergency fund first\n'
          '• Consider NSS (National Savings Schemes)\n'
          '• Mutual funds via Meezan, UBL, NBP\n'
          '• Pakistan Stock Exchange (PSX) for experienced investors\n'
          '• Real estate for long-term wealth\n\n'
          '⚠️ This is general info, not financial advice. '
          'Consult a qualified advisor for personalized guidance.';
    }

    if (_matches(q, [
      'spendwise',
      'app',
      'feature',
      'how to use',
      'what can you do',
    ])) {
      return '📱 SpendWise Features:\n\n'
          '🏠 Dashboard — Overview + quick add\n'
          '💳 Transactions — All txns with filters\n'
          '📊 Budget — Category budgets + alerts\n'
          '🧠 AI Insights — Anomaly detection + inflation\n'
          '🎯 Goals — Savings goals with deadlines\n'
          '🔄 Recurring — Auto monthly transactions\n'
          '⚙️ Settings — Theme, currency, security\n\n'
          "Ask me about your data: 'How much did I spend this month?' 💬";
    }

    if (_matches(q, [
      'recurring',
      'subscription',
      'monthly bill',
      'automatic',
    ])) {
      return '🔄 Recurring Transactions:\n\n'
          'Set up salary, rent, Netflix, electricity to auto-add monthly.\n\n'
          'Go to Transactions → Recurring tab → Add\n\n'
          'SpendWise processes them automatically on the set day '
          'and sends you a notification! ✅';
    }

    if (_matches(q, ['goal', 'target', 'saving for', 'saving up'])) {
      return '🎯 Savings Goals:\n\n'
          '1. Goals tab → Add goal\n'
          '2. Set name, target amount, deadline\n'
          '3. SpendWise calculates monthly saving needed\n'
          '4. Add money as you save\n\n'
          'Get reminders when deadlines approach and '
          'a celebration when you hit 100%! 🎉';
    }

    if (_matches(q, [
      'health score',
      'financial health',
      'score',
      'how am i doing',
    ])) {
      return '💯 Financial Health Score (0–100):\n\n'
          '• 40% — Savings Rate\n'
          '• 40% — Spending Control\n'
          '• 20% — Tracking Consistency\n\n'
          '80–100 → Excellent 🌟\n'
          '60–79  → Good 👍\n'
          '40–59  → Fair ⚠️\n'
          '0–39   → Needs attention ❗\n\n'
          'Check your score in the AI Insights tab!';
    }

    if (_matches(q, [
      'hi',
      'hello',
      'hey',
      'good morning',
      'salam',
      'assalam',
    ])) {
      return 'Hello! 👋 Great to chat with you!\n\n'
          'Ask me about your finances or get money-saving tips.\n\n'
          'Examples:\n'
          "• 'How much did I spend this month?'\n"
          "• 'Am I over budget on food?'\n"
          "• 'Compare this month vs last month'\n"
          "• 'Tips to save money'";
    }

    if (_matches(q, [
      'thanks',
      'thank you',
      'shukriya',
      'helpful',
      'great',
      'awesome',
      'shukria',
    ])) {
      return "You're welcome! 😊\n\n"
          'Good financial habits are built one day at a time. '
          "Keep tracking and you'll see the difference!\n\n"
          'Anything else I can help with?';
    }

    // ── Last resort: check if query contains ANY known category ──
    if (detectedCat != null) {
      return _categorySpending(ctx, detectedCat, offset);
    }

    // ── Fallback ──
    return "I'm a specialized finance assistant. Here's what I can help with:\n\n"
        "• 💸 'How much did I spend on food this month?'\n"
        "• 📊 'Am I over budget on anything?'\n"
        "• 📈 'Compare this month vs last month'\n"
        "• 💰 'What is my highest income category?'\n"
        "• 🎯 'Tips to save money'\n\n"
        "This is by design — like McDonald's kiosks that only take food orders! 🍔";
  }

  bool _matches(String query, List<String> keywords) {
    return keywords.any((kw) => query.contains(kw));
  }

  // ══════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: AppColors.neonBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SpendWise Assistant',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Finance & Budgeting Guide',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),

            if (_messages.length <= 2)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _suggestions.map((s) {
                    return GestureDetector(
                      onTap: () => _sendMessage(s),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 8),

            Container(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask about your spending or finance tips...',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: AppColors.neonBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient: AppColors.neonBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              gradient: AppColors.neonBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                _dot(),
                const SizedBox(width: 4),
                _dot(),
                const SizedBox(width: 4),
                _dot(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, val, __) => Opacity(
        opacity: val,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _TxSummary {
  final String category;
  final double amount;
  final String type;
  _TxSummary(this.category, this.amount, this.type);
}

class _Exchange {
  final String userQuery;
  final String botReply;
  _Exchange(this.userQuery, this.botReply);
}
