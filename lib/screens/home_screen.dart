import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:first_app/screens/vital_models.dart';
import 'package:first_app/screens/vital_screen.dart';
import 'package:first_app/screens/vitals_history_screen.dart';
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
  // Firebase refs
  final _latestRef = FirebaseDatabase.instance.ref('vitals/latest');
  final _alertRef  = FirebaseDatabase.instance.ref('alerts');

  // Live values
  double _hr = 0, _spo2 = 0, _temp = 0;
  bool _alertActive = false;

  // Rolling history for sparklines (last 20 readings each)
  final List<double> _hrHist   = [];
  final List<double> _spo2Hist = [];
  final List<double> _tempHist = [];

  static const _histLen = 20;

  // Spike mock data
  // TODO: Replace with Firestore/RTDB query once you store spikes
  final List<SpikeAlert> _recentSpikes = [
    SpikeAlert(vitalName: 'Heart Rate',  value: 172,  unit: 'bpm',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 14)),
        color: kGreen, isHigh: true),
    SpikeAlert(vitalName: 'SpO₂',        value: 91.2, unit: '%',
        timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 33)),
        color: kBlue, isHigh: false),
    SpikeAlert(vitalName: 'Temperature', value: 38.2, unit: '°C',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        color: kOrange, isHigh: true),
  ];

  String get _firstName {
    final name =
        FirebaseAuth.instance.currentUser?.displayName ?? 'there';
    return name.trim().split(' ').first;
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
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
      final data =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _hr   = double.tryParse(data['heartRate'].toString())   ?? _hr;
        _spo2 = double.tryParse(data['spo2'].toString())        ?? _spo2;
        _temp = double.tryParse(data['temperature'].toString()) ?? _temp;

        void push(List<double> list, double val) {
          list.add(val);
          if (list.length > _histLen) list.removeAt(0);
        }

        if (_hr   > 0) push(_hrHist,   _hr);
        if (_spo2 > 0) push(_spo2Hist, _spo2);
        if (_temp > 0) push(_tempHist, _temp);
      });
    });
  }

  void _listenAlerts() {
    _alertRef.onValue.listen((event) {
      if (event.snapshot.value == null || !mounted) return;
      final data =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() => _alertActive = data['active'] == true);
    });
  }

  List<double> _fallback(List<double> hist, double base, double spread) {
    if (hist.isNotEmpty) return hist;
    final rng = math.Random(42);
    return List.generate(12, (_) =>
        base + (rng.nextDouble() - 0.5) * 2 * spread);
  }

  @override
  Widget build(BuildContext context) {
    final vitals = [
      VitalReading(
          name: 'Heart Rate', unit: 'bpm',
          current: _hr == 0 ? 0 : _hr,
          displayMin: 100, displayMax: 180,
          history: _fallback(_hrHist, 138, 12),
          color: kGreen, icon: Icons.favorite_rounded,
          normalRange: '120–160 bpm', decimalPlaces: 0),
      VitalReading(
          name: 'SpO₂', unit: '%',
          current: _spo2 == 0 ? 0 : _spo2,
          displayMin: 88, displayMax: 100,
          history: _fallback(_spo2Hist, 98, 1.5),
          color: kBlue, icon: Icons.water_drop_rounded,
          normalRange: '95–100%', decimalPlaces: 1),
      VitalReading(
          name: 'Temperature', unit: '°C',
          current: _temp == 0 ? 0 : _temp,
          displayMin: 35, displayMax: 39,
          history: _fallback(_tempHist, 36.8, 0.3),
          color: kOrange, icon: Icons.thermostat_rounded,
          normalRange: '36.5–37.5°C', decimalPlaces: 1),
      // Resp. rate placeholder — add Firebase field when available
      VitalReading(
          name: 'Resp. Rate', unit: 'br/min',
          current: 0,
          displayMin: 20, displayMax: 70,
          history: List.generate(12, (i) =>
              40 + math.sin(i * 0.6) * 8),
          color: kPurple, icon: Icons.air_rounded,
          normalRange: '30–60 br/min', decimalPlaces: 0),
    ];

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Top bar ──────────────────────────────
          SliverToBoxAdapter(child: _TopBar(alertActive: _alertActive)),

          // ── Greeting ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hey $_firstName! 👋',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          height: 1.1)),
                  const SizedBox(height: 5),
                  Text(_greeting,
                      style: const TextStyle(
                          color: kSubtext, fontSize: 14)),
                ],
              ),
            ),
          ),

          // ── Alert banner ──────────────────────────
          if (_alertActive)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kRed.withValues(alpha: 0.4)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.warning_amber_rounded, color: kRed, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text('Vital alert is active — check readings!',
                            style: TextStyle(color: kRed, fontSize: 13))),
                  ]),
                ),
              ),
            ),

          // ── Vital History card ────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              child: _VitalHistoryCard(vitals: vitals),
            ),
          ),

          // ── Section heading ───────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, 28, 22, 12),
              child: Text('Vitals at the Moment',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),

          // ── 2×2 Vital grid ────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
              children: vitals.map((v) => _VitalCard(vital: v)).toList(),
            ),
          ),

          // ── Spike History card ────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
              child: _SpikePreviewCard(spikes: _recentSpikes),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// TOP BAR
