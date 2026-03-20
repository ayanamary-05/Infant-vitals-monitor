import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

const Color _bg      = Color(0xFF0F172A);
const Color _surface = Color(0xFF1E293B);
const Color _green   = Color(0xFF1DB954);
const Color _blue    = Color(0xFF4F8EF7);
const Color _orange  = Color(0xFFFFAB40);
const Color _red     = Color(0xFFFF6B6B);
const Color _subtext = Color(0xFF94A3B8);

class VitalsHistoryScreen extends StatefulWidget {
  const VitalsHistoryScreen({super.key});
  @override
  State<VitalsHistoryScreen> createState() => _VitalsHistoryScreenState();
}

class _VitalsHistoryScreenState extends State<VitalsHistoryScreen> {
  final _historyRef = FirebaseDatabase.instance.ref('vitals/history');

  List<FlSpot> _hrSpots   = [];
  List<FlSpot> _spo2Spots = [];
  List<FlSpot> _tempSpots = [];
  bool _loading = true;

  double _hrMin = 0, _hrMax = 0, _hrAvg = 0;
  double _spo2Min = 0, _spo2Max = 0, _spo2Avg = 0;
  double _tempMin = 0, _tempMax = 0, _tempAvg = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _historyRef.limitToLast(50).onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value == null) {
        setState(() => _loading = false); return;
      }
      final map =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      final entries = map.entries.toList();

      final List<FlSpot> hr = [], spo2 = [], temp = [];
      for (int i = 0; i < entries.length; i++) {
        final v =
            Map<String, dynamic>.from(entries[i].value as Map);
        hr.add(FlSpot(i.toDouble(),
            double.tryParse(v['heartRate'].toString()) ?? 0));
        spo2.add(FlSpot(i.toDouble(),
            double.tryParse(v['spo2'].toString()) ?? 0));
        temp.add(FlSpot(i.toDouble(),
            double.tryParse(v['temperature'].toString()) ?? 0));
      }

      double min(List<FlSpot> s) =>
          s.map((e) => e.y).reduce(math.min);
      double max(List<FlSpot> s) =>
          s.map((e) => e.y).reduce(math.max);
      double avg(List<FlSpot> s) =>
          s.map((e) => e.y).reduce((a, b) => a + b) / s.length;

      setState(() {
        _hrSpots = hr; _spo2Spots = spo2; _tempSpots = temp;
        if (hr.isNotEmpty) {
          _hrMin = min(hr); _hrMax = max(hr); _hrAvg = avg(hr);
        }
        if (spo2.isNotEmpty) {
          _spo2Min = min(spo2); _spo2Max = max(spo2);
          _spo2Avg = avg(spo2);
        }
        if (temp.isNotEmpty) {
          _tempMin = min(temp); _tempMax = max(temp);
          _tempAvg = avg(temp);
        }
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Vital History',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_green)))
          : _hrSpots.isEmpty
              ? const Center(
                  child: Text(
                      'No history yet.\nData appears once the sensor starts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _subtext, fontSize: 13)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _HistoryCard(
                      title: 'Heart Rate', unit: 'bpm',
                      color: _green,
                      icon: Icons.favorite_rounded,
                      normalRange: '120–160 bpm',
                      spots: _hrSpots,
                      minY: 60, maxY: 200,
                      statMin: _hrMin, statMax: _hrMax,
                      statAvg: _hrAvg, dp: 0,
                    ),
                    const SizedBox(height: 16),
                    _HistoryCard(
                      title: 'SpO₂', unit: '%',
                      color: _blue,
                      icon: Icons.water_drop_rounded,
                      normalRange: '95–100%',
                      spots: _spo2Spots,
                      minY: 85, maxY: 100,
                      statMin: _spo2Min, statMax: _spo2Max,
                      statAvg: _spo2Avg, dp: 1,
                    ),
                    const SizedBox(height: 16),
                    _HistoryCard(
                      title: 'Temperature', unit: '°C',
                      color: _orange,
                      icon: Icons.thermostat_rounded,
                      normalRange: '36.5–37.5°C',
                      spots: _tempSpots,
                      minY: 35, maxY: 40,
                      statMin: _tempMin, statMax: _tempMax,
                      statAvg: _tempAvg, dp: 1,
                    ),
                  ],
                ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title, unit, normalRange;
  final Color color;
  final IconData icon;
  final List<FlSpot> spots;
  final double minY, maxY;
  final double statMin, statMax, statAvg;
  final int dp;

  const _HistoryCard({
    required this.title,    required this.unit,
    required this.color,    required this.icon,
    required this.normalRange, required this.spots,
    required this.minY,     required this.maxY,
    required this.statMin,  required this.statMax,
    required this.statAvg,  required this.dp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  Text('Normal: $normalRange',
                      style: const TextStyle(
                          color: _subtext, fontSize: 11)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 22),
          SizedBox(
            height: 120,
            child: LineChart(LineChartData(
              minY: minY, maxY: maxY,
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white10, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, reservedSize: 36,
                    getTitlesWidget: (val, _) => Text(
                        val.toStringAsFixed(dp),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 9)),
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
                  spots: spots, isCurved: true,
                  color: color, barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.1)),
                ),
              ],
            )),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _StatChip(label: 'Min',
                value: statMin.toStringAsFixed(dp), color: _blue),
            const SizedBox(width: 8),
            _StatChip(label: 'Avg',
                value: statAvg.toStringAsFixed(dp), color: color),
            const SizedBox(width: 8),
            _StatChip(label: 'Max',
                value: statMax.toStringAsFixed(dp), color: _red),
          ]),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(label,
              style: const TextStyle(color: _subtext, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}