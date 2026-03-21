import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Accent colours (not theme-able — intentional
//  brand / vital-sign colours)
// ─────────────────────────────────────────────
const _teal      = Color(0xFF14B8A6);
const _alertRed  = Color(0xFFF87171);
const _roseColor = Color(0xFFFF6B8A);

// ─────────────────────────────────────────────
//  Theme-aware colour helpers
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
//  ProfileScreen  (StatefulWidget so fields
//  are mutable when the user saves edits)
// ─────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Infant fields ──────────────────────────
  String infantName      = 'Baby Sarah';
  String infantGender    = 'Female';
  String infantAge       = '3 months';
  String infantWeight    = '4.2 kg';
  String infantDob       = 'December 13, 2025';
  String infantBloodType = 'O+';
  String infantAllergies = 'None known';
  String infantNotes     = 'Healthy, regular checkups on schedule';

  // ── Caregiver fields ───────────────────────
  String caregiverName      = 'Jane Doe';
  String caregiverRole      = 'Mother';
  String caregiverEmail     = 'jane.doe@email.com';
  String caregiverPhone     = '+254 712 345 678';
  String caregiverAddress   = 'Nairobi, Kenya';
  String caregiverEmergency = 'John Doe · +254 713 456 789';

  // ── Open Infant edit sheet ─────────────────
  void _editInfant() {
    final fields = [
      _FieldDef(label: 'Name',         icon: Icons.badge_outlined,          initial: infantName),
      _FieldDef(label: 'Gender',       icon: Icons.wc_outlined,             initial: infantGender),
      _FieldDef(label: 'Age',          icon: Icons.cake_outlined,           initial: infantAge),
      _FieldDef(label: 'Weight',       icon: Icons.monitor_weight_outlined, initial: infantWeight),
      _FieldDef(label: 'Date of Birth',icon: Icons.calendar_today_outlined, initial: infantDob),
      _FieldDef(label: 'Blood Type',   icon: Icons.bloodtype_outlined,      initial: infantBloodType),
      _FieldDef(label: 'Allergies',    icon: Icons.favorite_border_rounded, initial: infantAllergies),
      _FieldDef(label: 'Medical Notes',icon: Icons.note_alt_outlined,       initial: infantNotes,
                maxLines: 3),
    ];

    _openEditSheet(
      context: context,
      title: 'Edit Infant Profile',
      accentColor: context.primary,
      avatarIcon: Icons.child_care_rounded,
      fields: fields,
      onSave: (values) {
        setState(() {
          infantName      = values[0];
          infantGender    = values[1];
          infantAge       = values[2];
          infantWeight    = values[3];
          infantDob       = values[4];
          infantBloodType = values[5];
          infantAllergies = values[6];
          infantNotes     = values[7];
        });
      },
    );
  }

  // ── Open Caregiver edit sheet ──────────────
  void _editCaregiver() {
    final fields = [
      _FieldDef(label: 'Name',             icon: Icons.badge_outlined,           initial: caregiverName),
      _FieldDef(label: 'Relationship',     icon: Icons.person_outline_rounded,   initial: caregiverRole),
      _FieldDef(label: 'Email',            icon: Icons.email_outlined,            initial: caregiverEmail,
                keyboardType: TextInputType.emailAddress),
      _FieldDef(label: 'Phone',            icon: Icons.phone_outlined,            initial: caregiverPhone,
                keyboardType: TextInputType.phone),
      _FieldDef(label: 'Address',          icon: Icons.location_on_outlined,      initial: caregiverAddress),
      _FieldDef(label: 'Emergency Contact',icon: Icons.emergency_outlined,        initial: caregiverEmergency),
    ];

    _openEditSheet(
      context: context,
      title: 'Edit Caregiver Profile',
      accentColor: _teal,
      avatarIcon: Icons.person_rounded,
      fields: fields,
      onSave: (values) {
        setState(() {
          caregiverName      = values[0];
          caregiverRole      = values[1];
          caregiverEmail     = values[2];
          caregiverPhone     = values[3];
          caregiverAddress   = values[4];
          caregiverEmergency = values[5];
        });
      },
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
              '$infantName · Caregiver info',
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
              name: infantName,
              subtitle: '$infantGender · $infantAge · $infantWeight',
              showOnlineDot: true,
              onEdit: _editInfant,
              details: [
                _DetailData(icon: Icons.calendar_today_outlined, label: 'Date of Birth', value: infantDob),
                _DetailData(icon: Icons.monitor_weight_outlined,  label: 'Weight',        value: infantWeight),
                _DetailData(icon: Icons.bloodtype_outlined,        label: 'Blood Type',    value: infantBloodType),
                _DetailData(icon: Icons.favorite_border_rounded,   label: 'Allergies',     value: infantAllergies),
                _DetailData(icon: Icons.note_alt_outlined,         label: 'Medical Notes', value: infantNotes),
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
              name: caregiverName,
              subtitle: caregiverRole,
              subtitleIsChip: true,
              chipColor: _teal,
              onEdit: _editCaregiver,
              details: [
                _DetailData(icon: Icons.person_outline_rounded, label: 'Relationship',      value: caregiverRole),
                _DetailData(icon: Icons.email_outlined,          label: 'Email',             value: caregiverEmail),
                _DetailData(icon: Icons.phone_outlined,           label: 'Phone',             value: caregiverPhone),
                _DetailData(icon: Icons.location_on_outlined,     label: 'Address',           value: caregiverAddress),
                _DetailData(icon: Icons.emergency_outlined,       label: 'Emergency Contact', value: caregiverEmergency),
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
//  Edit sheet launcher  (shared by both cards)
// ─────────────────────────────────────────────
class _FieldDef {
  final String label;
  final IconData icon;
  final String initial;
  final int maxLines;
  final TextInputType keyboardType;

  const _FieldDef({
    required this.label,
    required this.icon,
    required this.initial,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });
}

void _openEditSheet({
  required BuildContext context,
  required String title,
  required Color accentColor,
  required IconData avatarIcon,
  required List<_FieldDef> fields,
  required void Function(List<String> values) onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditBottomSheet(
      title: title,
      accentColor: accentColor,
      avatarIcon: avatarIcon,
      fields: fields,
      onSave: onSave,
    ),
  );
}

// ─────────────────────────────────────────────
//  Edit Bottom Sheet widget
// ─────────────────────────────────────────────
class _EditBottomSheet extends StatefulWidget {
  final String title;
  final Color accentColor;
  final IconData avatarIcon;
  final List<_FieldDef> fields;
  final void Function(List<String> values) onSave;

  const _EditBottomSheet({
    required this.title,
    required this.accentColor,
    required this.avatarIcon,
    required this.fields,
    required this.onSave,
  });

  @override
  State<_EditBottomSheet> createState() => _EditBottomSheetState();
}

class _EditBottomSheetState extends State<_EditBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.fields
        .map((f) => TextEditingController(text: f.initial))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(_controllers.map((c) => c.text.trim()).toList());
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: widget.accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final Color accent = widget.accentColor;

    return Container(
      margin: EdgeInsets.only(top: mq.padding.top + 24),
      decoration: BoxDecoration(
        color: context.bgPage,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── drag handle ─────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── header row ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: accent.withOpacity(0.15),
                  child: Icon(widget.avatarIcon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textMain,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: context.textSub),
                ),
              ],
            ),
          ),

          Divider(color: context.dividerColor, height: 24),

          // ── scrollable form fields ───────────
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20, right: 20,
                bottom: mq.viewInsets.bottom + 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    for (int i = 0; i < widget.fields.length; i++) ...[
                      _buildField(
                        context: context,
                        fieldDef: widget.fields[i],
                        controller: _controllers[i],
                        accent: accent,
                      ),
                      if (i < widget.fields.length - 1)
                        const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 28),

                    // ── Save button ─────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Cancel button ───────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: context.textSub,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required _FieldDef fieldDef,
    required TextEditingController controller,
    required Color accent,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: fieldDef.maxLines,
      keyboardType: fieldDef.keyboardType,
      style: TextStyle(
        fontSize: 14,
        color: context.textMain,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: fieldDef.label,
        labelStyle: TextStyle(fontSize: 13, color: context.textSub),
        prefixIcon: Icon(fieldDef.icon, size: 18, color: accent),
        filled: true,
        fillColor: context.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _alertRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _alertRed, width: 1.8),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return '${fieldDef.label} cannot be empty';
        }
        return null;
      },
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
//  Detail data model
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
//  Generic _ProfileCard
// ─────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final IconData  sectionIcon;
  final Color     sectionIconColor;
  final IconData  avatarIcon;
  final Color     avatarIconColor;
  final String    name;
  final String    subtitle;
  final bool      subtitleIsChip;
  final Color?    chipColor;
  final bool      showOnlineDot;
  final List<_DetailData> details;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.sectionIcon,
    required this.sectionIconColor,
    required this.avatarIcon,
    required this.avatarIconColor,
    required this.name,
    required this.subtitle,
    required this.details,
    required this.onEdit,
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
                _EditButton(accentColor: sectionIconColor, onPressed: onEdit),
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
//  Chip label
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
//  Edit button  (now wired to onPressed)
// ─────────────────────────────────────────────
class _EditButton extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onPressed;
  const _EditButton({required this.accentColor, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
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

    return Column(
      children: [
        SizedBox(
          height: 80,
          child: Row(
            children: [
              Expanded(child: SummaryCard(data: items[0])),
              const SizedBox(width: 10),
              Expanded(child: SummaryCard(data: items[1])),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: Row(
            children: [
              Expanded(child: SummaryCard(data: items[2])),
              const SizedBox(width: 10),
              Expanded(child: SummaryCard(data: items[3])),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.title,
            style: TextStyle(
              fontSize: 11,
              color: context.textSub,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.textMain,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}