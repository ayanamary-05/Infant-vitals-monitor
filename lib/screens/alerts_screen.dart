import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:first_app/screens/theme_ext.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/screens/vitals_service.dart';
import 'package:first_app/screens/app_strings.dart';
import 'package:first_app/main.dart' show tempUnitNotifier, languageNotifier;

// ── Palette ───────────────────────────────────────────────────────────────



const Color _red      = Color(0xFFFF6B6B);
const Color _orange   = Color(0xFFFFAB40);
const Color _green    = Color(0xFF1DB954);

// ── Alert model ───────────────────────────────────────────────────────────
enum AlertSeverity { warning, critical }

class VitalAlert {
  final String id;
  final String vitalName;
  final String value;
  final AlertSeverity severity;
  final DateTime triggeredAt;
  final String thresholdLabel;
  bool dismissed;

  VitalAlert({
    required this.id,
    required this.vitalName,
    required this.value,
    required this.severity,
    required this.triggeredAt,
    required this.thresholdLabel,
    this.dismissed = false,
  });
}

// ── Custom thresholds model ────────────────────────────────────────────────
class _AlertThresholds {
  double hrMin = 100;
  double hrMax = 160;
  double tempMax = 38.0;
  double spo2Min = 94;
}

// ── AlertsScreen ──────────────────────────────────────────────────────────
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<VitalAlert> _active   = [];
  final List<VitalAlert> _resolved = [];
  int _alertIdCounter = 0;
  DateTime? _lastAlertTime;
  final _thresholds = _AlertThresholds();

  // Track last known severity to avoid duplicate alerts
  String? _lastHrAlertKey;
  String? _lastTempAlertKey;
  String? _lastSpo2AlertKey;

  @override
  void initState() {
    super.initState();
    _loadThresholds();
    alertListeners.add(_onVitals);
    // Seed with initial vitals check
    final v = vitalsNotifier.value;
    _onVitals(v.hr, v.temp, v.spo2);
    languageNotifier.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    alertListeners.remove(_onVitals);
    languageNotifier.removeListener(_rebuild);
    super.dispose();
  }

  Future<void> _loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _thresholds.hrMin   = prefs.getDouble('t_hrMin')   ?? 100;
        _thresholds.hrMax   = prefs.getDouble('t_hrMax')   ?? 160;
        _thresholds.tempMax = prefs.getDouble('t_tempMax') ?? 38.0;
        _thresholds.spo2Min = prefs.getDouble('t_spo2Min') ?? 94;
      });
    }
  }

  Future<void> _saveThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('t_hrMin',   _thresholds.hrMin);
    await prefs.setDouble('t_hrMax',   _thresholds.hrMax);
    await prefs.setDouble('t_tempMax', _thresholds.tempMax);
    await prefs.setDouble('t_spo2Min', _thresholds.spo2Min);
  }

  void _onVitals(double hr, double temp, double spo2) {
    if (!mounted) return;

    final isFahrenheit = tempUnitNotifier.value == 'Fahrenheit';
    final displayTemp  = isFahrenheit ? temp * 9 / 5 + 32 : temp;
    final tempUnit     = isFahrenheit ? '°F' : '°C';
    final criticalTempThreshold = isFahrenheit ? 101.3 : 38.5;

    setState(() {
      // ── Heart Rate ──────────────────────────
      String hrKey = '';
      if (hr > 0) {
        if (hr > _thresholds.hrMax * 1.06 || hr < _thresholds.hrMin * 0.94) {
          hrKey = 'critical';
        } else if (hr > _thresholds.hrMax || hr < _thresholds.hrMin) {
          hrKey = 'warning';
        }

        if (hrKey.isNotEmpty && hrKey != _lastHrAlertKey) {
          _lastHrAlertKey = hrKey;
          _lastAlertTime = DateTime.now();
          final threshold = hrKey == 'critical'
              ? '${AppStrings.t('hr_max')} > ${(_thresholds.hrMax * 1.06).toStringAsFixed(0)} BPM'
              : '${AppStrings.t('hr_max')} > ${_thresholds.hrMax.toStringAsFixed(0)} BPM';
          _active.insert(0, VitalAlert(
            id: 'alert_${_alertIdCounter++}',
            vitalName: AppStrings.t('heart_rate'),
            value: '${hr.toStringAsFixed(0)} BPM',
            severity: hrKey == 'critical' ? AlertSeverity.critical : AlertSeverity.warning,
            triggeredAt: DateTime.now(),
            thresholdLabel: threshold,
          ));
        } else if (hrKey.isEmpty) {
          _lastHrAlertKey = null;
        }
      }

      // ── Temperature ─────────────────────────
      String tempKey = '';
      if (temp > 0) {
        if (displayTemp > criticalTempThreshold) {
          tempKey = 'critical';
        } else if (displayTemp > _thresholds.tempMax) {
          tempKey = 'warning';
        }

        if (tempKey.isNotEmpty && tempKey != _lastTempAlertKey) {
          _lastTempAlertKey = tempKey;
          _lastAlertTime = DateTime.now();
          final thr = isFahrenheit
              ? '${_thresholds.tempMax * 9 / 5 + 32} °F'
              : '${_thresholds.tempMax} °C';
          _active.insert(0, VitalAlert(
            id: 'alert_${_alertIdCounter++}',
            vitalName: AppStrings.t('body_temperature'),
            value: '${displayTemp.toStringAsFixed(1)}$tempUnit',
            severity: tempKey == 'critical' ? AlertSeverity.critical : AlertSeverity.warning,
            triggeredAt: DateTime.now(),
            thresholdLabel: '${AppStrings.t('temp_max')} > $thr',
          ));
        } else if (tempKey.isEmpty) {
          _lastTempAlertKey = null;
        }
      }

      // ── SpO2 ────────────────────────────────
      String spo2Key = '';
      if (spo2 > 0) {
        if (spo2 < _thresholds.spo2Min - 5) {
          spo2Key = 'critical';
        } else if (spo2 < _thresholds.spo2Min) {
          spo2Key = 'warning';
        }

        if (spo2Key.isNotEmpty && spo2Key != _lastSpo2AlertKey) {
          _lastSpo2AlertKey = spo2Key;
          _lastAlertTime = DateTime.now();
          _active.insert(0, VitalAlert(
            id: 'alert_${_alertIdCounter++}',
            vitalName: AppStrings.t('oxygen_saturation'),
            value: '${spo2.toStringAsFixed(0)}%',
            severity: spo2Key == 'critical' ? AlertSeverity.critical : AlertSeverity.warning,
            triggeredAt: DateTime.now(),
            thresholdLabel: '${AppStrings.t('spo2_min')} < ${_thresholds.spo2Min.toStringAsFixed(0)}%',
          ));
        } else if (spo2Key.isEmpty) {
          _lastSpo2AlertKey = null;
        }
      }
    });
  }

  void _dismissAlert(VitalAlert alert) {
    setState(() {
      _active.remove(alert);
      alert.dismissed = true;
      _resolved.insert(0, alert);
      if (_active.isEmpty) _lastAlertTime = null;
    });
    _showToast(AppStrings.t('alert_dismissed'));
  }

  void _dismissAll() {
    setState(() {
      for (final a in List.of(_active)) {
        a.dismissed = true;
        _resolved.insert(0, a);
      }
      _active.clear();
      _lastAlertTime = null;
    });
    _showToast(AppStrings.t('all_dismissed'));
  }

  void _snoozeAlert(VitalAlert alert, int minutes) {
    setState(() => _active.remove(alert));
    _showToast('${AppStrings.t('snoozed_for')} $minutes ${AppStrings.t('minutes')}');
    Timer(Duration(minutes: minutes), () {
      if (mounted) setState(() => _active.insert(0, alert));
    });
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF334155),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCustomThresholds() async {
    final hrMinCtrl   = TextEditingController(text: _thresholds.hrMin.toStringAsFixed(0));
    final hrMaxCtrl   = TextEditingController(text: _thresholds.hrMax.toStringAsFixed(0));
    final tempMaxCtrl = TextEditingController(text: _thresholds.tempMax.toStringAsFixed(1));
    final spo2MinCtrl = TextEditingController(text: _thresholds.spo2Min.toStringAsFixed(0));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.border),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.tune_rounded, color: _orange, size: 20),
                SizedBox(width: 10),
                Text(AppStrings.t('custom_thresholds'),
                    style: TextStyle(color: context.textMain, fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              SizedBox(height: 16),
              _ThresholdField(ctrl: hrMinCtrl, label: AppStrings.t('hr_min'), color: _red),
              SizedBox(height: 12),
              _ThresholdField(ctrl: hrMaxCtrl, label: AppStrings.t('hr_max'), color: _red),
              SizedBox(height: 12),
              _ThresholdField(ctrl: tempMaxCtrl, label: AppStrings.t('temp_max'), color: _orange),
              SizedBox(height: 12),
              _ThresholdField(ctrl: spo2MinCtrl, label: AppStrings.t('spo2_min'), color: const Color(0xFF4F8EF7)),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _thresholds.hrMin   = double.tryParse(hrMinCtrl.text) ?? _thresholds.hrMin;
                      _thresholds.hrMax   = double.tryParse(hrMaxCtrl.text) ?? _thresholds.hrMax;
                      _thresholds.tempMax = double.tryParse(tempMaxCtrl.text) ?? _thresholds.tempMax;
                      _thresholds.spo2Min = double.tryParse(spo2MinCtrl.text) ?? _thresholds.spo2Min;
                      // Reset alert keys so new thresholds trigger fresh alerts
                      _lastHrAlertKey = null;
                      _lastTempAlertKey = null;
                      _lastSpo2AlertKey = null;
                    });
                    _saveThresholds();
                    Navigator.pop(context);
                    _showToast(AppStrings.t('settings_saved'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(AppStrings.t('apply'),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    hrMinCtrl.dispose(); hrMaxCtrl.dispose();
    tempMaxCtrl.dispose(); spo2MinCtrl.dispose();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  String _calmDuration() {
    if (_lastAlertTime == null) {
      // Use app start as reference — at least a few seconds
      return '0 ${AppStrings.t('calm_hours')}';
    }
    final diff = DateTime.now().difference(_lastAlertTime!);
    if (diff.inHours >= 1) return '${diff.inHours} ${AppStrings.t('calm_hours')}';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} min';
    return '${diff.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset("assets/images/alerts_bg.jpg", fit: BoxFit.cover),
        ),
        Container(color: Colors.black.withValues(alpha: 0.72)),
        Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t('alerts'),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                Text(
                  '${_active.length} ${AppStrings.t('active_count')} · ${_resolved.length} ${AppStrings.t('resolved_count')}',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _showCustomThresholds,
                icon: Icon(Icons.tune_rounded, color: _orange, size: 20),
                tooltip: AppStrings.t('custom_thresholds'),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: Colors.white24),
            ),
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // ── Active Alerts ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionHeader(
                    label: AppStrings.t('active_alerts'),
                    icon: Icons.notifications_active_rounded,
                    iconColor: _red,
                  ),
                  if (_active.isNotEmpty)
                    TextButton(
                      onPressed: _dismissAll,
                      style: TextButton.styleFrom(
                        foregroundColor: _red,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      child: Text(AppStrings.t('dismiss_all')),
                    ),
                ],
              ),
              SizedBox(height: 12),

              if (_active.isEmpty)
                _CalmCard(message: '${AppStrings.t('calm_message')} ${_calmDuration()} ${AppStrings.t('calm_emoji')}')
              else
                ...List.generate(
                  _active.length,
                  (i) => Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _AlertCard(
                      alert: _active[i],
                      timeAgo: _timeAgo(_active[i].triggeredAt),
                      onDismiss: () => _dismissAlert(_active[i]),
                      onSnooze: (m) => _snoozeAlert(_active[i], m),
                    ),
                  ),
                ),

              SizedBox(height: 24),

              // ── Resolved Alerts ────────────────────────
              _SectionHeader(
                label: AppStrings.t('resolved_alerts'),
                icon: Icons.check_circle_outline_rounded,
                iconColor: _green,
              ),
              SizedBox(height: 12),

              if (_resolved.isEmpty)
                _EmptyCard(
                  icon: Icons.history_rounded,
                  color: Colors.white54,
                  message: AppStrings.t('no_resolved'),
                )
              else
                ...List.generate(
                  _resolved.length,
                  (i) => Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: _ResolvedCard(
                      alert: _resolved[i],
                      timeAgo: _timeAgo(_resolved[i].triggeredAt),
                    ),
                  ),
                ),
            ],
          ),
        ), // End Scaffold
      ],
    ); // End Stack
  }
}

