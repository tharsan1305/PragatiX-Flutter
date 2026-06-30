import 'package:flutter/material.dart';
import 'tabs/overview_tab.dart';
import 'tabs/students_tab.dart';
import 'tabs/teachers_tab.dart';
import 'tabs/departments_tab.dart';
import 'tabs/activity_tab.dart';
import 'tabs/profile_tab.dart';

class AdminDashboard extends StatefulWidget {
  final String token;
  const AdminDashboard({super.key, required this.token});

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
      OverviewTab(token: widget.token),
      StudentsTab(token: widget.token),
      TeachersTab(token: widget.token),
      DepartmentsTab(token: widget.token),
      ActivityTab(token: widget.token),
      ProfileTab(token: widget.token),
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
            icon: Icon(Icons.people_alt_rounded),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_rounded),
            label: 'Teachers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_rounded),
            label: 'Depts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_activity_rounded),
            label: 'Activity',
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
