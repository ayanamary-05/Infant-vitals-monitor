import 'package:flutter/material.dart';

const Color _bg      = Color(0xFF0F172A);
const Color _surface = Color(0xFF1E293B);
const Color _green   = Color(0xFF1DB954);
const Color _blue    = Color(0xFF4F8EF7);
const Color _purple  = Color(0xFFA78BFA);
const Color _orange  = Color(0xFFFFAB40);
const Color _subtext = Color(0xFF94A3B8);

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Details',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: const [
          _InfoCard(
            icon: Icons.favorite_rounded, color: _green,
            title: 'Heart Rate',
            subtitle: 'Measures heartbeats per minute via pulse oximeter.',
            detail:
                'Normal for neonates: 120–160 bpm.\nBelow 100 or above 180 triggers an alert.\nResting values above 160 may indicate distress.',
          ),
          SizedBox(height: 14),
          _InfoCard(
            icon: Icons.water_drop_rounded, color: _blue,
            title: 'SpO₂ — Oxygen Saturation',
            subtitle:
                'Percentage of haemoglobin actively carrying oxygen.',
            detail:
                'Normal: 95–100%.\nReadings below 93% require immediate clinical attention.\nPersistent low SpO₂ may indicate respiratory distress.',
          ),
          SizedBox(height: 14),
          _InfoCard(
            icon: Icons.air_rounded, color: _purple,
            title: 'Respiratory Rate',
            subtitle: 'Number of breaths taken per minute.',
            detail:
                'Normal for neonates: 30–60 br/min.\nTachypnoea (>60) or apnoea (<20) will trigger alerts.\nIrregular patterns should be reported immediately.',
          ),
          SizedBox(height: 14),
          _InfoCard(
            icon: Icons.thermostat_rounded, color: _orange,
            title: 'Temperature',
            subtitle: 'Core body temperature measured via skin sensor.',
            detail:
                'Normal: 36.5–37.5 °C.\nHypothermia (<36°C) and fever (>38°C) are flagged.\nNeonates are especially vulnerable to temperature swings.',
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle, detail;

  const _InfoCard({
    required this.icon,  required this.color,
    required this.title, required this.subtitle,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: _subtext, fontSize: 12)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          Text(detail,
              style: const TextStyle(
                  color: _subtext, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}