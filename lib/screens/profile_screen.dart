import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_app/screens/app_strings.dart';
import 'package:first_app/main.dart' show languageNotifier;

// ─────────────────────────────────────────────
//  Accent colours
// ─────────────────────────────────────────────
const _teal      = Color(0xFF14B8A6);
const _alertRed  = Color(0xFFF87171);
const _roseColor = Color(0xFFFF6B8A);
const _purple    = Color(0xFFA78BFA);

// ─────────────────────────────────────────────
//  Theme-aware helpers
// ─────────────────────────────────────────────
extension _AppTheme on BuildContext {
  ColorScheme get cs     => Theme.of(this).colorScheme;
  TextTheme   get tt     => Theme.of(this).textTheme;
  Color get bgCard       => cs.surface;
  Color get textMain     => tt.bodyLarge?.color    ?? cs.onSurface;
  Color get textSub      => tt.bodySmall?.color    ?? cs.onSurfaceVariant;
  Color get dividerColor => Theme.of(this).dividerColor;
  Color get primary      => cs.primary;
}

// ─────────────────────────────────────────────
//  Growth entry model (weight + height)
// ─────────────────────────────────────────────
class _GrowthEntry {
  DateTime date;
  double weightKg;
  double? heightCm;
  _GrowthEntry({required this.date, required this.weightKg, this.heightCm});

  String toPrefsString() => '${date.millisecondsSinceEpoch}:$weightKg:${heightCm ?? ''}' ;
  static _GrowthEntry fromPrefsString(String s) {
    final parts = s.split(':');
    return _GrowthEntry(
      date: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0])),
      weightKg: double.parse(parts[1]),
      heightCm: parts.length > 2 && parts[2].isNotEmpty ? double.tryParse(parts[2]) : null,
    );
  }
}

// ─────────────────────────────────────────────
//  Milestone vaccines
// ─────────────────────────────────────────────
const List<String> kMilestoneVaccines = [
  'BCG (Birth)',
  'Hepatitis B (Birth)',
  'OPV (6 weeks)',
  'DTP (6 weeks)',
  'Hib (6 weeks)',
  'Rotavirus (6 weeks)',
  'PCV (6 weeks)',
  'OPV (10 weeks)',
  'DTP (10 weeks)',
  'OPV (14 weeks)',
  'DTP (14 weeks)',
  'MMR (9 months)',
  'Yellow Fever (9 months)',
  'Vitamin A (6 months)',
];

