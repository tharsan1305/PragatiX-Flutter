import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
      ),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.emoji_events,
                  size: 80,
                ),

                SizedBox(height: 10),

                Text(
                  "Top Students",
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),

                SizedBox(height: 10),

                Text("🥇 Sharugesh  - 95 Points"),
                Text("🥈 Venkat - 90 Points"),
                Text("🥉 Jagadheesh - 88 Points"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}