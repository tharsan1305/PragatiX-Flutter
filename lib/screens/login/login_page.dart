import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../student/student_dashboard_page.dart';
import '../teacher/teacher_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../captain/captain_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'Student'; // Added role state



  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final String identity = _identityController.text.trim();
    final String password = _passwordController.text;

    try {
      if (_selectedRole == 'Admin' || _selectedRole == 'Teacher') {
        // Step 1: Attempt Staff (Teacher/Admin) Login
        final staffResponse = await http.post(
          Uri.parse("http://10.0.2.2:8080/api/v1/auth/login"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"username": identity, "password": password}),
        );

        final staffData = jsonDecode(staffResponse.body);

        if (staffResponse.statusCode == 200 && staffData["success"] == true) {
          final Map<String, dynamic> responseData = staffData["data"] ?? {};
          final String userType = responseData["userType"] ?? "";
          final List<dynamic> roles = responseData["roles"] ?? [];
          final String token = responseData["token"] ?? "";

          if (roles.contains("ROLE_ADMIN")) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Admin Access Granted. Welcome!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboard(token: token),
              ),
            );
            return;
          } else if (userType == "TEACHER" ||
              roles.contains("ROLE_TEACHER") ||
              roles.contains("ROLE_DISCIPLINE_COMMITTEE")) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Welcome to Teacher Portal!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherDashboard(token: token),
              ),
            );
            return;
          }
        }

        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid username or password"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        // Step 2: Attempt Student Login
        final studentResponse = await http.post(
          Uri.parse("http://10.0.2.2:8080/api/v1/auth/student-login"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"identity": identity, "password": password}),
        );

        final studentData = jsonDecode(studentResponse.body);
        if (!mounted) return;
        setState(() => _isLoading = false);

                if (studentResponse.statusCode == 200 && studentData["success"] == true) {
          final Map<String, dynamic> responseData = studentData["data"] ?? {};
          final String token = responseData["token"] ?? "";
          final List<dynamic> roles = responseData["roles"] ?? []; // <-- Added this

          // Check if they are a captain!
          if (roles.contains("ROLE_CAPTAIN")) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Welcome Captain!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CaptainDashboardPage(token: token), // Go to Captain page
              ),
            );
          } else {
            // Normal Student
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Login Successful! Welcome to Student Portal."),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentDashboardPage(token: token), // Go to Student page
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invalid username or password"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Handle connection errors with option to enter local debug mode for Teachers
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "Connection failed. Please ensure the backend is running.",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4F46E5); // Modern Indigo brand color
    const bgGradient = [Color(0xFF1E293B), Color(0xFF0F172A)]; // Sleek slate gradient

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgGradient,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Portal Branding Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_person_rounded,
                            size: 64,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Main Title
                        const Text(
                          "SPDMS Login",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        // Dynamic Subtitle
                        Text(
                          "Enter your credentials to access your portal",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Role Selector Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: "Select Role",
                            prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: primaryColor,
                                width: 2.0,
                              ),
                            ),
                          ),
                          items: ['Student', 'Teacher', 'Admin']
                              .map((role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedRole = value);
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Username / Identity Field
                        TextFormField(
                          controller: _identityController,
                          validator: (v) => v == null || v.trim().isEmpty 
                              ? "Username, Email or Student ID is required" 
                              : null,
                          decoration: InputDecoration(
                            labelText: "Username / ID / Email",
                            hintText: "Enter your Username, ID or Email",
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: primaryColor,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: (v) => v == null || v.isEmpty 
                              ? "Password is required" 
                              : null,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword 
                                    ? Icons.visibility_off_outlined 
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: primaryColor,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "Sign In",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}