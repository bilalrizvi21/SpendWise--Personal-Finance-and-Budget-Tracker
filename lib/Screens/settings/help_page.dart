import 'package:flutter/material.dart';
import '../../Core/constants/app_colors.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final List<_FAQItem> _faqs = [
    _FAQItem(
      question: 'How do I add a transaction?',
      answer:
          'Go to the Home screen and tap "Add Income" or "Add Expense". Fill in the amount, category, date, and payment method, then tap Save.',
    ),
    _FAQItem(
      question: 'How do budgets work?',
      answer:
          'Go to the Budget tab and tap the + button to set a monthly limit for a category. SpendWise automatically tracks your spending against this limit based on your expense transactions.',
    ),
    _FAQItem(
      question: 'How do I set a savings goal?',
      answer:
          'Go to the Goals tab and tap the + button. Enter a goal name, target amount, and an optional deadline. You can add savings to a goal anytime by tapping "Add Savings" on the goal card.',
    ),
    _FAQItem(
      question: 'Why is my data not showing after reopening the app?',
      answer:
          'All data is stored locally on your device using SQLite. Make sure you have not cleared the app data from your device settings. If the issue persists, try restarting the app.',
    ),
    _FAQItem(
      question: 'Can I edit or delete a transaction?',
      answer:
          'Go to the Transactions tab, find the transaction you want to modify, and swipe or long-press to reveal edit and delete options.',
    ),
    _FAQItem(
      question: 'What does the AI Insights page show?',
      answer:
          'The AI Insights page analyzes your spending patterns and provides intelligent recommendations such as budget warnings, saving tips, spending anomalies, and goal projections based on your real transaction data.',
    ),
    _FAQItem(
      question: 'How do I change the currency?',
      answer:
          'Go to Settings and tap Currency under the Profile section. Select your preferred currency from the list.',
    ),
    _FAQItem(
      question: 'Is my financial data secure?',
      answer:
          'Yes. All your data is stored locally on your device only. Nothing is uploaded to any external server. You can also enable biometric authentication in Settings → Security for extra protection.',
    ),
    _FAQItem(
      question: 'How do I view my monthly report?',
      answer:
          'Go to Settings → Reports. Use the arrow buttons to navigate between months. The report shows your total income, expenses, net balance, and a category-wise breakdown.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Help & Support',
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.white, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap a question to see the answer',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // FAQs
          ..._faqs.map((faq) => _buildFAQItem(faq)),

          const SizedBox(height: 20),

          // Contact
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.mail_outline,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Still need help?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reach out to our support team at\nsupport@spendwise.app',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(_FAQItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          faq.question,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Text(
            faq.answer,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQItem {
  final String question;
  final String answer;
  _FAQItem({required this.question, required this.answer});
}
