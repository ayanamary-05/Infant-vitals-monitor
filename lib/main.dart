import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';
// ─────────────────────────────────────────────
//  Global Notification Plugin
// ─────────────────────────────────────────────

final FlutterLocalNotificationsPlugin localNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel kCriticalChannel = AndroidNotificationChannel(
  'critical_vitals_alarm',
  'Infant Vitals Alarm',
  description: 'Urgent alarms for out-of-range infant vital signs.',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

// ─────────────────────────────────────────────
//  Global notifiers
// ─────────────────────────────────────────────
final themeModeNotifier    = ValueNotifier<ThemeMode>(ThemeMode.dark);
final languageNotifier     = ValueNotifier<Locale>(const Locale('en'));
final tempUnitNotifier     = ValueNotifier<String>('Celsius');      // 'Celsius' | 'Fahrenheit'
final refreshRateNotifier  = ValueNotifier<int>(3);                 // seconds
final alertCountNotifier      = ValueNotifier<int>(0);                 // active alert count
final criticalAlertNotifier   = ValueNotifier<bool>(false);            // true while full-screen alarm is shown

// ... existing locale map ...
const Map<String, Locale> kSupportedLocales = {
  'English':              Locale('en'),
  'Swahili':              Locale('sw'),
  'French':               Locale('fr'),
  'Hindi':                Locale('hi'),
  'Spanish':              Locale('es'),
  'Arabic':               Locale('ar'),
  'Malayalam':            Locale('ml'),
  'Portuguese':           Locale('pt'),
  'German':               Locale('de'),
  'Chinese Simplified':   Locale('zh'),
};

final batterySaverNotifier  = ValueNotifier<bool>(false);
final cloudBackupNotifier   = ValueNotifier<bool>(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
} catch (e) {
  // Already initialized — safe to ignore
  debugPrint('Firebase already initialized: $e');
}

  // App Check for Physical Device
  // try {
  //   await FirebaseAppCheck.instance.activate(
  //     androidProvider: AndroidProvider.playIntegrity,
  //   );
  //   debugPrint("App Check: Activated successfully");
  // } catch (e) {
  //   debugPrint("App Check: Activation failed: $e");
  // }

  // Initialize Notifications
  const androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const initSettings =
      InitializationSettings(android: androidInit);

  await localNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) {
      criticalAlertNotifier.value = true;
    },
  );

  final androidPlugin = localNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(
      kCriticalChannel);

  await androidPlugin?.requestNotificationsPermission();

  // Request Overlay permission
  if (await Permission.systemAlertWindow.isDenied) {
    await Permission.systemAlertWindow.request();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, child1) => ValueListenableBuilder<Locale>(
        valueListenable: languageNotifier,
        builder: (context, locale, child2) {
          final isRtl = locale.languageCode == 'ar';
          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: MaterialApp(
              title: 'Infant Vitals Monitor',
              debugShowCheckedModeBanner: false,
              themeMode: mode,
              locale: locale,
              supportedLocales: kSupportedLocales.values.toList(),

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
                cardTheme: const CardThemeData(
                  color: Color(0xFF1E293B),
                  elevation: 0,
                ),
              ),

              home: const AuthWrapper(),
            ),
          );
        },
      ),
    );
  }
}