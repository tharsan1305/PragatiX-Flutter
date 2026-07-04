import 'package:flutter/material.dart';

class LeaderboardTab extends StatelessWidget {
  final String token;
  const LeaderboardTab({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Leaderboard Tab'),
    );
  }
}
