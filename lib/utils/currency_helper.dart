import 'package:intl/intl.dart';
import '../services/storage_service.dart';

class CurrencyHelper {
  static String format(double amount) {
    final symbol = StorageService.getCurrency();

    // LOGIC:
    // If the number is whole (e.g. 20.0), show "20"
    // If the number has cents (e.g. 12.5), show "12.50"
    if (amount % 1 == 0) {
      return NumberFormat.currency(symbol: symbol, decimalDigits: 0).format(amount);
    } else {
      return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);
    }
  }
}