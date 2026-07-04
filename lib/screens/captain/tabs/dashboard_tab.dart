import 'package:flutter/material.dart';

class DashboardTab extends StatelessWidget {
  final String token;
  const DashboardTab({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Dashboard Tab'),
    );
  }
}
