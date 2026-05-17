import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'models/account.dart';
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/pin_screen.dart';
import 'package:finance_tracker/screens/settings_screen.dart';
import 'theme_provider.dart';
import 'package:intl/date_symbol_data_local.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(AccountAdapter());
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Account>('accounts');
  await Hive.openBox('settings');
  await initializeDateFormatting('el_GR', null); 
  await Hive.initFlutter();

  final isDark = Hive.box('settings').get('darkMode', defaultValue: false) as bool;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(isDark),
      child: const FinanceApp(),
    ),
  );
}

const _kSeedColor = Color(0xFF1565C0);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final cs = ColorScheme.fromSeed(
    seedColor: _kSeedColor,
    brightness: brightness,
  ).copyWith(
    primary: isDark ? const Color(0xFF4DA6FF) : const Color(0xFF1565C0),
    primaryContainer: isDark ? const Color(0xFF0D2137) : const Color(0xFFDCEEFF),
    secondary: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
    surface: isDark ? const Color(0xFF0F1C2E) : Colors.white,
    background: isDark ? const Color(0xFF0A1628) : const Color(0xFFF4F7FB),
    onBackground: isDark ? Colors.white : const Color(0xFF0D1B2A),
    onSurface: isDark ? Colors.white : const Color(0xFF0D1B2A),
    onPrimary: Colors.white,
    onPrimaryContainer: isDark ? Colors.white : const Color(0xFF0D2137),
    error: const Color(0xFFFF6B6B),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: cs.background,
    cardColor: isDark ? const Color(0xFF142035) : Colors.white,
    dividerColor: isDark ? Colors.white12 : Colors.grey.shade200,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF0F1C2E) : const Color(0xFF1565C0),
      indicatorColor: isDark ? const Color(0xFF1D3A5F) : const Color(0xFF1976D2),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: Colors.white);
        }
        return IconThemeData(color: Colors.white.withOpacity(0.6));
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600);
        }
        return TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12);
      }),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: isDark ? const Color(0xFF4DA6FF) : const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1A2B45) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF4DA6FF) : const Color(0xFF1565C0),
          width: 2,
        ),
      ),
      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
    ),
    cardTheme: CardThemeData(
      color: isDark ? const Color(0xFF142035) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF4DA6FF) : const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: isDark ? Colors.white : const Color(0xFF0D1B2A)),
      bodyMedium: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF2C3E50)),
      bodySmall: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600),
      titleMedium: TextStyle(color: isDark ? Colors.white : const Color(0xFF0D1B2A), fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: isDark ? Colors.white : const Color(0xFF0D1B2A), fontWeight: FontWeight.bold),
    ),
  );
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Οικονομικός Tracker',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeProvider.mode,
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    final pin = Hive.box('settings').get('pin', defaultValue: '') as String;
    if (pin.isEmpty) _unlocked = true;
  }

  @override
  Widget build(BuildContext context) {
  final box = Hive.box('settings');
  final pinEnabled = box.get('pinEnabled', defaultValue: false);

  if (pinEnabled) {
    return PinScreen(
      onSuccess: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      ),
    );
  }
  return const MainScreen();
}
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Αρχική',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Κινήσεις',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Λογαριασμοί',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Στατιστικά',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ρυθμίσεις',
          ),
        ],
      ),
    );
  }
}