// ─────────────────────────────────────────────
//  ProfileScreen
// ─────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Infant fields ──────────────────────────
  String infantName        = 'Sarah';
  String infantGender      = 'Female';
  String infantAge         = '3 months';
  String infantWeight      = '4.2 kg';
  String infantDob         = 'December 13, 2025';
  String infantBloodType   = 'O+';
  String infantAllergies   = 'None known';
  String infantNotes       = 'Healthy, regular checkups on schedule';
  String doctorName        = 'Dr. Anjali Mehta';
  String doctorPhone       = '+91 98765 43210';

  // ── Caregiver fields ───────────────────────
  String caregiverName      = 'Jane Doe';
  String caregiverRole      = 'Mother';
  String caregiverEmail     = 'jane.doe@email.com';
  String caregiverPhone     = '+254 712 345 678';
  String caregiverAddress   = 'Nairobi, Kenya';
  String caregiverEmergency = 'John Doe · +91 9895072644';

  String _userRole = 'Parent';
  List<String> _appointedCaregivers = [];
  
  // ── Growth tracker ─────────────────────────
  List<_GrowthEntry> _growthHistory = [];

  // ── Vaccination tracker ────────────────────
  Set<String> _vaccinatedSet = {};

  // ── Next checkup ───────────────────────────
  String nextCheckup = 'Not scheduled';

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
    languageNotifier.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    languageNotifier.removeListener(_rebuild);
    super.dispose();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      infantName        = prefs.getString('p_infantName')        ?? infantName;
      infantGender      = prefs.getString('p_infantGender')      ?? infantGender;
      infantAge         = prefs.getString('p_infantAge')         ?? infantAge;
      infantWeight      = prefs.getString('p_infantWeight')      ?? infantWeight;
      infantDob         = prefs.getString('p_infantDob')         ?? infantDob;
      infantBloodType   = prefs.getString('p_infantBloodType')   ?? infantBloodType;
      infantAllergies   = prefs.getString('p_infantAllergies')   ?? infantAllergies;
      infantNotes       = prefs.getString('p_infantNotes')       ?? infantNotes;
      doctorName        = prefs.getString('p_doctorName')        ?? doctorName;
      doctorPhone       = prefs.getString('p_doctorPhone')       ?? doctorPhone;
      caregiverName     = prefs.getString('p_caregiverName')     ?? caregiverName;
      caregiverRole     = prefs.getString('p_caregiverRole')     ?? caregiverRole;
      caregiverEmail    = prefs.getString('p_caregiverEmail')    ?? caregiverEmail;
      caregiverPhone    = prefs.getString('p_caregiverPhone')    ?? caregiverPhone;
      caregiverAddress  = prefs.getString('p_caregiverAddress')  ?? caregiverAddress;
      caregiverEmergency = prefs.getString('p_caregiverEmergency') ?? caregiverEmergency;
      nextCheckup       = prefs.getString('p_nextCheckup')       ?? nextCheckup;
      _userRole         = prefs.getString('user_role')           ?? 'Parent';
      _appointedCaregivers = prefs.getStringList('p_appointed_caregivers') ?? [];

      final entries = prefs.getStringList('p_growthHistory') ?? [];
      _growthHistory = entries.isEmpty
          ? [
              _GrowthEntry(date: DateTime(2025, 12, 13), weightKg: 3.5, heightCm: 49.0),
              _GrowthEntry(date: DateTime(2026, 1, 10),  weightKg: 3.9, heightCm: 52.0),
              _GrowthEntry(date: DateTime(2026, 2, 5),   weightKg: 4.2, heightCm: 55.0),
              _GrowthEntry(date: DateTime(2026, 3, 1),   weightKg: 4.5, heightCm: 58.0),
            ]
          : entries.map(_GrowthEntry.fromPrefsString).toList();

      final vaccList = prefs.getStringList('p_vaccinated') ?? [];
      _vaccinatedSet = vaccList.toSet();
    });
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('p_infantName', infantName);
    await prefs.setString('p_infantGender', infantGender);
    await prefs.setString('p_infantAge', infantAge);
    await prefs.setString('p_infantWeight', infantWeight);
    await prefs.setString('p_infantDob', infantDob);
    await prefs.setString('p_infantBloodType', infantBloodType);
    await prefs.setString('p_infantAllergies', infantAllergies);
    await prefs.setString('p_infantNotes', infantNotes);
    await prefs.setString('p_doctorName', doctorName);
    await prefs.setString('p_doctorPhone', doctorPhone);
    await prefs.setString('p_caregiverName', caregiverName);
    await prefs.setString('p_caregiverRole', caregiverRole);
    await prefs.setString('p_caregiverEmail', caregiverEmail);
    await prefs.setString('p_caregiverPhone', caregiverPhone);
    await prefs.setString('p_caregiverAddress', caregiverAddress);
    await prefs.setString('p_caregiverEmergency', caregiverEmergency);
    await prefs.setString('p_nextCheckup', nextCheckup);
    await prefs.setStringList('p_growthHistory',
        _growthHistory.map((e) => e.toPrefsString()).toList());
    await prefs.setStringList('p_vaccinated', _vaccinatedSet.toList());
  }

  // ── Open Infant edit sheet ─────────────────
  void _editInfant() {
    final fields = [
      _FieldDef(label: 'Name',          icon: Icons.badge_outlined,          initial: infantName),
      _FieldDef(label: 'Gender',        icon: Icons.wc_outlined,             initial: infantGender),
      _FieldDef(label: 'Age',           icon: Icons.cake_outlined,           initial: infantAge),
      _FieldDef(label: 'Weight',        icon: Icons.monitor_weight_outlined,  initial: infantWeight),
      _FieldDef(label: 'Date of Birth', icon: Icons.calendar_today_outlined,  initial: infantDob),
      _FieldDef(label: 'Blood Type',    icon: Icons.bloodtype_outlined,       initial: infantBloodType),
      _FieldDef(label: 'Allergies',     icon: Icons.favorite_border_rounded,  initial: infantAllergies),
      _FieldDef(label: 'Medical Notes', icon: Icons.note_alt_outlined,        initial: infantNotes, maxLines: 3),
      _FieldDef(label: 'Doctor Name',   icon: Icons.medical_services_outlined, initial: doctorName),
      _FieldDef(label: 'Doctor Phone',  icon: Icons.phone_outlined,           initial: doctorPhone,
                keyboardType: TextInputType.phone),
    ];
    _openEditSheet(
      context: context,
      title: 'Edit Infant Profile',
      accentColor: context.primary,
      avatarIcon: Icons.child_care_rounded,
      fields: fields,
      onSave: (values) {
        setState(() {
          infantName       = values[0];
          infantGender     = values[1];
          infantAge        = values[2];
          infantWeight     = values[3];
          infantDob        = values[4];
          infantBloodType  = values[5];
          infantAllergies  = values[6];
          infantNotes      = values[7];
          doctorName       = values[8];
          doctorPhone      = values[9];
        });
        _saveToPrefs();
      },
    );
  }

  // ── Open Caregiver edit sheet ──────────────
  void _editCaregiver() {
    final fields = [
      _FieldDef(label: 'Name',             icon: Icons.badge_outlined,          initial: FirebaseAuth.instance.currentUser?.displayName ?? caregiverName),
      _FieldDef(label: 'Relationship',     icon: Icons.person_outline_rounded,  initial: caregiverRole),
      _FieldDef(label: 'Email',            icon: Icons.email_outlined,          initial: FirebaseAuth.instance.currentUser?.email ?? caregiverEmail,
                keyboardType: TextInputType.emailAddress),
      _FieldDef(label: 'Phone',            icon: Icons.phone_outlined,          initial: caregiverPhone,
                keyboardType: TextInputType.phone),
      _FieldDef(label: 'Emergency Contact',icon: Icons.emergency_outlined,      initial: caregiverEmergency),
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
          caregiverEmergency = values[4];
        });
        _saveToPrefs();
      },
    );
  }


  void _addCaregiver() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => const _CaregiverDialog(),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _appointedCaregivers.add(result);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('p_appointed_caregivers', _appointedCaregivers);
    }
  }

  // ── Add growth entry (weight + optional height) ──────
  void _addGrowthEntry() async {
    final result = await showDialog<_GrowthEntry>(
      context: context,
      builder: (ctx) => const _GrowthEntryDialog(),
    );

    if (result != null) {
      setState(() {
        _growthHistory.add(result);
        _growthHistory.sort((a, b) => a.date.compareTo(b.date));
      });
      _saveToPrefs();
    }
  }

  // ── Alert breakdown modal ─────────────────────────────
  void _showAlertBreakdown(BuildContext ctx) {
    final breakdownData = [
      _AlertBreakdownItem(type: AppStrings.t('heart_rate'),   icon: Icons.favorite_rounded,          color: _alertRed, count: 7, lastDate: 'Mar 20'),
      _AlertBreakdownItem(type: AppStrings.t('body_temperature'), icon: Icons.thermostat_rounded,   color: _roseColor, count: 3, lastDate: 'Mar 15'),
      _AlertBreakdownItem(type: AppStrings.t('oxygen_saturation'), icon: Icons.air_rounded,         color: _teal,     count: 2, lastDate: 'Mar 10'),
    ];
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ctx.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ctx.dividerColor),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.bar_chart_rounded, color: _alertRed, size: 20),
              const SizedBox(width: 10),
              Text(AppStrings.t('alert_breakdown'),
                  style: TextStyle(color: ctx.textMain, fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),
            ...breakdownData.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.type, style: TextStyle(color: ctx.textMain, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('${AppStrings.t('date')}: ${item.lastDate}', style: TextStyle(color: ctx.textSub, fontSize: 11)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${item.count}x', style: TextStyle(color: item.color, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset('assets/images/profile_bg.jpg', fit: BoxFit.cover),
        ),
        Container(color: Colors.black.withValues(alpha: 0.70)),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t('profile'),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text('${infantName.split(' ').first} \u00b7 ${AppStrings.t('caregiver_info')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
            toolbarHeight: 64,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: Colors.white24),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(label: 'Infant - ${infantName.split(' ').first}'),
                const SizedBox(height: 12),
                _ProfileCard(
                  sectionIcon: Icons.child_care_rounded,
                  sectionIconColor: _teal,
                  avatarIcon: Icons.child_care_rounded,
                  avatarIconColor: _teal,
                  name: infantName,
                  subtitle: '$infantGender \u00b7 $infantAge \u00b7 $infantWeight',
                  showOnlineDot: true,
                  onEdit: _editInfant,
                  details: [
                    _DetailData(icon: Icons.calendar_today_outlined, label: 'Date of Birth', value: infantDob),
                    _DetailData(icon: Icons.monitor_weight_outlined,  label: 'Weight',       value: infantWeight),
                    _DetailData(icon: Icons.bloodtype_outlined,        label: 'Blood Type',   value: infantBloodType),
                    _DetailData(icon: Icons.favorite_border_rounded,   label: 'Allergies',    value: infantAllergies),
                    _DetailData(icon: Icons.note_alt_outlined,         label: 'Medical Notes',value: infantNotes),
                    _DetailData(icon: Icons.medical_services_outlined, label: 'Doctor',       value: doctorName),
                    _DetailData(icon: Icons.phone_outlined,            label: 'Doctor Phone', value: doctorPhone),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionLabel(label: _userRole == 'Parent' ? 'Parent Profile' : AppStrings.t('caregiver_profile')),
                const SizedBox(height: 12),
                _ProfileCard(
                  sectionIcon: Icons.person_outline_rounded,
                  sectionIconColor: _teal,
                  avatarIcon: Icons.person_rounded,
                  avatarIconColor: _teal,
                  name: FirebaseAuth.instance.currentUser?.displayName ?? caregiverName,
                  subtitle: _userRole,
                  subtitleIsChip: true,
                  chipColor: _teal,
                  onEdit: _editCaregiver,
                  details: [
                    _DetailData(icon: Icons.person_outline_rounded, label: 'Role',              value: _userRole),
                    _DetailData(icon: Icons.email_outlined,         label: 'Email',             value: FirebaseAuth.instance.currentUser?.email ?? caregiverEmail),
                    _DetailData(icon: Icons.phone_outlined,          label: 'Phone',             value: caregiverPhone),
                    _DetailData(icon: Icons.emergency_outlined,      label: 'Emergency Contact', value: caregiverEmergency),
                  ],
                ),
                const SizedBox(height: 20),
                if (_userRole == 'Parent') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel(label: 'Appointed Caregivers'),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: _teal),
                        onPressed: _addCaregiver,
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_appointedCaregivers.isEmpty)
                    const Text('No caregivers appointed yet. Tap the + icon to add one.',
                        style: TextStyle(color: Colors.white60, fontStyle: FontStyle.italic)),
                  ..._appointedCaregivers.map((c) {
                    final parts = c.split('|');
                    final name = parts[0];
                    final phone = parts.length > 1 ? parts[1] : '';
                    final addedDate = parts.length > 2 ? parts[2] : 'Unknown date';
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: _teal.withValues(alpha: 0.2), child: Icon(Icons.person, color: _teal)),
                            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (phone.isNotEmpty) Text(phone, style: const TextStyle(color: Colors.white70)),
                                Text('Added on: $addedDate', style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
                              ]
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: _alertRed),
                              onPressed: () async {
                                setState(() { _appointedCaregivers.remove(c); });
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setStringList('p_appointed_caregivers', _appointedCaregivers);
                              },
                            )
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
                _SectionLabel(label: AppStrings.t('growth_tracker')),
                const SizedBox(height: 12),
                _GrowthTrackerCard(entries: _growthHistory, onAddEntry: _addGrowthEntry),
                const SizedBox(height: 20),
                _SectionLabel(label: AppStrings.t('vaccination_tracker')),
                const SizedBox(height: 12),
                _VaccinationTrackerCard(
                  vaccinatedSet: _vaccinatedSet,
                  onToggle: (vaccine, checked) {
                    setState(() {
                      if (checked) { _vaccinatedSet.add(vaccine); }
                      else { _vaccinatedSet.remove(vaccine); }
                    });
                    _saveToPrefs();
                  },
                ),
                const SizedBox(height: 20),
                _SectionLabel(label: AppStrings.t('monitoring_summary')),
                const SizedBox(height: 12),
                MonitoringSummaryGrid(
                  nextCheckup: nextCheckup,
                  onAlertsTap: () => _showAlertBreakdown(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ), // End Scaffold
      ],
    ); // End Stack
  }
}



