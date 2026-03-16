import 'package:intl/intl.dart';

class CurrencyFormatter {
  static const String defaultCurrency = 'PKR';
  static const String currencySymbol = 'PKR';

  // Format: PKR 1,234.56
  static String format(double amount, {String? currency}) {
    final formatter = NumberFormat.currency(
      symbol: currency ?? currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Format: PKR 1,234 (no decimals)
  static String formatCompact(double amount, {String? currency}) {
    final formatter = NumberFormat.currency(
      symbol: currency ?? currencySymbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Format: 1,234.56 (no currency symbol)
  static String formatNumber(double amount, {int decimals = 2}) {
    final formatter = NumberFormat.decimalPattern();
    if (decimals == 0) {
      return formatter.format(amount.round());
    }
    return amount.toStringAsFixed(decimals);
  }

  // Format: PKR 1.2K, PKR 1.5M
  static String formatShort(double amount, {String? currency}) {
    final curr = currency ?? currencySymbol;

    if (amount >= 1000000000) {
      return '$curr ${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '$curr ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$curr ${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '$curr ${amount.toStringAsFixed(0)}';
    }
  }

  // Format with sign: +PKR 1,234 or -PKR 1,234
  static String formatWithSign(
    double amount, {
    String? currency,
    bool showPlus = true,
  }) {
    final formatted = formatCompact(amount.abs(), currency: currency);
    if (amount > 0 && showPlus) {
      return '+$formatted';
    } else if (amount < 0) {
      return '-$formatted';
    }
    return formatted;
  }

  // Format income/expense with color coding (returns formatted string)
  static String formatTransaction(
    double amount,
    bool isIncome, {
    String? currency,
  }) {
    final formatted = formatCompact(amount, currency: currency);
    return isIncome ? '+$formatted' : '-$formatted';
  }

  // Parse string to double
  static double? parse(String amount) {
    try {
      // Remove currency symbols and commas
      final cleaned = amount.replaceAll(RegExp(r'[^\d.]'), '');
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  // Format percentage
  static String formatPercentage(double percentage, {int decimals = 1}) {
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  // Calculate percentage
  static double calculatePercentage(double part, double whole) {
    if (whole == 0) return 0;
    return (part / whole) * 100;
  }

  // Format with custom symbol
  static String formatWithSymbol(
    double amount,
    String symbol, {
    int decimals = 2,
  }) {
    return '$symbol ${amount.toStringAsFixed(decimals)}';
  }

  // Convert to words (for checks, etc.)
  static String toWords(int amount) {
    if (amount == 0) return 'Zero';

    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
    ];
    final teens = [
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String convertLessThanThousand(int num) {
      if (num == 0) return '';
      if (num < 10) return ones[num];
      if (num < 20) return teens[num - 10];
      if (num < 100) {
        return '${tens[num ~/ 10]} ${ones[num % 10]}'.trim();
      }
      return '${ones[num ~/ 100]} Hundred ${convertLessThanThousand(num % 100)}'
          .trim();
    }

    if (amount < 1000) return convertLessThanThousand(amount);
    if (amount < 100000) {
      return '${convertLessThanThousand(amount ~/ 1000)} Thousand ${convertLessThanThousand(amount % 1000)}'
          .trim();
    }
    if (amount < 10000000) {
      return '${convertLessThanThousand(amount ~/ 100000)} Lakh ${convertLessThanThousand(amount % 100000)}'
          .trim();
    }
    return '${convertLessThanThousand(amount ~/ 10000000)} Crore ${convertLessThanThousand(amount % 10000000)}'
        .trim();
  }
}
