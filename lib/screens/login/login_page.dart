import 'package:flutter/material.dart';
import '../student/student_login_page.dart';
import '../teacher/teacher_login_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SPDMS Login"),
      ),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person,
                  size: 80,
                ),

                const SizedBox(height: 10),

                const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const StudentLoginPage(),
                        ),
                      );
                    },
                    child: const Text("Student Login"),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const TeacherLoginPage(),
                        ),
                      );
                    },
                    child: const Text("Teacher Login"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}