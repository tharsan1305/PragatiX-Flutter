import 'package:flutter/material.dart';
import 'student_dashboard_page.dart';
class StudentLoginPage extends StatelessWidget {
  const StudentLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Login"),
      ),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.school,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const TextField(
                  decoration: InputDecoration(
                    labelText: "Register Number",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentDashboardPage(),
                      ),
                    );
                  },
                  child: const Text("Login"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}