// ── Threshold input field ─────────────────────────────────────────────────
class _ThresholdField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final Color color;
  const _ThresholdField({required this.ctrl, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color.withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color.withValues(alpha: 0.35))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color, width: 1.5)),
      ),
    );
  }
}

// ── Calm Card ─────────────────────────────────────────────────────────────
class _CalmCard extends StatelessWidget {
  final String message;
  const _CalmCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _green.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(color: _green.withValues(alpha: 0.12), blurRadius: 16, spreadRadius: 1),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.child_care_rounded, color: _green, size: 22),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert Card ─────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final VitalAlert alert;
  final String timeAgo;
  final VoidCallback onDismiss;
  final void Function(int minutes) onSnooze;

  const _AlertCard({
    required this.alert,
    required this.timeAgo,
    required this.onDismiss,
    required this.onSnooze,
  });

  Color get _accentColor =>
      alert.severity == AlertSeverity.critical ? _red : _orange;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accentColor.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _SeverityBadge(severity: alert.severity),
                SizedBox(width: 8),
                Expanded(
                  child: Text(alert.vitalName,
                      style: TextStyle(
                          color: _accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
                Text(timeAgo,
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
              SizedBox(height: 8),
              Text(alert.value,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              // ── Threshold label ─────────────────────────
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 12, color: _accentColor),
                    SizedBox(width: 6),
                    Text(
                      '${AppStrings.t('threshold')}: ${alert.thresholdLabel}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _accentColor.withValues(alpha: 0.7)),
                      foregroundColor: Colors.white,
                      backgroundColor: _accentColor.withValues(alpha: 0.12),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(AppStrings.t('dismiss'),
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _SnoozeButton(
                      onSnooze: onSnooze, accentColor: _accentColor),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Snooze Button ──────────────────────────────────────────────────────────
class _SnoozeButton extends StatefulWidget {
  final void Function(int minutes) onSnooze;
  final Color accentColor;
  const _SnoozeButton({required this.onSnooze, required this.accentColor});

  @override
  State<_SnoozeButton> createState() => _SnoozeButtonState();
}

class _SnoozeButtonState extends State<_SnoozeButton> {
  int _selected = 5;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.accentColor.withValues(alpha: 0.5)),
          ),
          child: Row(children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selected,
                  dropdownColor: const Color(0xFF1E293B),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  icon: Icon(Icons.expand_more_rounded,
                      size: 16, color: widget.accentColor),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  items: [5, 15, 30]
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m min',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selected = v ?? 5),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => widget.onSnooze(_selected),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.snooze_rounded,
                    size: 18, color: widget.accentColor),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Severity Badge ─────────────────────────────────────────────────────────
class _SeverityBadge extends StatelessWidget {
  final AlertSeverity severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final isCritical = severity == AlertSeverity.critical;
    final color = isCritical ? _red : _orange;
    final label = isCritical ? AppStrings.t('critical') : AppStrings.t('warning');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5)),
    );
  }
}

// ── Resolved Card ──────────────────────────────────────────────────────────
class _ResolvedCard extends StatelessWidget {
  final VitalAlert alert;
  final String timeAgo;
  const _ResolvedCard({required this.alert, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _green.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            Icon(Icons.check_circle_rounded, color: _green, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.vitalName,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text(alert.value,
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 3),
                  Text(
                    '${AppStrings.t('threshold')}: ${alert.thresholdLabel}',
                    style: TextStyle(color: _green.withValues(alpha: 0.85), fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(timeAgo, style: TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  const _SectionHeader(
      {required this.label, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: iconColor),
      SizedBox(width: 8),
      Text(label,
          style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
    ]);
  }
}

// ── Empty Card ─────────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _EmptyCard(
      {required this.icon, required this.color, required this.message});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 10),
              Text(message,
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

