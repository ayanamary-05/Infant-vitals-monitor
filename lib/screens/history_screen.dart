import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const Color _bg       = Color(0xFF0F172A);
const Color _surface  = Color(0xFF1E293B);
const Color _primary  = Color(0xFF4F8EF7);
const Color _textMain = Color(0xFFF1F5F9);
const Color _textSub  = Color(0xFF94A3B8);
const Color _border   = Color(0xFF334155);

// ── Vital tab definition ────────────────────────────────────────────────────
class _VitalTab {
  final String label;
  final String firebaseKey;
  final Color  color;
  final double minY;
  final double maxY;
  final String unit;

  const _VitalTab({
    required this.label,
    required this.firebaseKey,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.unit,
  });
}

const _tabs = [
  _VitalTab(
    label: 'Heart Rate', firebaseKey: 'heartRate',
    color: Color(0xFFEF4444), minY: 0, maxY: 180, unit: 'bpm',
  ),
  _VitalTab(
    label: 'Temperature', firebaseKey: 'temperature',
    color: Color(0xFFF59E0B), minY: 35, maxY: 40, unit: '°C',
  ),
  _VitalTab(
    label: 'SpO2', firebaseKey: 'spo2',
    color: Color(0xFF3B82F6), minY: 85, maxY: 100, unit: '%',
  ),
];

// ── Screen ──────────────────────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedTab = 0;
  List<FlSpot> _spots = [];
  bool _loading = true;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() { _loading = true; _spots = []; _touchedIndex = null; });
    FirebaseDatabase.instance
        .ref('vitals/history')
        .limitToLast(24)
        .onValue
        .listen((event) {
      if (!mounted) return;
      if (event.snapshot.value == null) {
        setState(() => _loading = false);
        return;
      }
      final map = Map<String, dynamic>.from(event.snapshot.value as Map);
      final entries = map.entries.toList();
      final key = _tabs[_selectedTab].firebaseKey;
      final spots = <FlSpot>[];
      for (int i = 0; i < entries.length; i++) {
        final v = Map<String, dynamic>.from(entries[i].value as Map);
        final val = double.tryParse(v[key]?.toString() ?? '') ?? 0;
        spots.add(FlSpot(i.toDouble(), val));
      }
      setState(() { _spots = spots; _loading = false; });
    });
  }

  // Use demo data if Firebase has no data yet
  List<FlSpot> get _displaySpots {
    if (_spots.isNotEmpty) return _spots;
    final t = _tabs[_selectedTab];
    final rng = math.Random(42 + _selectedTab);
    final mid = (t.minY + t.maxY) / 2;
    final spread = (t.maxY - t.minY) * 0.15;
    return List.generate(24, (i) =>
        FlSpot(i.toDouble(), mid + (rng.nextDouble() - 0.5) * 2 * spread));
  }

  // Stats
  double get _min => _displaySpots.map((s) => s.y).reduce(math.min);
  double get _max => _displaySpots.map((s) => s.y).reduce(math.max);
  double get _avg =>
      _displaySpots.map((s) => s.y).reduce((a, b) => a + b) /
      _displaySpots.length;

  bool get _isTemp => _selectedTab == 1;
  int get _dp => _isTemp ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_selectedTab];
    final spots = _displaySpots;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text(
          'Vitals History',
          style: TextStyle(
            color: _textMain,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tab selector ───────────────────────
            const SizedBox(height: 4),
            _TabSelector(
              tabs: _tabs.map((t) => t.label).toList(),
              selected: _selectedTab,
              activeColor: tab.color,
              onTap: (i) {
                if (i == _selectedTab) return;
                setState(() => _selectedTab = i);
                _loadData();
              },
            ),
            const SizedBox(height: 20),

            // ── Chart card ─────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      'Last 24 Hours',
                      style: TextStyle(
                        color: _textSub,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 220,
                    child: _loading
                        ? Center(
                            child: CircularProgressIndicator(
                                color: tab.color, strokeWidth: 2))
                        : LineChart(
                            _buildChartData(spots, tab),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats row ──────────────────────────
            Row(children: [
              _StatCard(label: 'Min',  value: _min.toStringAsFixed(_dp), color: _primary),
              const SizedBox(width: 12),
              _StatCard(label: 'Avg',  value: _avg.toStringAsFixed(_dp), color: tab.color),
              const SizedBox(width: 12),
              _StatCard(label: 'Max',  value: _max.toStringAsFixed(_dp), color: const Color(0xFFEF4444)),
            ]),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(List<FlSpot> spots, _VitalTab tab) {
    return LineChartData(
      minY: tab.minY,
      maxY: tab.maxY,
      clipData: const FlClipData.all(),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF1E293B),
          tooltipBorder: BorderSide(color: _border),
          tooltipRoundedRadius: 10,
          getTooltipItems: (spots) => spots.map((s) {
            final idx = s.x.toInt();
            final now = DateTime.now();
            final startHour = (now.hour - 23 + 24) % 24;
            final hour = (startHour + idx) % 24;
            final timeLabel = '$hour:00';
            return LineTooltipItem(
              '$timeLabel\n',
              const TextStyle(color: _textSub, fontSize: 11),
              children: [
                TextSpan(
                  text: 'value : ${s.y.toStringAsFixed(_dp)}',
                  style: TextStyle(
                    color: tab.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (data, indices) =>
            indices.map((i) => TouchedSpotIndicatorData(
              FlLine(color: tab.color.withValues(alpha: 0.3), strokeWidth: 1,
                  dashArray: [4, 4]),
              FlDotData(
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 5,
                  color: tab.color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
            )).toList(),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (tab.maxY - tab.minY) / 4,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: Color(0xFF334155), strokeWidth: 0.8),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: (tab.maxY - tab.minY) / 4,
            getTitlesWidget: (val, _) => Text(
              val.toStringAsFixed(_dp),
              style: const TextStyle(color: _textSub, fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 3,
            getTitlesWidget: (val, _) {
              final idx = val.toInt();
              if (idx % 3 != 0) return const SizedBox.shrink();
              // Map index 0..23 to real clock hours starting 1 hour ago
              final now = DateTime.now();
              final startHour = (now.hour - 23 + 24) % 24;
              final hour = (startHour + idx) % 24;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '$hour:00',
                  style: const TextStyle(color: _textSub, fontSize: 10),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: tab.color,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tab.color.withValues(alpha: 0.18),
                tab.color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab selector widget ─────────────────────────────────────────────────────
class _TabSelector extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final Color activeColor;
  final ValueChanged<int> onTap;

  const _TabSelector({
    required this.tabs,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabs.length, (i) {
        final isActive = i == selected;
        return Padding(
          padding: EdgeInsets.only(right: i < tabs.length - 1 ? 10 : 0),
          child: GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: isActive ? activeColor : _surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isActive ? activeColor : _border,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  color: isActive ? Colors.white : _textSub,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Stat card widget ────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: _textSub, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: _textMain,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}