import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  final _vitalsRef = FirebaseDatabase.instance.ref('vitals/latest');
  final _alertRef  = FirebaseDatabase.instance.ref('alerts');
  final _historyRef = FirebaseDatabase.instance.ref('vitals/history');

  // Current readings
  double _heartRate   = 0;
  double _spo2        = 0;
  double _temperature = 0;
  String _lastUpdated = '--';
  bool   _alertActive = false;
  String _alertMessage = '';

  // Chart data
  final List<FlSpot> _hrSpots   = [];
  final List<FlSpot> _spo2Spots = [];
  final List<FlSpot> _tempSpots = [];

  @override
  void initState() {
    super.initState();
    _listenVitals();
    _listenAlerts();
    _loadHistory();
  }

  void _listenVitals() {
    _vitalsRef.onValue.listen((event) {
      if (event.snapshot.value == null) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      setState(() {
        _heartRate   = double.tryParse(data['heartRate'].toString())   ?? 0;
        _spo2        = double.tryParse(data['spo2'].toString())        ?? 0;
        _temperature = double.tryParse(data['temperature'].toString()) ?? 0;
        _lastUpdated = DateFormat('hh:mm:ss a').format(DateTime.now());
      });
    });
  }

  void _listenAlerts() {
    _alertRef.onValue.listen((event) {
      if (event.snapshot.value == null) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      setState(() {
        _alertActive  = data['active'] == true;
        _alertMessage = data['message']?.toString() ?? '';
      });
    });
  }

  void _loadHistory() {
    _historyRef.limitToLast(20).onValue.listen((event) {
      if (event.snapshot.value == null) return;
      final map = Map<String, dynamic>.from(event.snapshot.value as Map);

      final entries = map.entries.toList();
      setState(() {
        _hrSpots.clear();
        _spo2Spots.clear();
        _tempSpots.clear();

        for (int i = 0; i < entries.length; i++) {
          final v = Map<String, dynamic>.from(entries[i].value as Map);
          _hrSpots.add(FlSpot(i.toDouble(),
              double.tryParse(v['heartRate'].toString()) ?? 0));
          _spo2Spots.add(FlSpot(i.toDouble(),
              double.tryParse(v['spo2'].toString()) ?? 0));
          _tempSpots.add(FlSpot(i.toDouble(),
              double.tryParse(v['temperature'].toString()) ?? 0));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.monitor_heart, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('Infant Vitals Monitor',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Updated: $_lastUpdated',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Alert Banner ──────────────────────────────────────────
            if (_alertActive)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.redAccent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _alertMessage,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Vital Cards ───────────────────────────────────────────
            _VitalCard(
              label: 'Heart Rate',
              value: _heartRate == 0 ? '--' : _heartRate.toStringAsFixed(0),
              unit: 'BPM',
              icon: Icons.favorite,
              color: const Color(0xFFEF4444),
              normalRange: '100 – 160 BPM',
              isAlert: _heartRate > 0 &&
                  (_heartRate < 100 || _heartRate > 160),
            ),
            const SizedBox(height: 12),
            _VitalCard(
              label: 'SpO2',
              value: _spo2 == 0 ? '--' : _spo2.toStringAsFixed(1),
              unit: '%',
              icon: Icons.water_drop,
              color: const Color(0xFF3B82F6),
              normalRange: '95 – 100%',
              isAlert: _spo2 > 0 && _spo2 < 95,
            ),
            const SizedBox(height: 12),
            _VitalCard(
              label: 'Temperature',
              value: _temperature == 0
                  ? '--'
                  : _temperature.toStringAsFixed(1),
              unit: '°C',
              icon: Icons.thermostat,
              color: const Color(0xFFF59E0B),
              normalRange: '36.5 – 37.5 °C',
              isAlert: _temperature > 0 &&
                  (_temperature < 36.5 || _temperature > 37.5),
            ),

            // ── History Charts ────────────────────────────────────────
            const SizedBox(height: 28),
            const Text('History (last 20 readings)',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            if (_hrSpots.isNotEmpty) ...[
              _ChartCard(
                title: 'Heart Rate',
                spots: _hrSpots,
                color: const Color(0xFFEF4444),
                minY: 60,
                maxY: 200,
                unit: 'BPM',
              ),
              const SizedBox(height: 14),
              _ChartCard(
                title: 'SpO2',
                spots: _spo2Spots,
                color: const Color(0xFF3B82F6),
                minY: 85,
                maxY: 100,
                unit: '%',
              ),
              const SizedBox(height: 14),
              _ChartCard(
                title: 'Temperature',
                spots: _tempSpots,
                color: const Color(0xFFF59E0B),
                minY: 35,
                maxY: 40,
                unit: '°C',
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No history yet.\nData will appear once the sensor starts sending.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Vital Card Widget ────────────────────────────────────────────────────────

class _VitalCard extends StatelessWidget {
  final String label, value, unit, normalRange;
  final IconData icon;
  final Color color;
  final bool isAlert;

  const _VitalCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.normalRange,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert ? Colors.redAccent : color.withValues(alpha: 0.3),
          width: isAlert ? 1.5 : 1,
        ),
        boxShadow: isAlert
            ? [BoxShadow(color: Colors.red.withValues(alpha: 0.2), blurRadius: 12)]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value,
                        style: TextStyle(
                            color: isAlert ? Colors.redAccent : color,
                            fontSize: 36,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(unit,
                          style: TextStyle(
                              color: isAlert
                                  ? Colors.redAccent
                                  : color.withValues(alpha: 0.7),
                              fontSize: 14)),
                    ),
                  ],
                ),
                Text('Normal: $normalRange',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          if (isAlert)
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 22),
        ],
      ),
    );
  }
}

// ── Chart Card Widget ────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title, unit;
  final List<FlSpot> spots;
  final Color color;
  final double minY, maxY;

  const _ChartCard({
    required this.title,
    required this.spots,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (val, _) => Text(
                        val.toStringAsFixed(0),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
