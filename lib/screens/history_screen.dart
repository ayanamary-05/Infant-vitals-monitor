import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Colour palette  (matches dark-theme app)
// ─────────────────────────────────────────────
const _bgPage      = Color(0xFF0F172A);
const _bgCard      = Color(0xFF1E293B);
const _bgChip      = Color(0xFF334155);
const _primary     = Color(0xFF3B82F6);
const _textMain    = Color(0xFFF1F5F9);
const _textSub     = Color(0xFF94A3B8);
const _divider     = Color(0xFF334155);
const _heartColor  = Color(0xFFFF6B8A);
const _tempColor   = Color(0xFFFBBF24);
const _spo2Color   = Color(0xFF38BDF8);
const _normalGreen = Color(0xFF4ADE80);
const _warnOrange  = Color(0xFFFB923C);
const _alertRed    = Color(0xFFF87171);

// ─────────────────────────────────────────────
//  Data model
// ─────────────────────────────────────────────
class VitalsRecord {
  final DateTime timestamp;
  final int heartRate;
  final double temperature;
  final int oxygenLevel;

  const VitalsRecord({
    required this.timestamp,
    required this.heartRate,
    required this.temperature,
    required this.oxygenLevel,
  });

  VitalStatus get overallStatus {
    if (_heartStatus == VitalStatus.alert ||
        _tempStatus  == VitalStatus.alert ||
        _spo2Status  == VitalStatus.alert) return VitalStatus.alert;
    if (_heartStatus == VitalStatus.warning ||
        _tempStatus  == VitalStatus.warning ||
        _spo2Status  == VitalStatus.warning) return VitalStatus.warning;
    return VitalStatus.normal;
  }

  VitalStatus get _heartStatus {
    if (heartRate < 90 || heartRate > 170) return VitalStatus.alert;
    if (heartRate < 100 || heartRate > 160) return VitalStatus.warning;
    return VitalStatus.normal;
  }

  VitalStatus get _tempStatus {
    if (temperature < 35.5 || temperature > 39.0) return VitalStatus.alert;
    if (temperature < 36.5 || temperature > 38.0) return VitalStatus.warning;
    return VitalStatus.normal;
  }

  VitalStatus get _spo2Status {
    if (oxygenLevel < 90) return VitalStatus.alert;
    if (oxygenLevel < 95) return VitalStatus.warning;
    return VitalStatus.normal;
  }
}

enum VitalStatus { normal, warning, alert }

// ─────────────────────────────────────────────
//  Static sample records
// ─────────────────────────────────────────────
final List<VitalsRecord> _sampleRecords = [
  VitalsRecord(timestamp: DateTime(2026, 3, 15, 14, 30), heartRate: 138, temperature: 37.2, oxygenLevel: 98),
  VitalsRecord(timestamp: DateTime(2026, 3, 15, 12, 00), heartRate: 145, temperature: 37.6, oxygenLevel: 97),
  VitalsRecord(timestamp: DateTime(2026, 3, 15,  9, 15), heartRate: 172, temperature: 38.4, oxygenLevel: 96),
  VitalsRecord(timestamp: DateTime(2026, 3, 15,  6, 45), heartRate: 129, temperature: 36.9, oxygenLevel: 99),
  VitalsRecord(timestamp: DateTime(2026, 3, 14, 22, 10), heartRate: 118, temperature: 37.1, oxygenLevel: 92),
  VitalsRecord(timestamp: DateTime(2026, 3, 14, 18, 55), heartRate: 142, temperature: 37.4, oxygenLevel: 98),
  VitalsRecord(timestamp: DateTime(2026, 3, 14, 15, 30), heartRate: 155, temperature: 38.8, oxygenLevel: 95),
  VitalsRecord(timestamp: DateTime(2026, 3, 14, 11, 00), heartRate: 133, temperature: 37.0, oxygenLevel: 97),
  VitalsRecord(timestamp: DateTime(2026, 3, 14,  7, 20), heartRate: 126, temperature: 36.7, oxygenLevel: 99),
  VitalsRecord(timestamp: DateTime(2026, 3, 13, 21, 45), heartRate: 86,  temperature: 35.2, oxygenLevel: 88),
  VitalsRecord(timestamp: DateTime(2026, 3, 13, 17, 30), heartRate: 140, temperature: 37.3, oxygenLevel: 98),
  VitalsRecord(timestamp: DateTime(2026, 3, 13, 13, 10), heartRate: 148, temperature: 37.7, oxygenLevel: 96),
];

