import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' show ImageFilter;

import 'package:first_app/main.dart' show criticalAlertNotifier, localNotificationsPlugin;
import 'package:first_app/screens/vitals_service.dart'
    show vitalsNotifier, criticalVitalsNotifier, VitalsState;

// ════════════════════════════════════════════════════════════════════════════
//  WAV GENERATOR — builds an in-memory two-tone medical beep (no asset file)
// ════════════════════════════════════════════════════════════════════════════
Uint8List _buildBeepWav() {
  const int sampleRate = 44100;
  const int channels = 1;
  const int bitsPerSample = 16;

  // Pattern: 200 ms @880 Hz  |  20 ms silence  |  200 ms @1046 Hz  |  1780 ms silence
  // Total cycle = 2200 ms  → repeats cleanly at typical audioplayers loop
  final List<int> pcm = [];

  void addTone(double freq, int durationMs) {
    final samples = (sampleRate * durationMs / 1000).round();
    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate;
      final sample = (math.sin(2 * math.pi * freq * t) * 28000).round().clamp(-32768, 32767);
      pcm.add(sample & 0xFF);
      pcm.add((sample >> 8) & 0xFF);
    }
  }

  void addSilence(int durationMs) {
    final samples = (sampleRate * durationMs / 1000).round();
    for (int i = 0; i < samples; i++) {
      pcm.add(0);
      pcm.add(0);
    }
  }

  addTone(880.0, 200);   // sharp tone A5
  addSilence(20);
  addTone(1046.0, 200);  // sharp tone C6
  addSilence(1780);      // pause before next repeat

  final int dataSize = pcm.length;
  final int fileSize = 36 + dataSize;

  final ByteData header = ByteData(44);
  // RIFF chunk
  header.setUint8(0,  0x52); header.setUint8(1, 0x49);
  header.setUint8(2,  0x46); header.setUint8(3, 0x46); // "RIFF"
  header.setUint32(4, fileSize - 8, Endian.little);
  header.setUint8(8,  0x57); header.setUint8(9,  0x41);
  header.setUint8(10, 0x56); header.setUint8(11, 0x45); // "WAVE"
  // fmt chunk
  header.setUint8(12, 0x66); header.setUint8(13, 0x6D);
  header.setUint8(14, 0x74); header.setUint8(15, 0x20); // "fmt "
  header.setUint32(16, 16, Endian.little); // chunk size
  header.setUint16(20, 1,  Endian.little); // PCM
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * channels * bitsPerSample ~/ 8, Endian.little);
  header.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  // data chunk
  header.setUint8(36, 0x64); header.setUint8(37, 0x61);
  header.setUint8(38, 0x74); header.setUint8(39, 0x61); // "data"
  header.setUint32(40, dataSize, Endian.little);

  final result = Uint8List(44 + dataSize);
  result.setRange(0, 44, header.buffer.asUint8List());
  result.setRange(44, 44 + dataSize, pcm);
  return result;
}

// ════════════════════════════════════════════════════════════════════════════
//  WAVEFORM PAINTER
// ════════════════════════════════════════════════════════════════════════════
class _WaveformPainter extends CustomPainter {
  final double phase;
  final bool muted;
  _WaveformPainter(this.phase, this.muted);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    const barCount = 36;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final envelope = math.sin(i / barCount * math.pi);
      final wave = muted ? 0.08 : (math.sin(i * 0.45 + phase) * 0.5 + 0.5);
      final barH = (size.height * 0.12) + (size.height * 0.78) * wave * envelope;
      final top    = (size.height - barH) / 2;
      final bottom = top + barH;

      // Red → amber gradient per bar
      final t = i / barCount;
      final color = Color.lerp(
        const Color(0xFFFF2D2D),
        const Color(0xFFFFAB40),
        t,
      )!.withValues(alpha: muted ? 0.35 : 0.9);
      paint.color = color;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.phase != phase || old.muted != muted;
}

// ════════════════════════════════════════════════════════════════════════════
//  CRITICAL ALERT OVERLAY  (entry point — stacked directly in HomeScreen)
// ════════════════════════════════════════════════════════════════════════════
class CriticalAlertOverlay extends StatefulWidget {
  const CriticalAlertOverlay({super.key});

  @override
  State<CriticalAlertOverlay> createState() => _CriticalAlertOverlayState();
}

