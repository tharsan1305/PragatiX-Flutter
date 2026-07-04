import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  final String token;
  const ProfileTab({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Tab'),
    );
  }
}
