import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/main.dart' show themeModeNotifier;
import 'package:first_app/screens/login_screen.dart';

// ─────────────────────────────────────────────
//  Theme-aware colour helpers
// ─────────────────────────────────────────────
extension _AppTheme on BuildContext {
  ColorScheme get cs      => Theme.of(this).colorScheme;
  Color get bgPage        => Theme.of(this).scaffoldBackgroundColor;
  Color get bgCard        => cs.surface;
  Color get textMain      => Theme.of(this).textTheme.bodyLarge?.color ?? cs.onSurface;
  Color get textSub       => Theme.of(this).textTheme.bodySmall?.color ?? cs.onSurfaceVariant;
  Color get dividerClr    => Theme.of(this).dividerColor;
  Color get primary       => cs.primary;
  bool  get isDark        => Theme.of(this).brightness == Brightness.dark;
}

const _green   = Color(0xFF1DB954);
const _red     = Color(0xFFFF6B6B);
const _orange  = Color(0xFFFFAB40);
const _blue    = Color(0xFF4F8EF7);
const _purple  = Color(0xFFA78BFA);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Notification toggles ─────────────────
  bool _pushNotifications = true;
  bool _soundAlerts       = true;
  bool _vibration         = true;

  // ── Alert threshold ranges ────────────────
  double _hrMin   = 100;
  double _hrMax   = 160;
  double _tempMin = 36.5;
  double _tempMax = 38.0;
  double _spo2Min = 94;
  double _spo2Max = 100;

  // ── Preferences ──────────────────────────
  String _tempUnit      = 'Celsius';
  String _language      = 'English';
  String _refreshRate   = '3 seconds';

  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  void _toggleDarkMode(bool v) {
    setState(() {
      themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', false);
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPage,
      appBar: AppBar(
        backgroundColor: context.bgCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                color: context.textMain,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Alerts · Preferences · About',
              style: TextStyle(color: context.textSub, fontSize: 11),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.dividerClr),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const BouncingScrollPhysics(),
        children: [

          // ── Alert Thresholds ─────────────────
          _SectionHeader(label: 'Alert Thresholds', icon: Icons.notifications_active_outlined),
          const SizedBox(height: 12),

          _ThresholdCard(
            label: 'Heart Rate',
            icon: Icons.favorite_rounded,
            iconColor: _red,
            minLabel: 'Min (BPM)', maxLabel: 'Max (BPM)',
            minValue: _hrMin, maxValue: _hrMax,
            minRange: (60, 120), maxRange: (130, 220),
            onMinChanged: (v) => setState(() => _hrMin = v),
            onMaxChanged: (v) => setState(() => _hrMax = v),
          ),
          const SizedBox(height: 12),

          _ThresholdCard(
            label: 'Temperature',
            icon: Icons.thermostat_rounded,
            iconColor: _orange,
            minLabel: 'Min (°C)', maxLabel: 'Max (°C)',
            minValue: _tempMin, maxValue: _tempMax,
            minRange: (35.0, 37.0), maxRange: (37.1, 41.0),
            decimals: 1,
            onMinChanged: (v) => setState(() => _tempMin = v),
            onMaxChanged: (v) => setState(() => _tempMax = v),
          ),
          const SizedBox(height: 12),

          _ThresholdCard(
            label: 'SpO2',
            icon: Icons.air_rounded,
            iconColor: _blue,
            minLabel: 'Min (%)', maxLabel: 'Max (%)',
            minValue: _spo2Min, maxValue: _spo2Max,
            minRange: (80, 95), maxRange: (96, 100),
            onMinChanged: (v) => setState(() => _spo2Min = v),
            onMaxChanged: (v) => setState(() => _spo2Max = v),
          ),

          const SizedBox(height: 28),

          // ── Notifications ────────────────────
          _SectionHeader(label: 'Notifications', icon: Icons.notifications_outlined),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _ToggleTile(
                icon: Icons.notifications_outlined,
                label: 'Push Notifications',
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
              ),
              Divider(color: context.dividerClr, height: 1, indent: 48),
              _ToggleTile(
                icon: Icons.volume_up_outlined,
                label: 'Sound Alerts',
                value: _soundAlerts,
                onChanged: (v) => setState(() => _soundAlerts = v),
              ),
              Divider(color: context.dividerClr, height: 1, indent: 48),
              _ToggleTile(
                icon: Icons.vibration_outlined,
                label: 'Vibration',
                value: _vibration,
                onChanged: (v) => setState(() => _vibration = v),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Preferences ──────────────────────
          _SectionHeader(label: 'Preferences', icon: Icons.tune_outlined),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _ToggleTile(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
                activeColor: context.primary,
              ),
              Divider(color: context.dividerClr, height: 1, indent: 48),
              _SelectTile(
                icon: Icons.thermostat_outlined,
                label: 'Temperature Unit',
                value: _tempUnit,
                options: const ['Celsius', 'Fahrenheit'],
                onChanged: (v) => setState(() => _tempUnit = v),
              ),
              Divider(color: context.dividerClr, height: 1, indent: 48),
              _SelectTile(
                icon: Icons.language_outlined,
                label: 'Language',
                value: _language,
                options: const ['English', 'Swahili', 'French'],
                onChanged: (v) => setState(() => _language = v),
              ),
              Divider(color: context.dividerClr, height: 1, indent: 48),
              _SelectTile(
                icon: Icons.timer_outlined,
                label: 'Data Refresh Rate',
                value: _refreshRate,
                options: const ['1 second', '3 seconds', '5 seconds', '10 seconds'],
                onChanged: (v) => setState(() => _refreshRate = v),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── About ─────────────────────────────
          _SectionHeader(label: 'About', icon: Icons.info_outlined),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.dividerClr),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.05),
                  blurRadius: 8, offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IoT Infant Vitals Monitor',
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: context.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: context.textSub),
                ),
                const SizedBox(height: 10),
                Text(
                  'A wearable IoT-based system for real-time monitoring of infant heart rate, body temperature, and oxygen saturation levels.',
                  style: TextStyle(fontSize: 13, color: context.textSub, height: 1.5),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: [
                    _Tag(label: 'Firebase', color: _orange),
                    _Tag(label: 'IoT Sensors', color: _blue),
                    _Tag(label: 'Real-time', color: _green),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Save All Settings ─────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Settings saved'),
                    backgroundColor: context.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text(
                'Save All Settings',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Log Out ───────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 16, color: _red),
              label: const Text(
                'Log Out',
                style: TextStyle(color: _red, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _red.withOpacity(0.35)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Section header with icon
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.textMain,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Wraps children in a card container
// ─────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerClr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.05),
            blurRadius: 8, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

// ─────────────────────────────────────────────
//  Toggle tile row
// ─────────────────────────────────────────────
class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  const _ToggleTile({
    required this.icon, required this.label,
    required this.value, required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: context.textSub),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 14, color: context.textMain))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor ?? _green,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  Select tile row (shows current value + ›)
// ─────────────────────────────────────────────
class _SelectTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _SelectTile({
    required this.icon, required this.label,
    required this.value, required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(0),
      onTap: () async {
        final chosen = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: context.bgCard,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _OptionSheet(
            title: label, options: options, selected: value,
            accentColor: context.primary,
          ),
        );
        if (chosen != null) onChanged(chosen);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 18, color: context.textSub),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 14, color: context.textMain))),
          Text(value,
              style: TextStyle(fontSize: 13, color: context.textSub)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 18, color: context.textSub),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Option picker sheet
// ─────────────────────────────────────────────
class _OptionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final Color accentColor;
  const _OptionSheet({
    required this.title, required this.options,
    required this.selected, required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: context.dividerClr,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: context.textMain,
              )),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final isSel = opt == selected;
            return ListTile(
              title: Text(opt,
                  style: TextStyle(
                    color: isSel ? accentColor : context.textMain,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.normal,
                  )),
              trailing: isSel ? Icon(Icons.check_rounded, color: accentColor) : null,
              onTap: () => Navigator.of(context).pop(opt),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Threshold card  (Min + Max input fields)
// ─────────────────────────────────────────────
class _ThresholdCard extends StatelessWidget {
  final String label, minLabel, maxLabel;
  final IconData icon;
  final Color iconColor;
  final double minValue, maxValue;
  final (double, double) minRange, maxRange;
  final int decimals;
  final ValueChanged<double> onMinChanged, onMaxChanged;

  const _ThresholdCard({
    required this.label,   required this.icon,  required this.iconColor,
    required this.minLabel, required this.maxLabel,
    required this.minValue, required this.maxValue,
    required this.minRange, required this.maxRange,
    required this.onMinChanged, required this.onMaxChanged,
    this.decimals = 0,
  });

  String _fmt(double v) =>
      decimals > 0 ? v.toStringAsFixed(decimals) : v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerClr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.05),
            blurRadius: 8, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ]),
          const SizedBox(height: 14),
          // Min / Max fields side by side
          Row(children: [
            Expanded(child: _ThresholdField(
              label: minLabel, value: _fmt(minValue),
              min: minRange.$1, max: minRange.$2,
              color: iconColor,
              onChanged: onMinChanged,
              decimals: decimals,
            )),
            const SizedBox(width: 12),
            Expanded(child: _ThresholdField(
              label: maxLabel, value: _fmt(maxValue),
              min: maxRange.$1, max: maxRange.$2,
              color: iconColor,
              onChanged: onMaxChanged,
              decimals: decimals,
            )),
          ]),
        ],
      ),
    );
  }
}

class _ThresholdField extends StatefulWidget {
  final String label, value;
  final double min, max;
  final Color color;
  final int decimals;
  final ValueChanged<double> onChanged;

  const _ThresholdField({
    required this.label, required this.value,
    required this.min,   required this.max,
    required this.color, required this.onChanged,
    this.decimals = 0,
  });

  @override
  State<_ThresholdField> createState() => _ThresholdFieldState();
}

class _ThresholdFieldState extends State<_ThresholdField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_ThresholdField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: TextStyle(fontSize: 11, color: context.textSub)),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(fontSize: 14, color: context.textMain, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.bgPage,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.dividerClr),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: widget.color, width: 1.8),
            ),
          ),
          onSubmitted: (v) {
            final parsed = double.tryParse(v);
            if (parsed != null) {
              widget.onChanged(parsed.clamp(widget.min, widget.max));
            }
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Tag chip (About section)
// ─────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}