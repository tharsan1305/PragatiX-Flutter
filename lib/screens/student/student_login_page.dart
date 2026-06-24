import 'dart:convert';
//used for convert dart code to json code
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//Used for API requests: POST , GET
import 'student_dashboard_page.dart';

class StudentLoginPage extends StatefulWidget {
  //statefulwidget becaues here the user credential will change and the output is dynamic
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {

  final TextEditingController identityController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  Future<void> loginStudent() async {

    final response = await http.post(
      Uri.parse(
        "http://10.0.2.2:8080/api/v1/auth/student-login",
      ),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "identity": identityController.text,
        "password": passwordController.text,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data["success"] == true) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Successful"),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
          const StudentDashboardPage(),
        ),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data["message"] ??
                "Login Failed",
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    identityController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Login"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Icon(
                      Icons.school,
                      size: 80,
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: identityController,
                      decoration: const InputDecoration(
                        labelText: "Student ID",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loginStudent,
                        child: const Text("Login"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}