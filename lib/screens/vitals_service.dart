import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:first_app/main.dart' show alertCountNotifier, criticalAlertNotifier, localNotificationsPlugin, kCriticalChannel;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

// ── Vitals state ─────────────────────────────────────────────────────────────
class VitalsState {
  final double hr, temp, spo2;
  final double prevHr, prevTemp, prevSpo2;
  final DateTime lastUpdated;

  const VitalsState({
    this.hr = 0.0,
    this.temp = 0.0,
    this.spo2 = 0.0,
    this.prevHr = 0.0,
    this.prevTemp = 0.0,
    this.prevSpo2 = 0.0,
    required this.lastUpdated,
  });
}

// ── Alert listeners (shared between home and alerts screens) ─────────────────
final List<void Function(double hr, double temp, double spo2)> alertListeners = [];

// ── Global vitals notifier ───────────────────────────────────────────────────
final vitalsNotifier = ValueNotifier<VitalsState>(
  VitalsState(lastUpdated: DateTime.now()),
);

// ── Critical vitals notifier ─────────────────────────────────────────────────
final criticalVitalsNotifier = ValueNotifier<List<String>>([]);

// ── Firebase listener ────────────────────────────────────────────────────────
StreamSubscription<DatabaseEvent>? _vitalsSubscription;

/// Connects to Firebase Realtime Database and streams live vitals.
/// [intervalSeconds] is kept for API compatibility but ignored — Firebase
/// pushes updates whenever the sensor writes new data.
void startVitalsListener(int intervalSeconds) {
  _vitalsSubscription?.cancel();

  final vitalsRef = FirebaseDatabase.instance.ref('vitals/current');

  _vitalsSubscription = vitalsRef.onValue.listen(
    (event) {
      // Pause updates while the critical alert overlay is visible
      if (criticalAlertNotifier.value) return;

      final raw = event.snapshot.value;
      if (raw == null) {
        debugPrint('[VitalsService] vitals/current is null — no sensor data yet');
        return;
      }

      final Map<String, dynamic> data;
      try {
        data = Map<String, dynamic>.from(raw as Map);
      } catch (e) {
        debugPrint('[VitalsService] Unexpected data format: $raw ($e)');
        return;
      }

      final current = vitalsNotifier.value;

      final newHr   = double.tryParse(data['heartRate'].toString())   ?? current.hr;
      final newTemp = double.tryParse(data['temperature'].toString())  ?? current.temp;
      final newSpo2 = double.tryParse(data['spo2'].toString())         ?? current.spo2;

      debugPrint('[VitalsService] HR=$newHr  Temp=$newTemp  SpO2=$newSpo2');

      vitalsNotifier.value = VitalsState(
        hr: newHr,     temp: newTemp,     spo2: newSpo2,
        prevHr: current.hr, prevTemp: current.temp, prevSpo2: current.spo2,
        lastUpdated: DateTime.now(),
      );

      _checkAlerts(newHr, newTemp, newSpo2);
    },
    onError: (error) {
      debugPrint('[VitalsService] Firebase error: $error');
      debugPrint('[VitalsService] Check Firebase Realtime Database rules — '
          'ensure "vitals/current" is readable. '
          'Rules should allow: ".read": true  (or require auth and ensure user is logged in)');
    },
  );
}

void stopVitalsListener() => _vitalsSubscription?.cancel();

void _checkAlerts(double hr, double temp, double spo2) {
  final List<String> critical = [];
  // ALL VITAS ALARM: Triggers for ANY out-of-normal vital sign
  if (hr > 0 && (hr > 160 || hr < 100))     critical.add('Heart Rate');
  if (temp > 0 && temp > 37.8)            critical.add('Body Temperature');
  if (spo2 > 0 && (spo2 < 94 && spo2 > 0)) critical.add('SpO₂');

  alertCountNotifier.value = critical.length;

  if (critical.isNotEmpty) {
    _triggerSystemNotification(critical);
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

void _triggerSystemNotification(List<String> items) async {
  if (criticalAlertNotifier.value) return;

  final String body = 'Urgent Alarm: ${items.join(', ')}';
  
  const androidDetails = AndroidNotificationDetails(
    'critical_vitals_alarm',
    'Infant Vitals Alarm',
    channelDescription: 'Persistent alarm for infant monitor.',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'Emergency Alarm',
    fullScreenIntent: true,
    ongoing: true, // Requires user interaction to clear
    autoCancel: false,
    color: Color(0xFFFF0000),
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
  );

  const notificationDetails = NotificationDetails(android: androidDetails);

  await localNotificationsPlugin.show(
    0, // Constant ID for the alarm
    '🚨 BABY MONITOR ALARM',
    body,
    notificationDetails,
  );

  // FORCE ACTIVITY TO FRONT
  const platform = MethodChannel('com.example.first_app/foreground');
  try {
    await platform.invokeMethod('showAlarmWindow');
  } on PlatformException catch (e) {
    debugPrint("[VitalsService] Failed to jump to foreground: ${e.message}");
  }
}
