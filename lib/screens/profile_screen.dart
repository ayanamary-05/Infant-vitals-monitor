import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color _bg      = Color(0xFF0F172A);
const Color _surface = Color(0xFF1E293B);
const Color _green   = Color(0xFF1DB954);
const Color _red     = Color(0xFFFF6B6B);
const Color _subtext = Color(0xFF94A3B8);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final user    = FirebaseAuth.instance.currentUser;
    final name    = user?.displayName ?? 'User';
    final email   = user?.email ?? '—';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final verified = user?.emailVerified ?? false;
    final since   = user?.metadata.creationTime;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Avatar ───────────────────────────────────
          Center(
            child: Column(children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _green.withValues(alpha: 0.4), width: 2)),
                child: Center(
                  child: Text(initial,
                      style: TextStyle(
                          color: _green,
                          fontSize: 38,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 14),
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(email,
                  style: const TextStyle(color: _subtext, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 32),

          // ── Info tiles ───────────────────────────────
          _InfoTile(
              icon: Icons.person_outline_rounded,
              label: 'Full Name',
              value: name),
          const SizedBox(height: 10),
          _InfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: email),
          const SizedBox(height: 10),
          _InfoTile(
              icon: Icons.verified_user_outlined,
              label: 'Email Verified',
              value: verified ? '✓ Verified' : '✗ Not verified',
              valueColor: verified ? _green : _red),
          const SizedBox(height: 10),
          _InfoTile(
              icon: Icons.calendar_today_outlined,
              label: 'Member Since',
              value: since != null ? _fmt(since) : '—'),
          const SizedBox(height: 32),

          // ── Change password ──────────────────────────
          _ActionTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: () async {
              final em = FirebaseAuth.instance.currentUser?.email;
              if (em == null) return;
              await FirebaseAuth.instance
                  .sendPasswordResetEmail(email: em);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      const Text('Password reset email sent.'),
                  backgroundColor: _green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ));
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _InfoTile({required this.icon, required this.label,
      required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: _subtext, size: 18),
        const SizedBox(width: 14),
        Expanded(child: Text(label,
            style: const TextStyle(color: _subtext, fontSize: 13))),
        Text(value,
            style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: _green, size: 18),
          const SizedBox(width: 14),
          Expanded(child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14))),
          const Icon(Icons.chevron_right_rounded, color: _subtext, size: 18),
        ]),
      ),
    );
  }
}