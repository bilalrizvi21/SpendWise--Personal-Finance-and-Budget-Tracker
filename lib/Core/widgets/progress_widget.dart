import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/currency_formatter.dart';

// Progress bar with label
class LabeledProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final String? label;
  final bool showPercentage;

  const LabeledProgressBar({
    Key? key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.label,
    this.showPercentage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).toInt();
    final progressColor = color ?? _getColorByValue(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (showPercentage)
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: backgroundColor ?? Colors.grey.shade200,
            color: progressColor,
            minHeight: height,
          ),
        ),
      ],
    );
  }

  Color _getColorByValue(double value) {
    if (value >= 0.9) return AppColors.error;
    if (value >= 0.8) return AppColors.warning;
    return AppColors.success;
  }
}

// Circular progress with percentage
class CircularPercentage extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final Color? color;
  final double strokeWidth;
  final bool showPercentage;
  final Widget? center;

  const CircularPercentage({
    Key? key,
    required this.value,
    this.size = 100,
    this.color,
    this.strokeWidth = 8,
    this.showPercentage = true,
    this.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).toInt();
    final progressColor = color ?? AppColors.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          center ??
              (showPercentage
                  ? Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: size * 0.2,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );
  }
}

// Budget progress card
class BudgetProgressCard extends StatelessWidget {
  final String category;
  final double used;
  final double limit;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const BudgetProgressCard({
    Key? key,
    required this.category,
    required this.used,
    required this.limit,
    required this.color,
    this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (used / limit).clamp(0.0, 1.0);
    final remaining = limit - used;
    final isWarning = percentage >= 0.8;
    final isOverBudget = used > limit;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.formatPercentage(percentage * 100),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOverBudget
                          ? AppColors.error
                          : (isWarning ? AppColors.warning : AppColors.success),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LabeledProgressBar(
                value: percentage,
                color: isOverBudget
                    ? AppColors.error
                    : (isWarning ? AppColors.warning : color),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Used: ${CurrencyFormatter.formatCompact(used)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    'Limit: ${CurrencyFormatter.formatCompact(limit)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isOverBudget
                    ? 'Over budget by ${CurrencyFormatter.formatCompact(remaining.abs())}'
                    : 'Remaining: ${CurrencyFormatter.formatCompact(remaining)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isOverBudget
                      ? AppColors.error
                      : (isWarning ? AppColors.warning : AppColors.success),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Goal progress card
class GoalProgressCard extends StatelessWidget {
  final String goalName;
  final double current;
  final double target;
  final String? deadline;
  final Color color;
  final String? smartTip;
  final VoidCallback? onTap;

  const GoalProgressCard({
    Key? key,
    required this.goalName,
    required this.current,
    required this.target,
    this.deadline,
    required this.color,
    this.smartTip,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (current / target).clamp(0.0, 1.0);
    final remaining = target - current;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.flag, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goalName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (deadline != null)
                          Text(
                            'Deadline: $deadline',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatPercentage(percentage * 100),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LabeledProgressBar(value: percentage, color: color),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved: ${CurrencyFormatter.formatCompact(current)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Target: ${CurrencyFormatter.formatCompact(target)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Remaining: ${CurrencyFormatter.formatCompact(remaining)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              if (smartTip != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          smartTip!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
