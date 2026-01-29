import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/shopping_item.dart';

class StorageService {
  // --- KEYS ---
  static const String _keyExpenses = 'expenses_v1';
  static const String _keyDarkMode = 'dark_mode_v1';
  static const String _keyShoppingList = 'shopping_list_v1';
  static const String _keyCurrency = 'currency_symbol_v1';

  // Public key for main.dart to reference if needed
  static const String prefKeyDarkMode = _keyDarkMode;

  static late SharedPreferences _prefs;

  // --- INITIALIZATION ---
  static Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  // --- EXPENSE METHODS ---
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

  // --- THEME METHODS ---
  static bool getDarkMode() {
    return _prefs.getBool(_keyDarkMode) ?? false; // Default to Light Mode
  }

  static Future<void> saveDarkMode(bool isDark) async {
    await _prefs.setBool(_keyDarkMode, isDark);
  }

  // --- SHOPPING LIST METHODS ---
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

  // --- CURRENCY METHODS ---
  static String getCurrency() {
    return _prefs.getString(_keyCurrency) ?? '\$';
  }

  static Future<void> saveCurrency(String symbol) async {
    await _prefs.setString(_keyCurrency, symbol);
  }

  // --- BUDGET METHODS (HISTORICAL) ---

  // Helper to generate keys like "budgets_2026_1"
  static String _getBudgetKey(DateTime date) {
    return 'budgets_${date.year}_${date.month}';
  }

  static Future<void> saveBudget(Category category, double limit, DateTime month) async {
    final key = _getBudgetKey(month);

    // 1. Get existing budgets for THIS specific month
    final Map<Category, double> currentMonthBudgets = getBudgets(month);

    // 2. Update the specific category
    currentMonthBudgets[category] = limit;

    // 3. Convert to String Map for storage
    final Map<String, double> stringMap = {};
    currentMonthBudgets.forEach((key, val) => stringMap[key.name] = val);

    // 4. Save to the specific month's key
    await _prefs.setString(key, json.encode(stringMap));
  }

  static Map<Category, double> getBudgets(DateTime month) {
    final key = _getBudgetKey(month);
    final String? jsonStr = _prefs.getString(key);

    if (jsonStr == null) return {}; // Returns empty map (Reset) for new months

    try {
      final Map<String, dynamic> decoded = json.decode(jsonStr);
      final Map<Category, double> result = {};

      decoded.forEach((key, value) {
        final cat = Category.values.firstWhere(
                (e) => e.name == key,
            orElse: () => Category.other
        );
        result[cat] = (value as num).toDouble();
      });
      return result;
    } catch (e) {
      return {};
    }
  }
}