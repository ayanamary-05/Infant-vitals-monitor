import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:first_app/screens/theme_ext.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:first_app/screens/vitals_service.dart';
import 'package:first_app/screens/history_screen.dart';
import 'package:first_app/screens/alerts_screen.dart';
import 'package:first_app/screens/settings_screen.dart';
import 'package:first_app/screens/profile_screen.dart';
import 'package:first_app/screens/app_strings.dart';
import 'package:first_app/main.dart'
    show tempUnitNotifier, refreshRateNotifier, alertCountNotifier, languageNotifier;

// ── Palette ───────────────────────────────



const Color kGreen   = const Color(0xFF1DB954);
const Color kBlue    = const Color(0xFF4F8EF7);
const Color kOrange  = const Color(0xFFFFAB40);
const Color kRed     = const Color(0xFFFF6B6B);

// ══════════════════════════════════════════
// ROOT — manages bottom nav + SOS overlay
// ══════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = const [
      _DashboardTab(),
      HistoryScreen(),
      AlertsScreen(),
      ProfileScreen(),
      SettingsScreen(),
    ];
    startVitalsSimulation(refreshRateNotifier.value);
    refreshRateNotifier.addListener(_onRefreshRateChanged);
  }

  void _onRefreshRateChanged() {
    startVitalsSimulation(refreshRateNotifier.value);
  }

  @override
  void dispose() {
    refreshRateNotifier.removeListener(_onRefreshRateChanged);
    stopVitalsSimulation();
    super.dispose();
  }

  void _showSos() {
    // Show toast then immediately launch phone dialler
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.call_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Calling John Doe…',
                style: TextStyle(color: context.textMain, fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
    launchUrl(Uri.parse('tel:+919895072644'));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier.select((l) => l.languageCode),
      builder: (_, __, ___) => Scaffold(
        backgroundColor: context.bg,
        body: Stack(
          children: [
            IndexedStack(index: _tab, children: _tabs),
            // ── SOS Button (always visible) ─────────────────
            Positioned(
              right: 16,
              bottom: 80,
              child: GestureDetector(
                onTap: _showSos,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: kRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kRed.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      AppStrings.t('sos'),
                      style: TextStyle(
                        color: context.textMain, fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          current: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// DASHBOARD TAB
// ══════════════════════════════════════════
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab>
    with TickerProviderStateMixin {
  bool _isRefreshing = false;
  late AnimationController _pulseController;
  String _babyName = 'Baby Sarah';

  String get _greeting {
    // Calculate current time in Indian Standard Time (UTC+5:30)
    final nowUtc = DateTime.now().toUtc();
    final istTime = nowUtc.add(const Duration(hours: 5, minutes: 30));
    final h = istTime.hour;

    if (h < 12) return AppStrings.t('greeting_morning');
    if (h < 17) return AppStrings.t('greeting_afternoon');
    return AppStrings.t('greeting_evening');
  }

  String get _greetingLine {
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? 'User';
    final firstName = fullName.split(' ').first;
    // Dynamically greets the user safely
    return '$_greeting $firstName';
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    vitalsNotifier.addListener(_onVitalsUpdate);
    _loadBabyName();
    languageNotifier.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _loadBabyName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('p_infantName') ?? 'Baby Sarah';
    if (mounted) setState(() => _babyName = name);
  }

  void _onVitalsUpdate() {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isRefreshing = false);
    });
  }

  @override
  void dispose() {
    vitalsNotifier.removeListener(_onVitalsUpdate);
    languageNotifier.removeListener(_rebuild);
    _pulseController.dispose();
    super.dispose();
  }

  String _trend(double current, double previous) {
    final diff = current - previous;
    if (diff.abs() < 0.5) return '→';
    return diff > 0 ? '↑' : '↓';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  int _healthScore(VitalsState v) {
    int score = 100;
    if (v.hr > 160 || v.hr < 100) {
      score -= 20;
    } else if (v.hr > 150 || v.hr < 110) {
      score -= 5;
    }
    if (v.temp > 38.5) {
      score -= 20;
    } else if (v.temp > 38.0) {
      score -= 10;
    }
    if (v.spo2 < 89) {
      score -= 30;
    } else if (v.spo2 < 94) {
      score -= 15;
    }
    return score.clamp(0, 100);
  }

  String _healthLabel(int score) {
    if (score >= 90) return AppStrings.t('excellent');
    if (score >= 75) return AppStrings.t('good');
    if (score >= 50) return AppStrings.t('fair');
    return AppStrings.t('poor');
  }

  void _showScoreInfo(BuildContext context, int score) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.textMain.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline_rounded, color: kBlue, size: 20),
                ),
                SizedBox(width: 12),
                Text(AppStrings.t('health_score_info'),
                    style: TextStyle(color: context.textMain, fontSize: 17, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('$score/100',
                    style: TextStyle(color: kBlue, fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
              SizedBox(height: 16),
              Text(AppStrings.t('health_score_desc'),
                  style: TextStyle(color: context.subtext, fontSize: 13, height: 1.65)),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(AppStrings.t('close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VitalsState>(
      valueListenable: vitalsNotifier,
      builder: (_, v, __) => ValueListenableBuilder<String>(
        valueListenable: tempUnitNotifier,
        builder: (_, tempUnit, __) {
          final isFahrenheit = tempUnit == 'Fahrenheit';
          final displayTemp = isFahrenheit ? v.temp * 9 / 5 + 32 : v.temp;
          final tempStr = displayTemp.toStringAsFixed(1);
          final tempUnitLabel = isFahrenheit ? '°F' : '°C';
          final normalRangeTemp =
              isFahrenheit ? '97.7 – 100.4 °F' : '36.5 – 38.0 °C';

          final hrTrend   = _trend(v.hr,   v.prevHr);
          final tempTrend = _trend(v.temp,  v.prevTemp);
          final spo2Trend = _trend(v.spo2,  v.prevSpo2);

          final score    = _healthScore(v);
          final hasAlert = score < 75;

          return Stack(
            children: [
              // Background image & dark overlay
              SizedBox.expand(
                child: Image.asset("assets/images/dashboard_bg.jpg", fit: BoxFit.cover),
              ),
              Container(color: Colors.black.withValues(alpha: 0.68)),

              SafeArea(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 32),
                  children: [
                    // ── Greeting ──
                    Text(_greetingLine,
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 4),
                    Text(AppStrings.t('infant_monitoring'),
                        style: TextStyle(
                            color: Colors.white, fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),

                    // ── Health status banner ──
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: hasAlert
                                ? kRed.withValues(alpha: 0.15)
                                : kGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: hasAlert
                                  ? kRed.withValues(alpha: 0.35)
                                  : kGreen.withValues(alpha: 0.35),
                            ),
                          ),
                  child: Row(children: [
                    Icon(
                      hasAlert
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_rounded,
                      color: hasAlert ? kRed : kGreen,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasAlert
                                ? AppStrings.t('vital_alert_active')
                                : AppStrings.t('all_vitals_normal'),
                            style: TextStyle(
                              color: hasAlert ? kRed : kGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            hasAlert
                                ? AppStrings.t('check_readings')
                                : AppStrings.t('vitals_safe'),
                            style: TextStyle(
                              color: (hasAlert ? kRed : kGreen)
                                  .withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Score with info button
                    GestureDetector(
                      onTap: () => _showScoreInfo(context, score),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '$score/100',
                                style: TextStyle(
                                  color: hasAlert ? kRed : kGreen,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.info_outline_rounded,
                                color: (hasAlert ? kRed : kGreen).withValues(alpha: 0.6),
                                size: 14,
                              ),
                            ],
                          ),
                          Text(
                            _healthLabel(score),
                            style: TextStyle(
                              color: (hasAlert ? kRed : kGreen)
                                  .withValues(alpha: 0.75),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
                ), // End Health status ClipRRect
                SizedBox(height: 20),

                // ── Heart Rate ──
                _DashboardVitalCard(
                  label: AppStrings.t('heart_rate'),
                  normalRange: '${AppStrings.t('normal')}: 100 – 160 BPM',
                  value: v.hr.toStringAsFixed(0),
                  unit: 'BPM',
                  icon: Icons.favorite_rounded,
                  color: kRed,
                  trend: hrTrend,
                  lastUpdated: _formatTime(v.lastUpdated),
                  isRefreshing: _isRefreshing,
                  pulseController: _pulseController,
                  showPulse: true,
                ),
                SizedBox(height: 12),

                // ── Temperature ──
                _DashboardVitalCard(
                  label: AppStrings.t('body_temperature'),
                  normalRange: '${AppStrings.t('normal')}: $normalRangeTemp',
                  value: tempStr,
                  unit: tempUnitLabel,
                  icon: Icons.thermostat_rounded,
                  color: kOrange,
                  trend: tempTrend,
                  lastUpdated: _formatTime(v.lastUpdated),
                  isRefreshing: _isRefreshing,
                  pulseController: _pulseController,
                ),
                SizedBox(height: 12),

                // ── SpO2 ──
                _DashboardVitalCard(
                  label: AppStrings.t('oxygen_saturation'),
                  normalRange: '${AppStrings.t('normal')}: 94 – 100 %',
                  value: v.spo2.toStringAsFixed(0),
                  unit: '%',
                  icon: Icons.air_rounded,
                  color: kBlue,
                  trend: spo2Trend,
                  lastUpdated: _formatTime(v.lastUpdated),
                  isRefreshing: _isRefreshing,
                  pulseController: _pulseController,
                ),
              ],
            ),
          ),
          ],
         );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════
// DASHBOARD VITAL CARD
// ══════════════════════════════════════════
class _DashboardVitalCard extends StatelessWidget {
  final String label, normalRange, value, unit, trend, lastUpdated;
  final IconData icon;
  final Color color;
  final bool isRefreshing;
  final bool showPulse;
  final AnimationController pulseController;

  const _DashboardVitalCard({
    required this.label,
    required this.normalRange,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.trend,
    required this.lastUpdated,
    required this.isRefreshing,
    required this.pulseController,
    this.showPulse = false,
  });

  Color _trendColor(BuildContext context) {
    if (trend == '↑') return kRed;
    if (trend == '↓') return kBlue;
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
        children: [
          // Icon with optional pulse ring
          SizedBox(
            width: 52,
            height: 52,
            child: showPulse
                ? AnimatedBuilder(
                    animation: pulseController,
                    builder: (_, child) {
                      final scale = 1.0 + pulseController.value * 0.35;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: (1 - pulseController.value) * 0.4,
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color, width: 2),
                                ),
                              ),
                            ),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: _iconCircle(),
                  )
                : _iconCircle(),
          ),
          SizedBox(width: 14),
          // Label + range + prominent timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 3),
                Text(normalRange,
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                SizedBox(height: 6),
                // Prominent timestamp pill
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isRefreshing
                      ? Row(
                          key: const ValueKey('updating'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: Colors.white70),
                            ),
                            SizedBox(width: 6),
                            Text(
                              AppStrings.t('updating'),
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        )
                      : Container(
                          key: const ValueKey('timestamp'),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 11, color: color.withValues(alpha: 0.8)),
                              SizedBox(width: 4),
                              Text(
                                '${AppStrings.t('updated')} $lastUpdated',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          // Value + unit + trend
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          color: Colors.white, fontSize: 30,
                          fontWeight: FontWeight.bold,
                          height: 1.0)),
                  SizedBox(width: 4),
                  Text(trend,
                      style: TextStyle(
                          color: _trendColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              Text(unit,
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
      ), // Backdrop filter close
    ); // ClipRRect close
  }

  Widget _iconCircle() => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      );
}

// helper extension to listen to derived value
extension _ValueListenableExt<T> on ValueNotifier<T> {
  ValueNotifier<R> select<R>(R Function(T) selector) {
    final derived = ValueNotifier<R>(selector(value));
    addListener(() => derived.value = selector(value));
    return derived;
  }
}

// ══════════════════════════════════════════
// BOTTOM NAV  (with alert badge)
// ══════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.grid_view_rounded,     Icons.grid_view_outlined,     AppStrings.t('Dashboard')),
      (Icons.access_time_rounded,   Icons.access_time_outlined,   AppStrings.t('History')),
      (Icons.notifications_rounded, Icons.notifications_outlined, AppStrings.t('alerts')),
      (Icons.person_rounded,        Icons.person_outlined,        AppStrings.t('profile')),
      (Icons.settings_rounded,      Icons.settings_outlined,      AppStrings.t('settings')),
    ];

    return ValueListenableBuilder<int>(
      valueListenable: alertCountNotifier,
      builder: (_, alertCount, __) => Container(
        decoration: BoxDecoration(
          color: context.surface,
          border: Border(
              top: BorderSide(
                  color: context.textMain.withValues(alpha: 0.08))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(items.length, (i) {
                final sel = i == current;
                final (filled, outlined, label) = items[i];
                final isAlerts = i == 2;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                sel ? filled : outlined,
                                key: ValueKey(sel),
                                color: sel ? kGreen : context.subtext,
                                size: 22,
                              ),
                            ),
                            if (isAlerts && alertCount > 0)
                              Positioned(
                                top: -4,
                                right: -6,
                                child: Container(
                                  padding: EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: kRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$alertCount',
                                    style: TextStyle(
                                      color: context.textMain, fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: sel ? kGreen : context.subtext,
                            fontSize: 10,
                            fontWeight: sel
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          child: Text(label.isEmpty ? _navLabel(i) : label),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  String _navLabel(int i) {
    const labels = ['Dashboard', 'History', 'Alerts', 'Profile', 'Settings'];
    return labels[i];
  }
}