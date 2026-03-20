import 'package:flutter/material.dart';

class VitalReading {
  final String name;
  final String unit;
  final double current;
  final double displayMin;
  final double displayMax;
  final List<double> history;
  final Color color;
  final IconData icon;
  final String normalRange;
  final int decimalPlaces;

  const VitalReading({
    required this.name,
    required this.unit,
    required this.current,
    required this.displayMin,
    required this.displayMax,
    required this.history,
    required this.color,
    required this.icon,
    required this.normalRange,
    this.decimalPlaces = 0,
  });

  String get formattedCurrent =>
      current.toStringAsFixed(decimalPlaces);

  VitalReading copyWith({double? current, List<double>? history}) =>
      VitalReading(
        name: name, unit: unit,
        current: current ?? this.current,
        displayMin: displayMin, displayMax: displayMax,
        history: history ?? this.history,
        color: color, icon: icon,
        normalRange: normalRange, decimalPlaces: decimalPlaces,
      );
}

class SpikeAlert {
  final String vitalName;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Color color;
  final bool isHigh;

  const SpikeAlert({
    required this.vitalName,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.color,
    required this.isHigh,
  });

  String get formattedValue =>
      '${value.toStringAsFixed(1)} $unit';
  String get severity => isHigh ? '↑ High' : '↓ Low';

  String get timeAgo {
    final d = DateTime.now().difference(timestamp);
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    return '${d.inMinutes}m ago';
  }

  String get fullTime {
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '${days[timestamp.weekday - 1]} '
        '${timestamp.day}/${timestamp.month}  $h:$m';
  }
}