// ─────────────────────────────────────────────
//  Alert breakdown item model
// ─────────────────────────────────────────────
class _AlertBreakdownItem {
  final String type;
  final IconData icon;
  final Color color;
  final int count;
  final String lastDate;
  const _AlertBreakdownItem({
    required this.type, required this.icon, required this.color,
    required this.count, required this.lastDate,
  });
}

// ─────────────────────────────────────────────
//  Vaccination Tracker Card
// ─────────────────────────────────────────────
class _VaccinationTrackerCard extends StatelessWidget {
  final Set<String> vaccinatedSet;
  final void Function(String vaccine, bool checked) onToggle;
  const _VaccinationTrackerCard({
    required this.vaccinatedSet, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(children: [
                  const Icon(Icons.vaccines_rounded, size: 18, color: _teal),
                  const SizedBox(width: 8),
                  Text(AppStrings.t('vaccinations'),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${vaccinatedSet.length}/${kMilestoneVaccines.length}',
                      style: const TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.12), height: 1, indent: 16, endIndent: 16),
              ...kMilestoneVaccines.map((v) {
                final done = vaccinatedSet.contains(v);
                return CheckboxListTile(
                  dense: true,
                  value: done,
                  onChanged: (checked) => onToggle(v, checked ?? false),
                  title: Text(v,
                      style: TextStyle(
                        color: done ? _teal : Colors.white,
                        fontSize: 13,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: _teal,
                      )),
                  activeColor: _teal,
                  checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Growth Tracker Card
// ─────────────────────────────────────────────
class _GrowthTrackerCard extends StatelessWidget {
  final List<_GrowthEntry> entries;
  final VoidCallback onAddEntry;
  const _GrowthTrackerCard({required this.entries, required this.onAddEntry});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.show_chart_rounded, size: 18, color: _purple),
                      const SizedBox(width: 8),
                      Text(AppStrings.t('weight_over_time'),
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                    TextButton.icon(
                      onPressed: onAddEntry,
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: Text(AppStrings.t('add'), style: const TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: _purple,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: _purple, width: 0.5),
                        ),
                        backgroundColor: _purple.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
              if (entries.length >= 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: SizedBox(
                    height: 110,
                    child: CustomPaint(
                      painter: _GrowthChartPainter(
                        entries: entries,
                        weightColor: _purple,
                        heightColor: _teal,
                        bgColor: Colors.transparent,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              if (entries.length >= 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(children: [
                    Container(width: 12, height: 3, color: _purple),
                    const SizedBox(width: 4),
                    const Text('Weight', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(width: 12),
                    Container(width: 12, height: 3, color: _teal),
                    const SizedBox(width: 4),
                    const Text('Height', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ]),
                ),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No growth data yet. Tap Add to record an entry.',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ),
              if (entries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: entries.reversed.take(3).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Icon(Icons.circle, size: 8, color: _purple),
                        const SizedBox(width: 8),
                        Text(
                          '${e.date.month}/${e.date.day}/${e.date.year}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const Spacer(),
                        Text('${e.weightKg} kg', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        if (e.heightCm != null) ...[
                          const SizedBox(width: 12),
                          Text('${e.heightCm} cm', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ]),
                    )).toList(),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────
//  Growth Chart Painter
// ─────────────────────────────────────────────
class _GrowthChartPainter extends CustomPainter {
  final List<_GrowthEntry> entries;
  final Color weightColor;
  final Color heightColor;
  final Color bgColor;
  const _GrowthChartPainter({
    required this.entries,
    required this.weightColor,
    required this.heightColor,
    required this.bgColor,
  });

  void _drawLine(Canvas canvas, List<double> values, Color color, Size size) {
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).clamp(0.1, double.infinity);
    final n = values.length;
    double xOf(int i) => (i / (n - 1)) * size.width;
    double yOf(double v) => size.height - ((v - minV) / range) * size.height * 0.8 - size.height * 0.1;

    final path = Path()..moveTo(xOf(0), yOf(values[0]));
    for (int i = 1; i < n; i++) {
      final x0 = xOf(i - 1); final y0 = yOf(values[i - 1]);
      final x1 = xOf(i);     final y1 = yOf(values[i]);
      path.cubicTo(x0 + (x1 - x0) / 2, y0, x0 + (x1 - x0) / 2, y1, x1, y1);
    }
    // Fill
    final fillPath = Path.from(path)
      ..lineTo(xOf(n - 1), size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    // Line
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 2.0..style = PaintingStyle.stroke);
    // Dots
    for (int i = 0; i < n; i++) {
      canvas.drawCircle(Offset(xOf(i), yOf(values[i])), 4, Paint()..color = color);
      canvas.drawCircle(Offset(xOf(i), yOf(values[i])), 2, Paint()..color = bgColor);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;
    _drawLine(canvas, entries.map((e) => e.weightKg).toList(), weightColor, size);
    final heights = entries.where((e) => e.heightCm != null).map((e) => e.heightCm!).toList();
    if (heights.length >= 2) {
      _drawLine(canvas, heights, heightColor, size);
    }
  }

  @override
  bool shouldRepaint(_GrowthChartPainter old) => old.entries.length != entries.length;
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
    for (final c in _controllers) { c.dispose(); }
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
    final mq    = MediaQuery.of(context);
    final Color accent = widget.accentColor;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: accent.withValues(alpha: 0.15),
                      child: Icon(widget.avatarIcon, size: 20, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(widget.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 24),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                      left: 20, right: 20, bottom: mq.viewInsets.bottom + 16),
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
                        SizedBox(
                          width: double.infinity, height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Save Changes',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity, height: 48,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
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
        ),
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
      style: TextStyle(fontSize: 14, color: context.textMain, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: fieldDef.label,
        labelStyle: TextStyle(fontSize: 13, color: context.textSub),
        prefixIcon: Icon(fieldDef.icon, size: 18, color: accent),
        filled: true, fillColor: context.bgCard,
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
            color: _teal,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
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
  const _DetailData({required this.icon, required this.label, required this.value});
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(sectionIcon, size: 18, color: sectionIconColor),
                    _EditButton(accentColor: sectionIconColor, onPressed: onEdit),
                  ],
                ),
              ),
              // ── Avatar row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  children: [
                    Stack(children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: avatarIconColor.withValues(alpha: 0.25),
                        child: Icon(avatarIcon, size: 30, color: avatarIconColor),
                      ),
                      if (showOnlineDot)
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(
                              color: _teal, shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                            ),
                          ),
                        ),
                    ]),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.split(' ').first,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        subtitleIsChip
                            ? _ChipLabel(label: subtitle, color: chipColor ?? _teal)
                            : Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.15), height: 20, indent: 16, endIndent: 16),
              // ── Detail rows ──
              ...details.asMap().entries.map((e) {
                final isLast = e.key == details.length - 1;
                final d = e.value;
                return _DetailRow(icon: d.icon, label: d.label, value: d.value, isLast: isLast);
              }),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Growth Entry Dialog
// ─────────────────────────────────────────────
class _GrowthEntryDialog extends StatefulWidget {
  const _GrowthEntryDialog();

  @override
  State<_GrowthEntryDialog> createState() => _GrowthEntryDialogState();
}

class _GrowthEntryDialogState extends State<_GrowthEntryDialog> {
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    weightCtrl.dispose();
    heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppStrings.t('add_growth_entry'),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                TextField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: AppStrings.t('weight_kg'),
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                    prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 18, color: _purple),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _purple, width: 1.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: heightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: AppStrings.t('height_cm'),
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                    prefixIcon: const Icon(Icons.straighten_outlined, size: 18, color: _teal),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _teal, width: 1.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: _purple),
                        const SizedBox(width: 10),
                        Text(
                          '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.t('cancel'), style: const TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final kg = double.tryParse(weightCtrl.text);
                        final cm = double.tryParse(heightCtrl.text);
                        if (kg != null && kg > 0) {
                          Navigator.of(context).pop(_GrowthEntry(
                            date: selectedDate, weightKg: kg, heightCm: cm,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppStrings.t('add')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Caregiver Dialog
// ─────────────────────────────────────────────
class _CaregiverDialog extends StatefulWidget {
  const _CaregiverDialog();

  @override
  State<_CaregiverDialog> createState() => _CaregiverDialogState();
}

class _CaregiverDialogState extends State<_CaregiverDialog> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  String selectedCaregiver = 'Sarah Jenkins (Nanny)';

  static const List<Map<String, String>> predefinedCaregivers = [
    {'name': 'Sarah Jenkins (Nanny)', 'phone': '+1 555-0123'},
    {'name': 'David Smith (Babysitter)', 'phone': '+1 555-0199'},
    {'name': 'Maria Garcia (Night Nurse)', 'phone': '+1 555-0144'},
    {'name': 'Emily Davis (Daycare)', 'phone': '+1 555-0188'},
    {'name': 'Custom...', 'phone': ''},
  ];

  @override
  void initState() {
    super.initState();
    nameCtrl.text = predefinedCaregivers.first['name']!;
    phoneCtrl.text = predefinedCaregivers.first['phone']!;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = selectedCaregiver == 'Custom...';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add Appointed Caregiver',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: selectedCaregiver,
                  dropdownColor: Colors.black87,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Select Caregiver',
                    labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                  items: predefinedCaregivers.map((cg) {
                    return DropdownMenuItem(
                      value: cg['name'],
                      child: Text(cg['name']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      selectedCaregiver = val;
                      if (val != 'Custom...') {
                        final cg = predefinedCaregivers.firstWhere((e) => e['name'] == val);
                        nameCtrl.text = cg['name']!;
                        phoneCtrl.text = cg['phone']!;
                      } else {
                        nameCtrl.clear();
                        phoneCtrl.clear();
                      }
                    });
                  },
                ),
                if (isCustom) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Caregiver Name',
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.isNotEmpty) {
                          final now = DateTime.now();
                          const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                          final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';
                          Navigator.of(context).pop("${nameCtrl.text}|${phoneCtrl.text}|$dateStr");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────
//  Detail row
// ─────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isLast;

  const _DetailRow({
    required this.icon, required this.label,
    required this.value, this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _teal),
              const SizedBox(width: 10),
              Expanded(child: Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.white70))),
              Expanded(child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Colors.white))),
            ],
          ),
        ),
        if (!isLast)
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, indent: 44),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Edit button
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
          side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
        ),
        backgroundColor: accentColor.withValues(alpha: 0.08),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Monitoring Summary Grid
// ─────────────────────────────────────────────
class MonitoringSummaryGrid extends StatelessWidget {
  final String nextCheckup;
  final VoidCallback onAlertsTap;
  const MonitoringSummaryGrid({
    super.key,
    required this.nextCheckup,
    required this.onAlertsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(height: 80, child: Row(children: [
        Expanded(child: SummaryCard(data: SummaryData(
          icon: Icons.calendar_month_rounded, iconColor: context.primary,
          title: AppStrings.t('days_monitored'), value: '47',
        ))),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(
          onTap: onAlertsTap,
          child: SummaryCard(data: SummaryData(
            icon: Icons.notifications_active_rounded, iconColor: _alertRed,
            title: AppStrings.t('alerts_triggered'), value: '12',
            tappable: true,
          )),
        )),
      ])),
      const SizedBox(height: 10),
      SizedBox(height: 80, child: Row(children: [
        Expanded(child: SummaryCard(data: SummaryData(
          icon: Icons.favorite_rounded, iconColor: _roseColor,
          title: AppStrings.t('avg_heart_rate'), value: '128 BPM',
        ))),
        const SizedBox(width: 10),
        Expanded(child: SummaryCard(data: SummaryData(
          icon: Icons.event_available_rounded, iconColor: _teal,
          title: AppStrings.t('last_checkup'), value: 'Mar 5',
        ))),
      ])),
      const SizedBox(height: 10),
      SizedBox(height: 80, child: SummaryCard(data: SummaryData(
        icon: Icons.next_plan_outlined, iconColor: _purple,
        title: AppStrings.t('next_checkup'),
        value: nextCheckup.isEmpty ? AppStrings.t('not_scheduled') : nextCheckup,
      ))),
    ]);
  }
}

class SummaryData {
  final IconData icon;
  final Color iconColor;
  final String title, value;
  final bool tappable;
  const SummaryData({
    required this.icon, required this.iconColor,
    required this.title, required this.value,
    this.tappable = false,
  });
}

class SummaryCard extends StatelessWidget {
  final SummaryData data;
  const SummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: data.tappable
                ? data.iconColor.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: data.tappable
                  ? data.iconColor.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(data.title,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(data.value,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800,
                            color: Colors.white, height: 1.0)),
                  ],
                ),
              ),
              Icon(data.icon, color: data.iconColor, size: 22),
              if (data.tappable)
                Icon(Icons.chevron_right_rounded, size: 16, color: data.iconColor),
            ],
          ),
        ),
      ),
    );
  }
}