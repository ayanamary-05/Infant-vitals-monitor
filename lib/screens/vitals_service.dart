import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:first_app/main.dart' show alertCountNotifier;

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

Timer? _vitalsTimer;

void startVitalsSimulation(int intervalSeconds) {
  _vitalsTimer?.cancel();
  final rng = math.Random();
  _vitalsTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
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
  int count = 0;
  if (hr > 160 || hr < 100) count++;
  if (temp > 38.0) count++;
  if (spo2 < 94) count++;
  alertCountNotifier.value = count;
  for (final fn in List.of(alertListeners)) {
    fn(hr, temp, spo2);
  }
}
