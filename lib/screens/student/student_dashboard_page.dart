import 'package:flutter/material.dart';
import 'profile_card.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
      ),
      body: const Center(
        child: ProfileCard(),
      ),
    );
  }
}