// ─────────────────────────────────────────────
//  History Screen  ← safe as home: target
// ─────────────────────────────────────────────
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Map<String, List<VitalsRecord>> _groupByDate(List<VitalsRecord> records) {
    final Map<String, List<VitalsRecord>> grouped = {};
    final now = DateTime.now();
    for (final r in records) {
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day))
          .inDays;
      final label = diff == 0 ? 'Today' : diff == 1 ? 'Yesterday' : _formatDate(r.timestamp);
      grouped.putIfAbsent(label, () => []).add(r);
    }
    return grouped;
  }

  static String _formatDate(DateTime dt) =>
      '${_month(dt.month)} ${dt.day}, ${dt.year}';

  static String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(_sampleRecords);
    int normalCount = 0, warnCount = 0, alertCount = 0;
    for (final r in _sampleRecords) {
      switch (r.overallStatus) {
        case VitalStatus.normal:  normalCount++; break;
        case VitalStatus.warning: warnCount++;   break;
        case VitalStatus.alert:   alertCount++;  break;
      }
    }

    // Show back button only when pushed onto a stack, not as root
    final bool canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: _buildAppBar(context, canPop),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _SummaryStrip(
              total: _sampleRecords.length,
              normal: normalCount,
              warning: warnCount,
              alert: alertCount,
            ),
          ),
          SliverToBoxAdapter(child: _RangesBanner()),
          for (final entry in grouped.entries) ...[
            SliverToBoxAdapter(
              child: _DateGroupHeader(label: entry.key, count: entry.value.length),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => VitalsCard(record: entry.value[index]),
                childCount: entry.value.length,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool canPop) {
    return AppBar(
      backgroundColor: _bgCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: canPop,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: _textMain, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vitals History',
            style: TextStyle(
                color: _textMain, fontSize: 18,
                fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
          Text(
            'Baby Sarah · Last 3 days',
            style: TextStyle(color: _textSub, fontSize: 11),
          ),
        ],
      ),
      toolbarHeight: 64,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _bgChip,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.filter_list_rounded, color: _textSub, size: 18),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _divider),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Summary strip
// ─────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final int total, normal, warning, alert;
  const _SummaryStrip({
    required this.total, required this.normal,
    required this.warning, required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          _StripStat(value: '$total',   label: 'Total',   color: _primary),
          _Vbar(),
          _StripStat(value: '$normal',  label: 'Normal',  color: _normalGreen),
          _Vbar(),
          _StripStat(value: '$warning', label: 'Warning', color: _warnOrange),
          _Vbar(),
          _StripStat(value: '$alert',   label: 'Alert',   color: _alertRed),
        ],
      ),
    );
  }
}

class _StripStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StripStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: _textSub)),
      ],
    ),
  );
}

class _Vbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: _divider);
}

