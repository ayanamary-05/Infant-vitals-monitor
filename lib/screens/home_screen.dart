import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:first_app/screens/history_screen.dart';
import 'package:first_app/screens/spike_history_screen.dart';
import 'package:first_app/screens/settings_screen.dart';
import 'package:first_app/screens/profile_screen.dart';


// ── Palette ───────────────────────────────
const Color kBg      = Color(0xFF0F172A);
const Color kSurface = Color(0xFF1E293B);
const Color kGreen   = Color(0xFF1DB954);
const Color kBlue    = Color(0xFF4F8EF7);
const Color kPurple  = Color(0xFFA78BFA);
const Color kOrange  = Color(0xFFFFAB40);
const Color kRed     = Color(0xFFFF6B6B);
const Color kSubtext = Color(0xFF94A3B8);

// ══════════════════════════════════════════
// ROOT — manages bottom nav
// ══════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final _tabs = const [
    _DashboardTab(),
    HistoryScreen(),
    SpikeHistoryScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ══════════════════════════════════════════
// DASHBOARD TAB
// ══════════════════════════════════════════
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _latestRef = FirebaseDatabase.instance.ref('vitals/latest');
  final _alertRef  = FirebaseDatabase.instance.ref('alerts');

  double _hr = 0, _spo2 = 0, _temp = 0;
  bool _alertActive = false;

  String get _displayName =>
      FirebaseAuth.instance.currentUser?.displayName?.trim().split(' ').first
      ?? 'Caregiver';

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  void initState() {
    super.initState();
    _listenVitals();
    _listenAlerts();
  }

  void _listenVitals() {
    _latestRef.onValue.listen((event) {
      if (event.snapshot.value == null || !mounted) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _hr   = double.tryParse(data['heartRate'].toString())   ?? _hr;
        _spo2 = double.tryParse(data['spo2'].toString())        ?? _spo2;
        _temp = double.tryParse(data['temperature'].toString()) ?? _temp;
      });
    });
  }

  void _listenAlerts() {
    _alertRef.onValue.listen((event) {
      if (event.snapshot.value == null || !mounted) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() => _alertActive = data['active'] == true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use fallback demo values when sensor not yet connected
    final hrVal   = _hr   > 0 ? _hr   : 139.0;
    final tempVal = _temp > 0 ? _temp : 37.9;
    final spo2Val = _spo2 > 0 ? _spo2 : 95.0;

    final vitals = [
      _VitalRow(
        label: 'Heart Rate',
        normalRange: 'Normal: 100 – 160 BPM',
        value: hrVal.toStringAsFixed(0),
        unit: 'BPM',
        icon: Icons.favorite_rounded,
        color: kRed,
      ),
      _VitalRow(
        label: 'Body Temperature',
        normalRange: 'Normal: 36.5 – 38.0 °C',
        value: tempVal.toStringAsFixed(1),
        unit: '°C',
        icon: Icons.thermostat_rounded,
        color: kOrange,
      ),
      _VitalRow(
        label: 'Oxygen Saturation',
        normalRange: 'Normal: 94 – 100 %',
        value: spo2Val.toStringAsFixed(0),
        unit: '%',
        icon: Icons.air_rounded,
        color: kBlue,
      ),
    ];

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          // ── Greeting ──────────────────────────────
          Text('$_greeting $_displayName',
              style: const TextStyle(color: kSubtext, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Infant Monitoring',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // ── Status banner ─────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _alertActive
                  ? kRed.withValues(alpha: 0.12)
                  : kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _alertActive
                    ? kRed.withValues(alpha: 0.35)
                    : kGreen.withValues(alpha: 0.35),
              ),
            ),
            child: Row(children: [
              Icon(
                _alertActive
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: _alertActive ? kRed : kGreen,
                size: 22,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _alertActive
                        ? 'Vital Alert Active'
                        : 'All Vitals Normal',
                    style: TextStyle(
                      color: _alertActive ? kRed : kGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _alertActive
                        ? 'Check readings immediately!'
                        : "Baby's vitals are within safe range.",
                    style: TextStyle(
                      color: (_alertActive ? kRed : kGreen)
                          .withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Vital rows ────────────────────────────
          ...vitals.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DashboardVitalCard(row: v),
              )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// VITAL ROW DATA
// ══════════════════════════════════════════
class _VitalRow {
  final String label;
  final String normalRange;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  const _VitalRow({
    required this.label,
    required this.normalRange,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });
}

// ══════════════════════════════════════════
// DASHBOARD VITAL CARD
// ══════════════════════════════════════════
class _DashboardVitalCard extends StatelessWidget {
  final _VitalRow row;
  const _DashboardVitalCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: row.color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(row.icon, color: row.color, size: 22),
          ),
          const SizedBox(width: 16),
          // Label + normal range
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(row.normalRange,
                    style: const TextStyle(
                        color: kSubtext, fontSize: 11)),
              ],
            ),
          ),
          // Value + unit
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(row.value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.0)),
              Text(row.unit,
                  style: const TextStyle(
                      color: kSubtext, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// BOTTOM NAV
// ══════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  static const _items = [
    (Icons.grid_view_rounded,         Icons.grid_view_outlined,          'Dashboard'),
    (Icons.access_time_rounded,        Icons.access_time_outlined,        'History'),
    (Icons.notifications_rounded,      Icons.notifications_outlined,      'Alerts'),
    (Icons.person_rounded,             Icons.person_outlined,             'Profile'),
    (Icons.settings_rounded,           Icons.settings_outlined,           'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: kSurface,
          border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final sel = i == current;
              final (filled, outlined, label) = _items[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(sel ? filled : outlined,
                            key: ValueKey(sel),
                            color: sel ? kGreen : kSubtext,
                            size: 22),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                            color: sel ? kGreen : kSubtext,
                            fontSize: 10,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.normal),
                        child: Text(label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
