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
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Static sample data
// ─────────────────────────────────────────────

// Infant
const _infantName      = 'Baby Sarah';
const _infantGender    = 'Female';
const _infantAge       = '3 months';
const _infantWeight    = '4.2 kg';
const _infantDob       = 'December 13, 2025';
const _infantBloodType = 'O+';
const _infantAllergies = 'None known';
const _infantNotes     = 'Healthy, regular checkups on schedule';

// Caregiver
const _caregiverName      = 'Jane Doe';
const _caregiverRole      = 'Mother';
const _caregiverEmail     = 'jane.doe@email.com';
const _caregiverPhone     = '+254 712 345 678';
const _caregiverAddress   = 'Nairobi, Kenya';
const _caregiverEmergency = 'John Doe · +254 713 456 789';

// ─────────────────────────────────────────────
//  Accent colours (not theme-able — intentional
//  brand / vital-sign colours)
// ─────────────────────────────────────────────
const _teal      = Color(0xFF14B8A6);
const _alertRed  = Color(0xFFF87171);
const _roseColor = Color(0xFFFF6B8A);

// ─────────────────────────────────────────────
//  Theme-aware colour helpers
//  (call inside build methods that have context)
// ─────────────────────────────────────────────
extension _AppTheme on BuildContext {
  ColorScheme get cs     => Theme.of(this).colorScheme;
  TextTheme   get tt     => Theme.of(this).textTheme;
  Color get bgPage       => Theme.of(this).scaffoldBackgroundColor;
  Color get bgCard       => cs.surface;
  Color get textMain     => tt.bodyLarge?.color    ?? cs.onSurface;
  Color get textSub      => tt.bodySmall?.color    ?? cs.onSurfaceVariant;
  Color get dividerColor => Theme.of(this).dividerColor;
  Color get primary      => cs.primary;
}

// ─────────────────────────────────────────────
//  ProfileScreen
// ─────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPage,
      appBar: AppBar(
        backgroundColor: context.bgCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: TextStyle(
                color: context.textMain,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Baby Sarah · Caregiver info',
              style: TextStyle(color: context.textSub, fontSize: 11),
            ),
          ],
        ),
        toolbarHeight: 64,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.dividerColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Infant profile ───────────────────
            _SectionLabel(label: 'Infant Profile'),
            const SizedBox(height: 12),
            _ProfileCard(
              sectionIcon: Icons.child_care_rounded,
              sectionIconColor: context.primary,
              avatarIcon: Icons.child_care_rounded,
              avatarIconColor: context.primary,
              name: _infantName,
              subtitle: '$_infantGender · $_infantAge · $_infantWeight',
              showOnlineDot: true,
              details: const [
                _DetailData(icon: Icons.calendar_today_outlined, label: 'Date of Birth', value: _infantDob),
                _DetailData(icon: Icons.monitor_weight_outlined,  label: 'Weight',        value: _infantWeight),
                _DetailData(icon: Icons.bloodtype_outlined,        label: 'Blood Type',    value: _infantBloodType),
                _DetailData(icon: Icons.favorite_border_rounded,   label: 'Allergies',     value: _infantAllergies),
                _DetailData(icon: Icons.note_alt_outlined,         label: 'Medical Notes', value: _infantNotes),
              ],
            ),

            const SizedBox(height: 20),

            // ── Caregiver profile ────────────────
            _SectionLabel(label: 'Caregiver Profile'),
            const SizedBox(height: 12),
            _ProfileCard(
              sectionIcon: Icons.person_outline_rounded,
              sectionIconColor: _teal,
              avatarIcon: Icons.person_rounded,
              avatarIconColor: _teal,
              name: _caregiverName,
              subtitle: _caregiverRole,
              subtitleIsChip: true,
              chipColor: _teal,
              details: const [
                _DetailData(icon: Icons.person_outline_rounded, label: 'Relationship',      value: _caregiverRole),
                _DetailData(icon: Icons.email_outlined,          label: 'Email',             value: _caregiverEmail),
                _DetailData(icon: Icons.phone_outlined,           label: 'Phone',             value: _caregiverPhone),
                _DetailData(icon: Icons.location_on_outlined,     label: 'Address',           value: _caregiverAddress),
                _DetailData(icon: Icons.emergency_outlined,       label: 'Emergency Contact', value: _caregiverEmergency),
              ],
            ),

            const SizedBox(height: 20),

            // ── Monitoring summary ───────────────
            _SectionLabel(label: 'Monitoring Summary'),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: MonitoringSummaryGrid(),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Section label
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            color: context.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textMain,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Detail data model  (plain data class)
// ─────────────────────────────────────────────
class _DetailData {
  final IconData icon;
  final String label;
  final String value;
  const _DetailData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

// ─────────────────────────────────────────────
//  Generic _ProfileCard  — used for BOTH infant
//  and caregiver, eliminating duplication
// ─────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final IconData  sectionIcon;
  final Color     sectionIconColor;
  final IconData  avatarIcon;
  final Color     avatarIconColor;
  final String    name;
  final String    subtitle;
  final bool      subtitleIsChip;   // true → render as pill badge
  final Color?    chipColor;
  final bool      showOnlineDot;
  final List<_DetailData> details;