// ─────────────────────────────────────────────
//  Ranges banner
// ─────────────────────────────────────────────
class _RangesBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: _primary),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 11, color: _textSub, height: 1.5),
                children: [
                  TextSpan(
                    text: 'Normal ranges:  ',
                    style: TextStyle(color: _textMain, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: '❤ 100–160 BPM   '),
                  TextSpan(text: '🌡 36.5–38 °C   '),
                  TextSpan(text: '💧 95–100 %'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Date-group header
// ─────────────────────────────────────────────
class _DateGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  const _DateGroupHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: _textMain, fontSize: 14,
                  fontWeight: FontWeight.w700, letterSpacing: 0.2)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: _bgChip, borderRadius: BorderRadius.circular(20)),
            child: Text('$count readings',
                style: const TextStyle(fontSize: 10, color: _textSub)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Vitals Card
// ─────────────────────────────────────────────
class VitalsCard extends StatelessWidget {
  final VitalsRecord record;
  const VitalsCard({super.key, required this.record});

  static Color _statusColor(VitalStatus s) {
    switch (s) {
      case VitalStatus.normal:  return _normalGreen;
      case VitalStatus.warning: return _warnOrange;
      case VitalStatus.alert:   return _alertRed;
    }
  }

  static String _statusLabel(VitalStatus s) {
    switch (s) {
      case VitalStatus.normal:  return 'Normal';
      case VitalStatus.warning: return 'Warning';
      case VitalStatus.alert:   return 'Alert';
    }
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(record.overallStatus);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: _textSub),
                const SizedBox(width: 5),
                Text(_formatTime(record.timestamp),
                    style: const TextStyle(fontSize: 13, color: _textSub, fontWeight: FontWeight.w500)),
                const Spacer(),
                _StatusBadge(
                    label: _statusLabel(record.overallStatus),
                    color: statusColor),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: _divider, height: 1, indent: 14, endIndent: 14),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
            child: Row(
              children: [
                _VitalCell(
                  icon: Icons.favorite_rounded, iconColor: _heartColor,
                  label: 'Heart Rate', value: '${record.heartRate}', unit: 'BPM',
                  vitalValue: record.heartRate.toDouble(), min: 100, max: 160,
                ),
                _VerticalDivider(),
                _VitalCell(
                  icon: Icons.thermostat_rounded, iconColor: _tempColor,
                  label: 'Temperature',
                  value: record.temperature.toStringAsFixed(1), unit: '°C',
                  vitalValue: record.temperature, min: 36.5, max: 38.0,
                ),
                _VerticalDivider(),
                _VitalCell(
                  icon: Icons.water_drop_rounded, iconColor: _spo2Color,
                  label: 'SpO₂', value: '${record.oxygenLevel}', unit: '%',
                  vitalValue: record.oxygenLevel.toDouble(), min: 95, max: 100,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Status badge
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color,
                  fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Vital cell
// ─────────────────────────────────────────────
class _VitalCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value, unit;
  final double vitalValue, min, max;

  const _VitalCell({
    required this.icon, required this.iconColor,
    required this.label, required this.value, required this.unit,
    required this.vitalValue, required this.min, required this.max,
  });

  bool get _isOutOfRange => vitalValue < min || vitalValue > max;

  @override
  Widget build(BuildContext context) {
    final valueColor = _isOutOfRange
        ? (vitalValue < min * 0.95 || vitalValue > max * 1.06 ? _alertRed : _warnOrange)
        : _textMain;
    final progress =
        ((vitalValue - (min * 0.85)) / ((max * 1.15) - (min * 0.85))).clamp(0.0, 1.0);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800,
                      color: valueColor, letterSpacing: -0.5)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit,
                    style: const TextStyle(
                        fontSize: 10, color: _textSub, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: _textSub)),
          const SizedBox(height: 7),
          _MiniRangeBar(progress: progress, color: iconColor, outOfRange: _isOutOfRange),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Mini range bar
// ─────────────────────────────────────────────
class _MiniRangeBar extends StatelessWidget {
  final double progress;
  final Color color;
  final bool outOfRange;
  const _MiniRangeBar({required this.progress, required this.color, required this.outOfRange});

  @override
  Widget build(BuildContext context) {
    final barColor = outOfRange ? _warnOrange : color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Stack(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(color: _divider, borderRadius: BorderRadius.circular(2)),
          ),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: 4,
              decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Vertical divider between cells
// ─────────────────────────────────────────────
class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 80,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: _divider,
  );
}