import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/main.dart'
    show themeModeNotifier, languageNotifier,
         tempUnitNotifier, refreshRateNotifier;
import 'package:first_app/screens/login_screen.dart';
import 'package:first_app/screens/app_strings.dart';

// ─────────────────────────────────────────────
//  Theme-aware colour helpers
// ─────────────────────────────────────────────
extension _AppTheme on BuildContext {
  ColorScheme get cs   => Theme.of(this).colorScheme;
  Color get bgPage     => Theme.of(this).scaffoldBackgroundColor;
  Color get bgCard     => cs.surface;
  Color get textMain   => Theme.of(this).textTheme.bodyLarge?.color ?? cs.onSurface;
  Color get textSub    => Theme.of(this).textTheme.bodySmall?.color ?? cs.onSurfaceVariant;
  Color get dividerClr => Theme.of(this).dividerColor;
  Color get primary    => cs.primary;
  bool  get isDark     => Theme.of(this).brightness == Brightness.dark;
}

const _green  = Color(0xFF1DB954);
const _red    = Color(0xFFFF6B6B);

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

  // ── Preferences (mirror global notifiers) ─
  String _tempUnit      = tempUnitNotifier.value;
  String _refreshRate   = '3 seconds';
  bool   _batterySaver  = false;
  bool   _cloudBackup   = false;

  bool get _isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
    languageNotifier.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('s_pushNotif')    ?? _pushNotifications;
      _soundAlerts       = prefs.getBool('s_soundAlerts')  ?? _soundAlerts;
      _vibration         = prefs.getBool('s_vibration')    ?? _vibration;
      _tempUnit          = prefs.getString('s_tempUnit')   ?? _tempUnit;
      _refreshRate       = prefs.getString('s_refreshRate') ?? _refreshRate;
      _batterySaver      = prefs.getBool('s_batterySaver') ?? _batterySaver;
      _cloudBackup       = prefs.getBool('s_cloudBackup')  ?? _cloudBackup;
    });
    if (_batterySaver) refreshRateNotifier.value = 30;

    // Apply loaded preferences globally
    tempUnitNotifier.value = _tempUnit;
    refreshRateNotifier.value = _refreshRateToSeconds(_refreshRate);
    themeModeNotifier.value =
        (prefs.getBool('s_darkMode') ?? true) ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('s_pushNotif',    _pushNotifications);
    await prefs.setBool('s_soundAlerts',  _soundAlerts);
    await prefs.setBool('s_vibration',    _vibration);
    await prefs.setString('s_tempUnit',   _tempUnit);
    await prefs.setString('s_refreshRate', _refreshRate);
    await prefs.setBool('s_darkMode',     _isDarkMode);
    await prefs.setBool('s_batterySaver', _batterySaver);
    await prefs.setBool('s_cloudBackup',  _cloudBackup);
  }

  int _refreshRateToSeconds(String label) {
    return switch (label) {
      '1 second'   => 1,
      '5 seconds'  => 5,
      '10 seconds' => 10,
      _            => 3,
    };
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: context.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleDarkMode(bool v) {
    setState(() => themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light);
    _saveToPrefs();
    _showToast('Settings saved');
  }

  @override
  void dispose() {
    languageNotifier.removeListener(_rebuild);
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', false);
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
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
            Text(AppStrings.t('settings'),
                style: TextStyle(
                    color: context.textMain, fontSize: 18, fontWeight: FontWeight.w700)),
            Text(AppStrings.t('preferences_notif'),
                style: TextStyle(color: context.textSub, fontSize: 11)),
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

          // ── Notifications ────────────────────
          _SectionHeader(label: AppStrings.t('notifications'), icon: Icons.notifications_outlined),
          const SizedBox(height: 12),
          _SettingsCard(children: [
            _ToggleTile(
              icon: Icons.notifications_outlined,
              label: AppStrings.t('push_notifications'),
              value: _pushNotifications,
              onChanged: (v) {
                setState(() => _pushNotifications = v);
                _saveToPrefs();
                _showToast(AppStrings.t('settings_saved'));
              },
            ),
            Divider(color: context.dividerClr, height: 1, indent: 48),
            _ToggleTile(
              icon: Icons.volume_up_outlined,
              label: AppStrings.t('sound_alerts'),
              value: _soundAlerts,
              onChanged: (v) {
                setState(() => _soundAlerts = v);
                _saveToPrefs();
                _showToast(AppStrings.t('settings_saved'));
              },
            ),
            Divider(color: context.dividerClr, height: 1, indent: 48),
            _ToggleTile(
              icon: Icons.vibration_outlined,
              label: AppStrings.t('vibration'),
              value: _vibration,
              onChanged: (v) {
                setState(() => _vibration = v);
                _saveToPrefs();
                _showToast(AppStrings.t('settings_saved'));
              },
            ),
          ]),

          const SizedBox(height: 28),

          // ── Preferences ──────────────────────
          _SectionHeader(label: AppStrings.t('preferences'), icon: Icons.tune_outlined),
          const SizedBox(height: 12),
          _SettingsCard(children: [
            // Dark Mode
            _ToggleTile(
              icon: Icons.dark_mode_outlined,
              label: AppStrings.t('dark_mode'),
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
              activeColor: context.primary,
            ),
            Divider(color: context.dividerClr, height: 1, indent: 48),

            // Temperature Unit
            _SelectTile(
              icon: Icons.thermostat_outlined,
              label: AppStrings.t('temperature_unit'),
              value: _tempUnit,
              options: const ['Celsius', 'Fahrenheit'],
              onChanged: (v) {
                setState(() => _tempUnit = v);
                tempUnitNotifier.value = v;
                _saveToPrefs();
                _showToast(AppStrings.t('settings_saved'));
              },
            ),
            Divider(color: context.dividerClr, height: 1, indent: 48),

            // Data Refresh Rate
            _SelectTile(
              icon: Icons.timer_outlined,
              label: AppStrings.t('data_refresh_rate'),
              value: _refreshRate,
              options: const ['1 second', '3 seconds', '5 seconds', '10 seconds'],
              onChanged: (v) {
                setState(() {
                  _refreshRate = v;
                  // Disable battery saver if a specific rate is chosen
                  _batterySaver = false;
                });
                refreshRateNotifier.value = _refreshRateToSeconds(v);
                _saveToPrefs();
                _showToast(AppStrings.t('settings_saved'));
              },
            ),
            Divider(color: context.dividerClr, height: 1, indent: 48),

            // Battery Saver Mode
            _ToggleTile(
              icon: Icons.battery_saver_outlined,
              label: AppStrings.t('battery_saver'),
              subtitle: AppStrings.t('battery_saver_sub'),
              value: _batterySaver,
              onChanged: (v) {
                setState(() => _batterySaver = v);
                if (v) {
                  refreshRateNotifier.value = 30;
                } else {
                  refreshRateNotifier.value = _refreshRateToSeconds(_refreshRate);
                }
                _saveToPrefs();
                _showToast(AppStrings.t('settings_saved'));
              },
            ),
            Divider(color: context.dividerClr, height: 1, indent: 48),

            // Cloud Backup
            _ToggleTile(
              icon: Icons.cloud_upload_outlined,
              label: AppStrings.t('cloud_backup'),
              subtitle: AppStrings.t('cloud_backup_sub'),
              value: _cloudBackup,
              onChanged: (v) {
                setState(() => _cloudBackup = v);
                _saveToPrefs();
                _showToast(v ? AppStrings.t('cloud_enabled') : AppStrings.t('cloud_disabled'));
              },
            ),
          ]),

          const SizedBox(height: 28),

          // ── About ─────────────────────────────
          _SectionHeader(label: AppStrings.t('about'), icon: Icons.info_outlined),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.dividerClr),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
                  blurRadius: 8, offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t('app_name'),
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: context.textMain)),
                const SizedBox(height: 4),
                Text(AppStrings.t('version'),
                    style: TextStyle(fontSize: 12, color: context.textSub)),
                const SizedBox(height: 10),
                Text(
                  AppStrings.t('app_desc'),
                  style: TextStyle(fontSize: 13, color: context.textSub, height: 1.5),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: [
                    _Tag(label: 'Firebase',    color: const Color(0xFFFFAB40)),
                    _Tag(label: 'IoT Sensors', color: const Color(0xFF4F8EF7)),
                    _Tag(label: 'Real-time',   color: _green),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Log Out ───────────────────────────
          SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 16, color: _red),
              label: Text(AppStrings.t('log_out'),
                  style: const TextStyle(
                      color: _red, fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _red.withValues(alpha: 0.35)),
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
        Text(label,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: context.textMain)),
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
            color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
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
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const _ToggleTile({
    required this.icon, required this.label,
    required this.value, required this.onChanged,
    this.subtitle,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: context.textSub),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: context.textMain)),
            if (subtitle != null)
              Text(subtitle!, style: TextStyle(fontSize: 11, color: context.textSub)),
          ],
        )),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: activeColor ?? _green,
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
          Text(value, style: TextStyle(fontSize: 13, color: context.textSub)),
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
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: context.dividerClr,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final isSel = opt == selected;
            return ListTile(
              title: Text(opt,
                  style: TextStyle(
                    color: isSel ? accentColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}