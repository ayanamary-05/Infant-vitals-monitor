import 'package:flutter/material.dart';

// ── Dark palette ─────────────────────────────────────────────────────────────
const Color _abg     = Color(0xFF0F172A);
const Color _asurf   = Color(0xFF1E293B);
const Color _ared    = Color(0xFFFF6B6B);
const Color _aorange = Color(0xFFFFAB40);
const Color _ablue   = Color(0xFF4F8EF7);
const Color _agreen  = Color(0xFF1DB954);
const Color _asub    = Color(0xFF94A3B8);
const Color _aborder = Color(0xFF334155);

// ── Alert model ──────────────────────────────────────────────────────────────
class _Alert {
  final String title;
  final String subtitle;
  final String valueLabel;
  final String timeLabel;
  final Color  color;
  final IconData icon;
  final bool   resolved;

  const _Alert({
    required this.title,
    required this.subtitle,
    required this.valueLabel,
    required this.timeLabel,
    required this.color,
    required this.icon,
    this.resolved = false,
  });
}

// ── Screen ───────────────────────────────────────────────────────────────────
class SpikeHistoryScreen extends StatefulWidget {
  const SpikeHistoryScreen({super.key});
  @override
  State<SpikeHistoryScreen> createState() => _SpikeHistoryScreenState();
}

class _SpikeHistoryScreenState extends State<SpikeHistoryScreen> {
  late final List<_Alert> _alerts = [
    // Active
    const _Alert(
      title: 'Heart rate above safe limit',
      subtitle: '2 min ago',
      valueLabel: '172 BPM',
      timeLabel: '2 min ago',
      color: _ared,
      icon: Icons.favorite_rounded,
    ),
    const _Alert(
      title: 'Temperature elevated',
      subtitle: '15 min ago',
      valueLabel: '38.4 °C',
      timeLabel: '15 min ago',
      color: _aorange,
      icon: Icons.thermostat_rounded,
    ),
    // Resolved
    const _Alert(
      title: 'Oxygen saturation low',
      subtitle: '92% · 1 hr ago',
      valueLabel: '92%',
      timeLabel: '1 hr ago',
      color: _ablue,
      icon: Icons.air_rounded,
      resolved: true,
    ),
    const _Alert(
      title: 'Heart rate below safe limit',
      subtitle: '94 BPM · 2 hrs ago',
      valueLabel: '94 BPM',
      timeLabel: '2 hrs ago',
      color: _ared,
      icon: Icons.favorite_rounded,
      resolved: true,
    ),
    const _Alert(
      title: 'SpO₂ critically low',
      subtitle: '89% · 5 hrs ago',
      valueLabel: '89%',
      timeLabel: '5 hrs ago',
      color: _ablue,
      icon: Icons.water_drop_rounded,
      resolved: true,
    ),
  ];

  // Tracks which active alerts have been dismissed
  late final Set<int> _dismissed = {};

  List<_Alert> get _active   => _alerts.where((a) => !a.resolved).toList();
  List<_Alert> get _resolved => _alerts.where((a) =>  a.resolved).toList();

  int get _activeCount => _active.length - _dismissed.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _abg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const Text(
                      'Alerts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_activeCount > 0)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _ared,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_activeCount active',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── ACTIVE ALERTS label ──────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text(
                  'ACTIVE ALERTS',
                  style: TextStyle(
                    color: _ared,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // ── Active alert cards ───────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final alert = _active[i];
                    final dismissed = _dismissed.contains(i);
                    if (dismissed) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ActiveAlertCard(
                        alert: alert,
                        onDismiss: () => setState(() => _dismissed.add(i)),
                      ),
                    );
                  },
                  childCount: _active.length,
                ),
              ),
            ),

            // Empty state for active
            if (_activeCount == 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _asurf,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _aborder),
                    ),
                    child: const Row(children: [
                      Icon(Icons.check_circle_rounded,
                          color: _agreen, size: 18),
                      SizedBox(width: 10),
                      Text('No active alerts right now',
                          style:
                              TextStyle(color: _asub, fontSize: 13)),
                    ]),
                  ),
                ),
              ),

            // ── RESOLVED label ───────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Text(
                  'RESOLVED',
                  style: TextStyle(
                    color: _asub,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // ── Resolved alert cards ─────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ResolvedAlertCard(alert: _resolved[i]),
                  ),
                  childCount: _resolved.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active alert card ─────────────────────────────────────────────────────────
class _ActiveAlertCard extends StatelessWidget {
  final _Alert alert;
  final VoidCallback onDismiss;
  const _ActiveAlertCard({required this.alert, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alert.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alert.color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: alert.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(alert.icon, color: alert.color, size: 18),
          ),
          const SizedBox(width: 14),

          // Title + value + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: alert.color, size: 14),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      alert.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  alert.valueLabel,
                  style: TextStyle(
                    color: alert.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.timeLabel,
                  style:
                      const TextStyle(color: _asub, fontSize: 11),
                ),
              ],
            ),
          ),

          // Dismiss button
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _asurf,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _aborder),
              ),
              child: const Text(
                'Dismiss',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resolved alert card ───────────────────────────────────────────────────────
class _ResolvedAlertCard extends StatelessWidget {
  final _Alert alert;
  const _ResolvedAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _asurf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _aborder),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: alert.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(alert.icon, color: alert.color, size: 18),
          ),
          const SizedBox(width: 14),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.subtitle,
                  style:
                      const TextStyle(color: _asub, fontSize: 11),
                ),
              ],
            ),
          ),

          // Green resolved check
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _agreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: _agreen, size: 20),
          ),
        ],
      ),
    );
  }
}