  const _ProfileCard({
    required this.sectionIcon,
    required this.sectionIconColor,
    required this.avatarIcon,
    required this.avatarIconColor,
    required this.name,
    required this.subtitle,
    required this.details,
    this.subtitleIsChip = false,
    this.chipColor,
    this.showOnlineDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header (icon + title + Edit) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(sectionIcon, size: 18, color: sectionIconColor),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textMain,
                      ),
                    ),
                  ],
                ),
                _EditButton(accentColor: sectionIconColor),
              ],
            ),
          ),

          // ── Avatar row ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: avatarIconColor.withOpacity(0.15),
                      child: Icon(avatarIcon, size: 30, color: avatarIconColor),
                    ),
                    if (showOnlineDot)
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: _teal,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.bgCard, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    subtitleIsChip
                        ? _ChipLabel(label: subtitle, color: chipColor ?? context.primary)
                        : Text(
                            subtitle,
                            style: TextStyle(fontSize: 12, color: context.textSub),
                          ),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: context.dividerColor, height: 20, indent: 16, endIndent: 16),

          // ── Detail rows ─────────────────────────
          ...details.asMap().entries.map((e) {
            final isLast = e.key == details.length - 1;
            final d = e.value;
            return _DetailRow(
              icon: d.icon,
              label: d.label,
              value: d.value,
              isLast: isLast,
            );
          }),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Chip label  (used for caregiver role badge)
// ─────────────────────────────────────────────
class _ChipLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _ChipLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Detail row
// ─────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: context.textSub),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 13, color: context.textSub)),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textMain,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: context.dividerColor, height: 1, indent: 44),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Edit button  (accent colour passed in so
//  it matches the card it belongs to)
// ─────────────────────────────────────────────
class _EditButton extends StatelessWidget {
  final Color accentColor;
  const _EditButton({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.edit_outlined, size: 14),
      label: const Text('Edit'),
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: accentColor.withOpacity(0.3)),
        ),
        backgroundColor: accentColor.withOpacity(0.08),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Monitoring Summary Grid
// ─────────────────────────────────────────────
class MonitoringSummaryGrid extends StatelessWidget {
  const MonitoringSummaryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryData(
        icon: Icons.calendar_month_rounded,
        iconColor: context.primary,
        title: 'Days Monitored',
        value: '47',
      ),
      _SummaryData(
        icon: Icons.notifications_active_rounded,
        iconColor: _alertRed,
        title: 'Alerts Triggered',
        value: '12',
      ),
      _SummaryData(
        icon: Icons.favorite_rounded,
        iconColor: _roseColor,
        title: 'Avg Heart Rate',
        value: '128 BPM',
      ),
      _SummaryData(
        icon: Icons.event_available_rounded,
        iconColor: _teal,
        title: 'Last Checkup',
        value: 'Mar 5',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: items.map((s) => SummaryCard(data: s)).toList(),
    );
  }
}

// ─────────────────────────────────────────────
//  Summary data model
// ─────────────────────────────────────────────
class _SummaryData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _SummaryData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });
}

// ─────────────────────────────────────────────
//  Summary Card  (theme-aware)
// ─────────────────────────────────────────────
class SummaryCard extends StatelessWidget {
  final _SummaryData data;
  const SummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.06,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon with themed tinted background
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: data.iconColor.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSub,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textMain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}