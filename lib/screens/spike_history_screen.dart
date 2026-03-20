import 'package:flutter/material.dart';
import 'package:first_app/screens/vital_models.dart';

const Color _bg      = Color(0xFF0F172A);
const Color _surface = Color(0xFF1E293B);
const Color _green   = Color(0xFF1DB954);
const Color _blue    = Color(0xFF4F8EF7);
const Color _orange  = Color(0xFFFFAB40);
const Color _red     = Color(0xFFFF6B6B);
const Color _subtext = Color(0xFF94A3B8);

class SpikeHistoryScreen extends StatelessWidget {
  const SpikeHistoryScreen({super.key});

  // TODO: Replace with Firestore/RTDB query once spikes are stored
  static final List<SpikeAlert> _all = [
    SpikeAlert(vitalName: 'Heart Rate',  value: 172,  unit: 'bpm',    timestamp: DateTime.now().subtract(const Duration(hours: 2,  minutes: 14)), color: _green,  isHigh: true),
    SpikeAlert(vitalName: 'SpO₂',        value: 91.2, unit: '%',      timestamp: DateTime.now().subtract(const Duration(hours: 5,  minutes: 33)), color: _blue,   isHigh: false),
    SpikeAlert(vitalName: 'Temperature', value: 38.2, unit: '°C',     timestamp: DateTime.now().subtract(const Duration(days: 1,  hours: 1)),     color: _orange, isHigh: true),
    SpikeAlert(vitalName: 'Heart Rate',  value: 168,  unit: 'bpm',    timestamp: DateTime.now().subtract(const Duration(days: 1,  hours: 8)),     color: _green,  isHigh: true),
    SpikeAlert(vitalName: 'SpO₂',        value: 92.5, unit: '%',      timestamp: DateTime.now().subtract(const Duration(days: 2,  hours: 11)),    color: _blue,   isHigh: false),
    SpikeAlert(vitalName: 'Temperature', value: 37.9, unit: '°C',     timestamp: DateTime.now().subtract(const Duration(days: 3,  hours: 2)),     color: _orange, isHigh: true),
    SpikeAlert(vitalName: 'Heart Rate',  value: 174,  unit: 'bpm',    timestamp: DateTime.now().subtract(const Duration(days: 4,  hours: 5)),     color: _green,  isHigh: true),
    SpikeAlert(vitalName: 'SpO₂',        value: 90.1, unit: '%',      timestamp: DateTime.now().subtract(const Duration(days: 5,  hours: 9)),     color: _blue,   isHigh: false),
  ];

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
        title: const Text('Spike Alerts',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: _red, size: 13),
                const SizedBox(width: 4),
                Text('${_all.length} alerts',
                    style: const TextStyle(
                        color: _red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      ),
      body: _all.isEmpty
          ? const Center(
              child: Text('No alerts recorded.',
                  style: TextStyle(color: _subtext, fontSize: 14)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              physics: const BouncingScrollPhysics(),
              itemCount: _all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final s = _all[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: s.color.withValues(alpha: 0.18)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: s.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(
                          s.isHigh
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: s.color, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.vitalName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(s.fullTime,
                              style: const TextStyle(
                                  color: _subtext, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(s.formattedValue,
                            style: TextStyle(
                                color: s.color,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: s.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(s.severity,
                              style: TextStyle(
                                  color: s.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ]),
                );
              },
            ),
    );
  }
}