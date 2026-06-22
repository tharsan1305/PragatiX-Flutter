import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.person,
              size: 80,
            ),

            SizedBox(height: 10),

            Text(
              "Student Profile",
              style: TextStyle(
                fontSize: 24,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Name : Sharugesh",
              style: TextStyle(fontSize: 18),
            ),

            Text(
              "Register No : 22CS001",
              style: TextStyle(fontSize: 18),
            ),

            Text(
              "Department : CSE",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}