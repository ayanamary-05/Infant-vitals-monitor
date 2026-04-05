import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:first_app/main.dart' show alertCountNotifier, criticalAlertNotifier;

// ── Simulated vitals state ──────────────────────────────────────────────────
class VitalsState {
  final double hr, temp, spo2;
  final double prevHr, prevTemp, prevSpo2;
  final DateTime lastUpdated;

  const VitalsState({
    this.hr = 132.0,
    this.temp = 37.2,
    this.spo2 = 97.0,
    this.prevHr = 132.0,
    this.prevTemp = 37.2,
    this.prevSpo2 = 97.0,
    required this.lastUpdated,
  });
}

// ── Alert listeners (shared between home and alerts screens) ────────────────
final List<void Function(double hr, double temp, double spo2)> alertListeners = [];

// ── Global vitals notifier ──────────────────────────────────────────────────
final vitalsNotifier = ValueNotifier<VitalsState>(
  VitalsState(lastUpdated: DateTime.now()),
);

// ── Critical vitals notifier — list of out-of-range vital names ─────────────
// e.g. ['Heart Rate', 'SpO₂'] when those two are critical
final criticalVitalsNotifier = ValueNotifier<List<String>>([]);

Timer? _vitalsTimer;

void startVitalsSimulation(int intervalSeconds) {
  _vitalsTimer?.cancel();
  final rng = math.Random();
  _vitalsTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
    // Pause simulation while the critical alert overlay is visible
    if (criticalAlertNotifier.value) return;

    final current = vitalsNotifier.value;
    final newHr   = (current.hr   + (rng.nextDouble() - 0.48) * 4).clamp(80.0, 190.0);
    final newTemp = (current.temp + (rng.nextDouble() - 0.48) * 0.1).clamp(35.0, 41.0);
    final newSpo2 = (current.spo2 + (rng.nextDouble() - 0.48) * 1).clamp(82.0, 100.0);

    vitalsNotifier.value = VitalsState(
      hr: newHr, temp: newTemp, spo2: newSpo2,
      prevHr: current.hr, prevTemp: current.temp, prevSpo2: current.spo2,
      lastUpdated: DateTime.now(),
    );

    _checkAlerts(newHr, newTemp, newSpo2);
  });
}

void stopVitalsSimulation() => _vitalsTimer?.cancel();

void _checkAlerts(double hr, double temp, double spo2) {
  // Build list of out-of-range vital names
  final List<String> critical = [];
  if (hr > 160 || hr < 100) critical.add('Heart Rate');
  if (temp > 38.0)           critical.add('Body Temperature');
  if (spo2 < 94)             critical.add('SpO₂');

  alertCountNotifier.value = critical.length;

  // Only raise the critical notifier when new critical vitals appear
  // (don't overwrite if already showing — the overlay reads the latest vitalsNotifier)
  if (critical.isNotEmpty) {
    criticalVitalsNotifier.value = critical;
  }

  // Log to database for admin analytics
  if (critical.isNotEmpty) {
    _logAlertToFirebase(critical.join(', '));
  }

  for (final fn in List.of(alertListeners)) {
    fn(hr, temp, spo2);
  }
}

void _logAlertToFirebase(String vitalNames) async {
  final ref = FirebaseDatabase.instance.ref();
  final timestamp = ServerValue.timestamp;
  
  // Push to alerts history
  await ref.child('alerts').push().set({
    'type': 'Critical Threshold',
    'message': 'Alert triggered for: $vitalNames',
    'severity': 'critical',
    'timestamp': timestamp,
    'status': 'active',
  });

  // Push to general activity log
  await ref.child('history').push().set({
    'type': 'alert',
    'message': 'CRITICAL ALERT: $vitalNames threshold exceeded',
    'timestamp': timestamp,
  });
}
