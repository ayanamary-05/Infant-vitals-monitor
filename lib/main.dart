import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/vital_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infant Vitals Monitor',
      debugShowCheckedModeBanner: false,

      // ── Light theme ──────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
          surface: Colors.white,
          onSurface: Colors.black87,
          onSurfaceVariant: Colors.black54,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        dividerColor: const Color(0xFFE2E8F0),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black54),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        // ✅ Fix: use CardThemeData instead of CardTheme
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
        ),
      ),

      // ── Dark theme ───────────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          surface: Color(0xFF1E293B),
          onSurface: Color(0xFFF1F5F9),
          onSurfaceVariant: Color(0xFF94A3B8),
          surfaceContainerHighest: Color(0xFF334155),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        dividerColor: const Color(0xFF334155),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF1F5F9)),
          bodySmall: TextStyle(color: Color(0xFF94A3B8)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Color(0xFFF1F5F9),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        // ✅ Fix: use CardThemeData instead of CardTheme
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 0,
        ),
      ),

      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────
//  HomeScreen
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    VitalsScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Bottom navigation bar
// ─────────────────────────────────────────────
class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AppBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: cs.surface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant.withOpacity(0.7),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_outlined),
            activeIcon: Icon(Icons.monitor_heart_rounded),
            label: 'Vitals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}