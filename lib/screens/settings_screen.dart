import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/screens/login_screen.dart';

const Color _bg      = Color(0xFF0F172A);
const Color _surface = Color(0xFF1E293B);
const Color _green   = Color(0xFF1DB954);
const Color _red     = Color(0xFFFF6B6B);
const Color _subtext = Color(0xFF94A3B8);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _alertsEnabled   = true;
  bool _soundEnabled    = true;
  bool _vibration       = true;
  double _hrHigh   = 170;
  double _spo2Low  = 93;
  double _tempHigh = 38;
  double _rrHigh   = 65;

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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Settings',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          _SectionLabel('Notifications'),
          const SizedBox(height: 10),
          _ToggleTile(
              icon: Icons.notifications_outlined,
              label: 'Enable Alerts',
              value: _alertsEnabled,
              onChanged: (v) => setState(() => _alertsEnabled = v)),
          const SizedBox(height: 8),
          _ToggleTile(
              icon: Icons.volume_up_outlined,
              label: 'Sound',
              value: _soundEnabled,
              onChanged: (v) => setState(() => _soundEnabled = v)),
          const SizedBox(height: 8),
          _ToggleTile(
              icon: Icons.vibration_outlined,
              label: 'Vibration',
              value: _vibration,
              onChanged: (v) => setState(() => _vibration = v)),
          const SizedBox(height: 28),
          _SectionLabel('Alert Thresholds'),
          const SizedBox(height: 10),
          _SliderTile(
              label: 'Heart Rate — High',
              value: _hrHigh, min: 140, max: 200,
              unit: 'bpm', color: _green,
              onChanged: (v) => setState(() => _hrHigh = v)),
          const SizedBox(height: 8),
          _SliderTile(
              label: 'SpO₂ — Low',
              value: _spo2Low, min: 85, max: 95,
              unit: '%', color: const Color(0xFF4F8EF7),
              onChanged: (v) => setState(() => _spo2Low = v)),
          const SizedBox(height: 8),
          _SliderTile(
              label: 'Temperature — High',
              value: _tempHigh, min: 37, max: 40,
              unit: '°C', color: const Color(0xFFFFAB40),
              onChanged: (v) => setState(() => _tempHigh = v)),
          const SizedBox(height: 8),
          _SliderTile(
              label: 'Resp. Rate — High',
              value: _rrHigh, min: 50, max: 80,
              unit: 'br/min', color: const Color(0xFFA78BFA),
              onChanged: (v) => setState(() => _rrHigh = v)),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _red.withValues(alpha: 0.25)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: _red, size: 18),
                  SizedBox(width: 10),
                  Text('Log Out',
                      style: TextStyle(
                          color: _red,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: const TextStyle(
            color: _subtext,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2),
      );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.label,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: _subtext, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 14))),
        Switch(
            value: value, onChanged: onChanged,
            activeColor: _green,
            inactiveTrackColor: Colors.white12,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ]),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final Color color;
  final ValueChanged<double> onChanged;
  const _SliderTile({required this.label, required this.value,
      required this.min,   required this.max,
      required this.unit,  required this.color,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 13))),
          Text('${value.toStringAsFixed(1)} $unit',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: Colors.white12,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.15),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
              value: value, min: min, max: max, onChanged: onChanged),
        ),
      ]),
    );
  }
}