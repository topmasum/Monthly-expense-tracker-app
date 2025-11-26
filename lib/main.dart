import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'services/storage_service.dart';
import 'theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool(StorageService.prefKeyDarkMode) ?? false;
  await StorageService.initialize(prefs);
  runApp(MyApp(isDark: isDark));
}


class MyApp extends StatefulWidget {
  final bool isDark;
  const MyApp({super.key, required this.isDark});


  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {
  late bool _isDark;


  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
  }


  void toggleTheme(bool value) async {
    setState(() => _isDark = value);
    await StorageService.saveDarkMode(value);
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Monthly Expense Tracker',
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(onThemeToggle: toggleTheme, isDark: _isDark),
    );
  }
}