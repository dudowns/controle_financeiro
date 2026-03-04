// lib/utils/currency_formatter.dart
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double value) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
    ).format(value);
  }

  // 🔥 ADICIONAR ESTE MÉTODO!
  static String formatCompact(double value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(0)}k';
    }
    return format(value);
  }

  static String formatPercentual(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  static String formatVariation(double value) {
    final signal = value >= 0 ? '+' : '';
    return '$signal${value.toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  static double parse(String value) {
    try {
      String cleaned = value.replaceAll('R\$', '').replaceAll(' ', '');
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      return double.parse(cleaned);
    } catch (e) {
      return 0;
    }
  }
}