class _CriticalAlertOverlayState extends State<CriticalAlertOverlay>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────
  late final AnimationController _blinkCtrl;   // 1 Hz strip blink
  late final AnimationController _waveCtrl;    // 60 fps waveform
  late final AnimationController _cardCtrl;    // card entrance
  late final Animation<double>   _cardScale;

  // ── Audio ──────────────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  bool _muted = false;

  // ── Clock ──────────────────────────────────────────────────────────────
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // ── Baby info ──────────────────────────────────────────────────────────
  String _babyName   = 'Baby';
  String _babyAge    = '—';
  String _babyWeight = '—';

  // ─────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Blink — 1 Hz
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Waveform — continuous phase scroll
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Card entrance
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _cardScale = CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut);
    _cardCtrl.forward();

    // Clock tick
    _clockTimer = Timer.periodic(const Duration(seconds: 1),
        (_) { if (mounted) setState(() => _now = DateTime.now()); });

    _loadBabyInfo();
    _startAudio();
  }

  Future<void> _loadBabyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _babyName   = prefs.getString('p_infantName')   ?? 'Baby';
      _babyAge    = prefs.getString('p_infantAge')    ?? '—';
      _babyWeight = prefs.getString('p_infantWeight') ?? '—';
    });
  }

  Future<void> _startAudio() async {
    try {
      final bytes = _buildBeepWav();
      await _player.setVolume(1.0);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(BytesSource(bytes));
    } catch (_) {
      // Audio unavailable — continue silently
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  void _toggleMute() async {
    setState(() => _muted = !_muted);
    if (_muted) {
      await _player.setVolume(0.0);
    } else {
      await _player.setVolume(1.0);
    }
  }

  void _dismiss() async {
    await _stopAudio();
    // Cancel the system alarm notification
    await localNotificationsPlugin.cancel(0);
    criticalAlertNotifier.value = false;
    // Clear notifier so a fresh alert can fire again next time
    criticalVitalsNotifier.value = [];
    if (mounted) Navigator.of(context).pop();
  }

  void _sos(BuildContext context) async {
    await _stopAudio();
    await localNotificationsPlugin.cancel(0);
    criticalAlertNotifier.value = false;
    criticalVitalsNotifier.value = [];
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Notifying response team…',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: const Color(0xFFFF2D2D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    launchUrl(Uri.parse('tel:+919895072644'));
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _blinkCtrl.dispose();
    _waveCtrl.dispose();
    _cardCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────────────
  String _clockStr() {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Color _vitalColor(String name, VitalsState v) {
    switch (name) {
      case 'Heart Rate':
        return (v.hr > 160 || v.hr < 100)
            ? const Color(0xFFFF2D2D)
            : const Color(0xFFFFAB40);
      case 'SpO₂':
        return v.spo2 < 89
            ? const Color(0xFFFF2D2D)
            : const Color(0xFFFFAB40);
      case 'Body Temperature':
        return v.temp > 38.5
            ? const Color(0xFFFF2D2D)
            : const Color(0xFFFFAB40);
      default:
        return const Color(0xFFFF2D2D);
    }
  }

  String _vitalValue(String name, VitalsState v) {
    switch (name) {
      case 'Heart Rate':        return '${v.hr.toStringAsFixed(0)} BPM';
      case 'SpO₂':              return '${v.spo2.toStringAsFixed(0)} %';
      case 'Body Temperature':  return '${v.temp.toStringAsFixed(1)} °C';
      default: return '—';
    }
  }

  String _vitalThreshold(String name) {
    switch (name) {
      case 'Heart Rate':        return 'Normal: 100–160 BPM';
      case 'SpO₂':              return 'Normal: ≥ 94 %';
      case 'Body Temperature':  return 'Normal: ≤ 38.0 °C';
      default: return '';
    }
  }

  IconData _vitalIcon(String name) {
    switch (name) {
      case 'Heart Rate':       return Icons.favorite_rounded;
      case 'SpO₂':             return Icons.air_rounded;
      case 'Body Temperature': return Icons.thermostat_rounded;
      default: return Icons.warning_amber_rounded;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VitalsState>(
      valueListenable: vitalsNotifier,
      builder: (context, vitals, child1) =>
          ValueListenableBuilder<List<String>>(
        valueListenable: criticalVitalsNotifier,
        builder: (context, criticalNames, child2) {
          final names = criticalNames.isEmpty
              ? <String>['Heart Rate'] // fallback — shouldn't happen
              : criticalNames;
          return _buildOverlay(context, vitals, names);
        },
      ),
    );
  }

  Widget _buildOverlay(
      BuildContext context, VitalsState vitals, List<String> names) {
    final screenH = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Blurred backdrop ──────────────────────────────────────────
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),
          ),

          // ── Content column ────────────────────────────────────────────
          Column(
            children: [
              // ── Blinking alert strip ──────────────────────────────
              AnimatedBuilder(
                animation: _blinkCtrl,
                builder: (context, child) => Container(
                  width: double.infinity,
                  color: Color.lerp(
                    const Color(0xFFCC0000),
                    const Color(0xFFFF2D2D),
                    _blinkCtrl.value,
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: 12,
                    left: 18,
                    right: 18,
                  ),
                  child: Row(
                    children: [
                      // Blinking dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withValues(alpha: _blinkCtrl.value > 0.5 ? 1.0 : 0.25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white
                                  .withValues(alpha: _blinkCtrl.value * 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '⚠  CRITICAL VITAL ALERT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Spacer(),
                      // Live clock
                      Text(
                        _clockStr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [],
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Alert card (animated entrance) ────────────────────
              Expanded(
                child: Center(
                  child: ScaleTransition(
                    scale: _cardScale,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        children: [
                          // ── Card ────────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A0A0A).withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFFF2D2D).withValues(alpha: 0.55),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF2D2D).withValues(alpha: 0.18),
                                  blurRadius: 36,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Baby info row ────────────────
                                Row(
                                  children: [
                                    // Baby avatar
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFFF2D2D)
                                            .withValues(alpha: 0.15),
                                        border: Border.all(
                                          color: const Color(0xFFFF2D2D)
                                              .withValues(alpha: 0.4),
                                          width: 2,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text('👶', style: TextStyle(fontSize: 28)),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _babyName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              _infoPill('Age', _babyAge),
                                              const SizedBox(width: 8),
                                              _infoPill('Wt', '$_babyWeight kg'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Warning icon pulse
                                    AnimatedBuilder(
                                      animation: _blinkCtrl,
                                      builder: (context, child) => Icon(
                                        Icons.report_rounded,
                                        color: Color.lerp(
                                          const Color(0xFFFF2D2D),
                                          Colors.white,
                                          _blinkCtrl.value * 0.5,
                                        ),
                                        size: 34,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),
                                _divider(),
                                const SizedBox(height: 16),

                                // ── Out-of-range vitals ──────────
                                const Text(
                                  'OUT-OF-RANGE VITALS',
                                  style: TextStyle(
                                    color: Color(0xFFFF2D2D),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...names.map((name) =>
                                    _vitalRow(name, vitals)),

                                const SizedBox(height: 16),
                                _divider(),
                                const SizedBox(height: 18),

                                // ── Waveform visualizer ──────────
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'ALARM WAVEFORM',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 10,
                                          letterSpacing: 1.4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _toggleMute,
                                      child: AnimatedBuilder(
                                        animation: _blinkCtrl,
                                        builder: (context, child) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _muted
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFFF2D2D)
                                                    .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: _muted
                                                  ? const Color(0xFF475569)
                                                  : const Color(0xFFFF2D2D)
                                                      .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _muted
                                                    ? Icons.volume_off_rounded
                                                    : Icons.volume_up_rounded,
                                                color: _muted
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFFFF2D2D),
                                                size: 14,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                _muted ? 'Muted' : 'Mute',
                                                style: TextStyle(
                                                  color: _muted
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFFFF2D2D),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Waveform canvas
                                AnimatedBuilder(
                                  animation: _waveCtrl,
                                  builder: (context, child) => SizedBox(
                                    height: 60,
                                    width: double.infinity,
                                    child: CustomPaint(
                                      painter: _WaveformPainter(
                                        _waveCtrl.value * 2 * math.pi,
                                        _muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── SOS button ───────────────────────────────
                          _ActionButton(
                            label: '🚨  SOS — Call Emergency',
                            sublabel: 'Notifies response team & stops alarm',
                            color: const Color(0xFFFF2D2D),
                            onTap: () => _sos(context),
                            blinkCtrl: _blinkCtrl,
                          ),

                          const SizedBox(height: 12),

                          // ── Acknowledge button ───────────────────────
                          _ActionButton(
                            label: '✅  I\'m with Baby — Acknowledge',
                            sublabel: 'Dismisses alert & restores dashboard',
                            color: const Color(0xFF1DB954),
                            onTap: _dismiss,
                          ),

                          SizedBox(height: math.max(20, screenH * 0.04)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Sub-widgets
  // ─────────────────────────────────────────────────────────────────────

  Widget _infoPill(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Text(
          '$label: $value',
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _divider() => Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            const Color(0xFFFF2D2D).withValues(alpha: 0.35),
            Colors.transparent,
          ]),
        ),
      );

  Widget _vitalRow(String name, VitalsState v) {
    final color = _vitalColor(name, v);
    final value = _vitalValue(name, v);
    final threshold = _vitalThreshold(name);
    final icon = _vitalIcon(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(threshold,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    )),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _blinkCtrl,
            builder: (context, child) => Text(
              value,
              style: TextStyle(
                color: Color.lerp(color, Colors.white, _blinkCtrl.value * 0.3),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  ACTION BUTTON
// ════════════════════════════════════════════════════════════════════════════
class _ActionButton extends StatefulWidget {
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  final AnimationController? blinkCtrl;

  const _ActionButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
    this.blinkCtrl,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _pressed ? 0.25 : 0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.18),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.sublabel,
                style: TextStyle(
                  color: widget.color.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.blinkCtrl != null) {
      return AnimatedBuilder(
        animation: widget.blinkCtrl!,
        builder: (_, c) => Opacity(
          opacity: 0.75 + widget.blinkCtrl!.value * 0.25,
          child: c,
        ),
        child: child,
      );
    }
    return child;
  }
}
