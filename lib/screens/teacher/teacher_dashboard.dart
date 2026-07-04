import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'tabs/students_tab.dart';
import 'tabs/activity_tab.dart';
import 'tabs/leaderboard_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/hod_performance_tab.dart';
import 'tabs/removal_requests_tab.dart';
import 'tabs/teacher_group_management_tab.dart';

class TeacherDashboard extends StatefulWidget {
  final String token;
  const TeacherDashboard({super.key, required this.token});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;
  List<Widget> _screens = [];
  List<String> subRoles = [];
  bool isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (widget.token == "debug_token") {
      setState(() {
        subRoles = ["CC", "HOD", "PET", "Discipline Commitee"];
        isProfileLoading = false;
        _initializeScreens();
      });
      return;
    }
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/auth/me"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final List<dynamic> subs = data["data"]["subRoles"] ?? [];
          setState(() {
            subRoles = subs.map((e) => e.toString()).toList();
            isProfileLoading = false;
            _initializeScreens();
          });
          return;
        }
      }
    } catch (e) {
      // Catch
    }
    setState(() {
      isProfileLoading = false;
      _initializeScreens();
    });
  }

  void _initializeScreens() {
    setState(() {
      _screens = [
        StudentsTab(token: widget.token, subRoles: subRoles),
        ActivityTab(token: widget.token),
        LeaderboardTab(token: widget.token),
        RemovalRequestsTab(token: widget.token),
        TeacherGroupManagementTab(token: widget.token),
        if (subRoles.contains("HOD"))
          HodPerformanceTab(token: widget.token),
        ProfileTab(token: widget.token),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isProfileLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<BottomNavigationBarItem> barItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_alt_rounded),
        label: 'Students',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.local_activity_rounded),
        label: 'Activity',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.leaderboard_rounded),
        label: 'Leaderboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.pending_actions_rounded),
        label: 'Requests',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.groups_rounded),
        label: 'Groups',
      ),
      if (subRoles.contains("HOD"))
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          label: 'HOD Report',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: _screens.isEmpty 
          ? const Center(child: CircularProgressIndicator()) 
          : _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF11998e),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: barItems,
      ),
    );
  }
}