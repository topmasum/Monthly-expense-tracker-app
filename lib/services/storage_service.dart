import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/shopping_item.dart';


class StorageService {
  static const String _keyExpenses = 'expenses_v1';
  static const String _keyDarkMode = 'dark_mode_v1';
  static const String prefKeyDarkMode = _keyDarkMode;


  static late SharedPreferences _prefs;


  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
  }


  static List<Expense> getAllExpenses() {
    final raw = _prefs.getStringList(_keyExpenses) ?? <String>[];
    return raw.map((s) => Expense.fromJson(s)).toList();
  }


  static Future<void> saveExpenses(List<Expense> list) async {
    final raw = list.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_keyExpenses, raw);
  }


  static Future<void> addExpense(Expense e) async {
    final list = getAllExpenses();
    list.add(e);
    await saveExpenses(list);
  }


  static Future<void> updateExpense(Expense e) async {
    final list = getAllExpenses();
    final idx = list.indexWhere((x) => x.id == e.id);
    if (idx >= 0) {
      list[idx] = e;
      await saveExpenses(list);
    }
  }


  static Future<void> deleteExpense(String id) async {
    final list = getAllExpenses();
    list.removeWhere((x) => x.id == id);
    await saveExpenses(list);
  }


  static Future<void> saveDarkMode(bool isDark) async {
    await _prefs.setBool(_keyDarkMode, isDark);
  }
  static const String _keyShoppingList = 'shopping_list_v1';

  static List<ShoppingItem> getShoppingList() {
    final raw = _prefs.getStringList(_keyShoppingList) ?? <String>[];
    return raw.map((s) => ShoppingItem.fromJson(s)).toList();
  }

  static Future<void> saveShoppingList(List<ShoppingItem> list) async {
    final raw = list.map((e) => e.toJson()).toList();
    await _prefs.setStringList(_keyShoppingList, raw);
  }

  static Future<void> addShoppingItem(ShoppingItem item) async {
    final list = getShoppingList();
    list.add(item);
    await saveShoppingList(list);
  }

  static Future<void> deleteShoppingItem(String id) async {
    final list = getShoppingList();
    list.removeWhere((x) => x.id == id);
    await saveShoppingList(list);
  }
  // ... inside StorageService class ...

  static const String _keyCurrency = 'currency_symbol_v1';

  // Default to $ if nothing saved
  static String getCurrency() {
    return _prefs.getString(_keyCurrency) ?? '\$';
  }

  static Future<void> saveCurrency(String symbol) async {
    await _prefs.setString(_keyCurrency, symbol);
  }
}