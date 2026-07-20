import 'package:flutter/material.dart';
import 'package:spdms_app/features/admin/pages/overview_tab.dart';
import 'package:spdms_app/features/admin/pages/activity_tab.dart';
import 'package:spdms_app/features/admin/pages/profile_tab.dart';
import 'package:spdms_app/features/team/pages/team_removal_requests_tab.dart';
import 'package:spdms_app/features/team/pages/team_group_management_tab.dart';
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
    _tabs = [
      const OverviewTab(),
      const ActivityTab(),
      const TeamGroupManagementTab(),
      const TeamRemovalRequestsTab(),
      const ProfileTab(),
      
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFEA4335),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_activity_rounded),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions_rounded),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
