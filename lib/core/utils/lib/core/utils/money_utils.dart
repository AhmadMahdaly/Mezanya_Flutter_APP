import 'package:intl/intl.dart';

class MoneyUtils {
  static String format(double amount, {String currency = 'EGP', String locale = 'ar'}) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: _currencySymbol(currency),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatSimple(double amount) {
    return amount.toStringAsFixed(2);
  }

  static String _currencySymbol(String currency) {
    return switch (currency) {
      'EGP' => 'ج.م',
      'USD' => '\$',
      'EUR' => '€',
      _ => currency,
    };
  }
}