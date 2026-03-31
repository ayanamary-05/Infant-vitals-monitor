import os
import re

login_file_path = r"C:\Users\Anosha Roy\Desktop\ORG\infant-vitals-monitor\lib\screens\login_screen.dart"
home_file_path = r"C:\Users\Anosha Roy\Desktop\ORG\infant-vitals-monitor\lib\screens\home_screen.dart"
profile_file_path = r"C:\Users\Anosha Roy\Desktop\ORG\infant-vitals-monitor\lib\screens\profile_screen.dart"

# --- 1. LOGIN SCREEN ---
with open(login_file_path, "r", encoding="utf-8") as f:
    login_code = f.read()

# Add _selectedRole variable
login_code = login_code.replace("bool _isLoading = false;", "bool _isLoading = false;\n  String _selectedRole = 'Parent';")

# Inject Role Selector in SignUp Build
role_selector = """const SizedBox(height: 36),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _RolePill(
                                label: "Parent",
                                isSelected: _selectedRole == 'Parent',
                                onTap: () => setState(() => _selectedRole = 'Parent'),
                              ),
                              const SizedBox(width: 16),
                              _RolePill(
                                label: "Caregiver",
                                isSelected: _selectedRole == 'Caregiver',
                                onTap: () => setState(() => _selectedRole = 'Caregiver'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),"""
login_code = login_code.replace("const SizedBox(height: 36),\n                          _GlassTextField", role_selector + "\n                          _GlassTextField")

# Add _RolePill widget at the end of LOGIN FORM SCREEN part
role_pill = """
class _RolePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _RolePill({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1DB954) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? const Color(0xFF1DB954) : Colors.white38),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
"""
login_code = login_code + role_pill

# Save _selectedRole in SharedPreferences
save_role = """await credential.user?.updateDisplayName('$firstName $lastName');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', _selectedRole);"""
login_code = login_code.replace("await credential.user?.updateDisplayName('$firstName $lastName');", save_role)

with open(login_file_path, "w", encoding="utf-8") as f:
    f.write(login_code)


# --- 2. HOME SCREEN ---
with open(home_file_path, "r", encoding="utf-8") as f:
    home_code = f.read()

# Make it use FirebaseAuth for the greeting
if "import 'package:firebase_auth/firebase_auth.dart';" not in home_code:
    home_code = home_code.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:firebase_auth/firebase_auth.dart';")

greeting_replace = """  String get _greetingLine {
    return '$_greeting $_babyName${AppStrings.t('greeting_suffix')}';
  }"""
greeting_new = """  String get _greetingLine {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'User';
    // Dynamically greets the user safely
    return '$_greeting $userName';
  }"""
if greeting_replace in home_code:
    home_code = home_code.replace(greeting_replace, greeting_new)

with open(home_file_path, "w", encoding="utf-8") as f:
    f.write(home_code)


# --- 3. PROFILE SCREEN ---
with open(profile_file_path, "r", encoding="utf-8") as f:
    profile_code = f.read()

if "import 'package:firebase_auth/firebase_auth.dart';" not in profile_code:
    profile_code = profile_code.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:firebase_auth/firebase_auth.dart';")

# Add state variables
vars_replace = """  // ── Growth tracker ─────────────────────────
  List<_GrowthEntry> _growthHistory = [];"""
vars_new = """  String _userRole = 'Parent';
  List<String> _appointedCaregivers = [];
  
  // ── Growth tracker ─────────────────────────
  List<_GrowthEntry> _growthHistory = [];"""
profile_code = profile_code.replace(vars_replace, vars_new)

prefs_replace = """      nextCheckup       = prefs.getString('p_nextCheckup')       ?? nextCheckup;

      final entries = prefs.getStringList('p_growthHistory') ?? [];"""
prefs_new = """      nextCheckup       = prefs.getString('p_nextCheckup')       ?? nextCheckup;
      _userRole         = prefs.getString('user_role')           ?? 'Parent';
      _appointedCaregivers = prefs.getStringList('p_appointed_caregivers') ?? [];

      final entries = prefs.getStringList('p_growthHistory') ?? [];"""
profile_code = profile_code.replace(prefs_replace, prefs_new)

# Add logic to add caregivers
add_caregiver_modal = """
  void _addCaregiver() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Appointed Caregiver', style: TextStyle(color: context.textMain, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: context.textMain, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Caregiver Name',
                labelStyle: TextStyle(color: context.textSub, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: context.textMain, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: context.textSub, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(AppStrings.t('cancel'))),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(AppStrings.t('add'))),
        ],
      ),
    );
    if (result == true && nameCtrl.text.isNotEmpty) {
      setState(() {
        _appointedCaregivers.add(nameCtrl.text + "|" + phoneCtrl.text);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('p_appointed_caregivers', _appointedCaregivers);
    }
  }
"""
profile_code = profile_code.replace("  // ── Add growth entry", add_caregiver_modal + "\n  // ── Add growth entry")

# Modify Profile Screen UI Layout to separate Parent from Caregiver
ui_caregiver_replace = """            // ── Caregiver profile ────────────────
            _SectionLabel(label: AppStrings.t('caregiver_profile')),
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

            const SizedBox(height: 20),"""

ui_caregiver_new = """            // ── Role Specific profile ────────────────
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
                _DetailData(icon: Icons.location_on_outlined,    label: 'Address',           value: caregiverAddress),
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
                Text("No caregivers appointed yet. Tap the + icon to add one.", style: TextStyle(color: context.textSub, fontStyle: FontStyle.italic)),
              ..._appointedCaregivers.map((c) {
                final parts = c.split('|');
                final name = parts[0];
                final phone = parts.length > 1 ? parts[1] : '';
                return Card(
                  color: context.bgCard,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: _teal.withValues(alpha: 0.2), child: Icon(Icons.person, color: _teal)),
                    title: Text(name, style: TextStyle(color: context.textMain, fontWeight: FontWeight.bold)),
                    subtitle: Text(phone, style: TextStyle(color: context.textSub)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: _alertRed),
                      onPressed: () async {
                        setState(() {
                          _appointedCaregivers.remove(c);
                        });
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setStringList('p_appointed_caregivers', _appointedCaregivers);
                      },
                    )
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],"""
profile_code = profile_code.replace(ui_caregiver_replace, ui_caregiver_new)

with open(profile_file_path, "w", encoding="utf-8") as f:
    f.write(profile_code)

print("Enhancement injection completed.")
