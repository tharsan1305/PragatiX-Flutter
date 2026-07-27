import 'package:flutter/material.dart';
import 'package:spdms_app/features/admin/pages/overview_tab.dart';
import 'package:spdms_app/features/admin/pages/activity_tab.dart';
import 'package:spdms_app/features/admin/pages/profile_tab.dart';
import 'package:spdms_app/features/team/pages/team_group_management_tab.dart';
import 'package:spdms_app/features/attendance/pages/admin_attendance_tab.dart';
import 'package:spdms_app/features/badge/pages/admin_badge_requests_page.dart';
import 'package:spdms_app/features/admin/pages/super_admin_management_tab.dart';
import 'package:provider/provider.dart';
import 'package:spdms_app/features/auth/providers/auth_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback or delay to read provider if needed, 
    // but context.read is safe in initState if we don't watch.
    final authProvider = context.read<AuthProvider>();
    final roles = authProvider.currentUser?['roles'] ?? [];
    final isSuperAdmin = roles.contains('ROLE_SUPER_ADMIN');

    _tabs = [
      const OverviewTab(),
      const ActivityTab(),
      const AdminAttendanceTab(),
      const TeamGroupManagementTab(),
      const AdminBadgeRequestsPage(),
      if (isSuperAdmin) const SuperAdminManagementTab(),
      const ProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final roles = authProvider.currentUser?['roles'] ?? [];
    final isSuperAdmin = roles.contains('ROLE_SUPER_ADMIN');

    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFEA4335),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_activity_rounded),
            label: 'Activity',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.co_present_rounded),
            label: 'Attendance',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Groups',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.workspace_premium),
            label: 'Requests',
          ),
          if (isSuperAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_rounded),
              label: 'Admins',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
