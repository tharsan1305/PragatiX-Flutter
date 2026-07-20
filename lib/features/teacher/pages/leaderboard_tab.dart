import 'package:flutter/material.dart';
import 'package:spdms_app/features/leaderboard/pages/shared_leaderboard_page.dart';

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedLeaderboardPage(
      title: 'Student Leaderboard',
      showFilters: true,
      showCurrentUserRank: false,
    );
  }
}