// ══════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final bool alertActive;
  const _TopBar({this.alertActive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: kSubtext, size: 22),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        const Expanded(
          child: Center(
            child: Text('NeoBeat',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8)),
          ),
        ),
        Stack(clipBehavior: Clip.none, children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: kSubtext, size: 22),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const SpikeHistoryScreen())),
          ),
          if (alertActive)
            Positioned(
              top: 8, right: 8,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: kRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: kBg, width: 1.5)),
              ),
            ),
        ]),
      ]),
    );
  }
}

// ══════════════════════════════════════════
// VITAL HISTORY CARD
// ══════════════════════════════════════════
class _VitalHistoryCard extends StatelessWidget {
  final List<VitalReading> vitals;
  const _VitalHistoryCard({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const VitalsHistoryScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF1E2D4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.history_rounded,
                        color: kBlue.withValues(alpha: 0.8), size: 13),
                    const SizedBox(width: 5),
                    Text('VITAL HISTORY',
                        style: TextStyle(
                            color: kBlue.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                  ]),
                  const SizedBox(height: 10),
                  const Text(
                    "Check up on your\nbaby's vitals over time",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: kBlue.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min,
                        children: [
                      Text('View all graphs',
                          style: TextStyle(
                              color: kBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward_rounded,
                          color: kBlue, size: 13),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Mini sparklines preview
            SizedBox(
              width: 100,
              height: 88,
              child: Column(
                children: vitals.map((v) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: CustomPaint(
                      painter: _SparklinePainter(
                          data: v.history,
                          color: v.color,
                          filled: false,
                          strokeWidth: 1.5,
                          showDot: false),
                      size: Size.infinite,
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// VITAL CARD
// ══════════════════════════════════════════
class _VitalCard extends StatelessWidget {
  final VitalReading vital;
  const _VitalCard({required this.vital});

  @override
  Widget build(BuildContext context) {
    final isWaiting = vital.current == 0;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const VitalsScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: vital.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(vital.icon, color: vital.color, size: 15),
              ),
              const Spacer(),
              _LiveDot(color: vital.color),
            ]),
            const SizedBox(height: 12),
            Text(
              isWaiting ? '--' : vital.formattedCurrent,
              style: TextStyle(
                  color: vital.color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.0),
            ),
            Text(vital.unit,
                style: const TextStyle(color: kSubtext, fontSize: 10)),
            const SizedBox(height: 3),
            Text(vital.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            SizedBox(
              height: 44,
              child: CustomPaint(
                painter: _SparklinePainter(
                    data: vital.history,
                    color: vital.color,
                    filled: true,
                    strokeWidth: 2.0,
                    showDot: true),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 6),
            Text('Normal: ${vital.normalRange}',
                style: const TextStyle(color: kSubtext, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// SPIKE PREVIEW CARD
// ══════════════════════════════════════════
class _SpikePreviewCard extends StatelessWidget {
  final List<SpikeAlert> spikes;
  const _SpikePreviewCard({required this.spikes});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SpikeHistoryScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: kRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.warning_amber_rounded,
                    color: kRed, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spike Alerts',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    Text('Tap to view full alert history',
                        style: TextStyle(color: kSubtext, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: kSubtext),
            ]),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 14),
            ...spikes.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                          color: s.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(s.severity,
                          style: TextStyle(
                              color: s.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(s.vitalName,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13))),
                    Text(s.formattedValue,
                        style: TextStyle(
                            color: s.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Text(s.timeAgo,
                        style: const TextStyle(
                            color: kSubtext, fontSize: 11)),
                  ]),
                )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// PULSING LIVE DOT
// ══════════════════════════════════════════
class _LiveDot extends StatefulWidget {
  final Color color;
  const _LiveDot({required this.color});
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);
  late final Animation<double> _anim =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.4 + 0.6 * _anim.value),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
              color: widget.color.withValues(alpha: 0.5 * _anim.value),
              blurRadius: 5, spreadRadius: 1)],
        ),
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

// ══════════════════════════════════════════
// SPARKLINE PAINTER (local to home_screen)
// ══════════════════════════════════════════
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool filled;
  final double strokeWidth;
  final bool showDot;

  const _SparklinePainter({
    required this.data,
    required this.color,
    this.filled = true,
    this.strokeWidth = 2.0,
    this.showDot = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce(math.min);
    final maxV = data.reduce(math.max);
    final range = (maxV - minV) == 0 ? 1.0 : maxV - minV;
    const vPad = 0.12;

    final pts = List.generate(data.length, (i) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height * (1 - vPad) -
          (data[i] - minV) / range * size.height * (1 - 2 * vPad);
      return Offset(x, y);
    });

    if (filled) {
      final fp = Path()
        ..moveTo(pts.first.dx, size.height)
        ..lineTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        final c1 = Offset((pts[i-1].dx + pts[i].dx)/2, pts[i-1].dy);
        final c2 = Offset((pts[i-1].dx + pts[i].dx)/2, pts[i].dy);
        fp.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, pts[i].dx, pts[i].dy);
      }
      fp..lineTo(pts.last.dx, size.height)..close();
      canvas.drawPath(fp, Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill);
    }

    final lp = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final c1 = Offset((pts[i-1].dx + pts[i].dx)/2, pts[i-1].dy);
      final c2 = Offset((pts[i-1].dx + pts[i].dx)/2, pts[i].dy);
      lp.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(lp, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round);

    if (showDot) {
      canvas.drawCircle(pts.last, strokeWidth + 1.5, Paint()..color = color);
      canvas.drawCircle(pts.last, strokeWidth - 0.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter o) =>
      o.data != data || o.color != color;
}