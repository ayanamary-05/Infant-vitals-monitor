import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:first_app/screens/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late final Stream<DatabaseEvent> _usersStream;
  late final Stream<DatabaseEvent> _statusStream;
  late final Stream<DatabaseEvent> _activityStream;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseDatabase.instance.ref('users').onValue;
    _statusStream = FirebaseDatabase.instance.ref().onValue;
    _activityStream = FirebaseDatabase.instance.ref('history').onValue;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildUsersSection() {
    return StreamBuilder(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text("No users found", style: TextStyle(color: Colors.white70)));
        }

        final usersMap = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final filteredUsers = usersMap.entries.where((entry) {
          final userData = Map<String, dynamic>.from(entry.value);
          final name = userData['name']?.toString().toLowerCase() ?? '';
          final email = userData['email']?.toString().toLowerCase() ?? '';
          return name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
        }).toList();

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TOTAL USERS", style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  Text("${usersMap.length}", style: const TextStyle(color: Color(0xFF1DB954), fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassTextField(
                hintText: "Search users...",
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: filteredUsers.isEmpty
                  ? const Center(child: Text("No users with that name", style: TextStyle(color: Colors.white54, fontSize: 14)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final userData = Map<String, dynamic>.from(filteredUsers[index].value);
                  return _AdminCard(
                    title: userData['name'] ?? 'Unknown User',
                    subtitle: userData['email'] ?? 'No Email',
                    trailingText: userData['role']?.toString().toUpperCase() ?? 'PARENT',
                    icon: Icons.person_rounded,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSystemStatusSection() {
    return StreamBuilder(
      stream: _statusStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final data = snapshot.data?.snapshot.value as Map? ?? {};
        final usersMap = data['users'] != null ? Map<dynamic, dynamic>.from(data['users']) : {};
        final alertsMap = data['alerts'] != null ? Map<dynamic, dynamic>.from(data['alerts']) : {};

        // Count infants (assuming one per parent)
        int infantCount = 0;
        usersMap.forEach((key, value) {
          final userData = Map<String, dynamic>.from(value);
          if (userData['role']?.toString().toLowerCase() == 'parent') {
            infantCount++;
          }
        });

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "SYSTEM OVERVIEW",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 24),
              _VitalStatCard(
                label: "Total Registered Users",
                value: "${usersMap.length}",
                icon: Icons.group_rounded,
                color: const Color(0xFF6366F1), // Indigo
              ),
              const SizedBox(height: 16),
              _VitalStatCard(
                label: "Infants under Monitor",
                value: "$infantCount",
                icon: Icons.child_care_rounded,
                color: const Color(0xFF10B981), // Emerald
              ),
              const SizedBox(height: 16),
              _VitalStatCard(
                label: "Total Alerts Generated",
                value: "${alertsMap.length}",
                icon: Icons.notifications_active_rounded,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.shield_rounded, color: Color(0xFF1DB954), size: 40),
                    SizedBox(height: 12),
                    Text("SYSTEM SECURE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Real-time monitoring active", style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSystemActivitySection() {
    return StreamBuilder(
      stream: _activityStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text("No system activity tracked", style: TextStyle(color: Colors.white70)));
        }

        final historyMap = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final history = historyMap.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();
        
        int getTimestamp(Map<String, dynamic> entry) {
          final t = entry['timestamp'];
          if (t is int) return t;
          if (t is String) return int.tryParse(t) ?? 0;
          return 0;
        }

        history.sort((a, b) => getTimestamp(b).compareTo(getTimestamp(a)));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
          itemBuilder: (context, index) {
            final entry = history[index];
            final timestamp = getTimestamp(entry);
            final timeStr = timestamp > 0 
                ? DateFormat('MMM dd · HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(timestamp))
                : '--:--:--';

            return ListTile(
              leading: Icon(
                entry['type'] == 'login' ? Icons.login_rounded : Icons.info_outline_rounded,
                color: entry['type'] == 'login' ? const Color(0xFF1DB954) : Colors.white70,
                size: 20
              ),
              title: Text(entry['message'] ?? 'System Event', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 22),
            onPressed: _logout,
          ),
        ],
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildUsersSection(),
          _buildSystemStatusSection(),
          _buildSystemActivitySection(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: const Color(0xFF1DB954),
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: "Users"),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: "Status"),
            BottomNavigationBarItem(icon: Icon(Icons.history_toggle_off_rounded), label: "Activity"),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailingText;
  final IconData icon;
  final Color iconColor;
  final bool isCritical;

  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.icon,
    this.iconColor = Colors.white70,
    this.isCritical = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isCritical ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          width: isCritical ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCritical ? Colors.redAccent : iconColor).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isCritical ? Colors.redAccent : iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          Text(
            trailingText,
            style: TextStyle(
              color: isCritical ? Colors.redAccent : const Color(0xFF1DB954),
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _VitalStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 1),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
