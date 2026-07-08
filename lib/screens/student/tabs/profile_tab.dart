import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../login/login_page.dart';

class ProfileTab extends StatefulWidget {
  final String token;
  const ProfileTab({super.key, required this.token});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool isLoading = true;
  String studentName = "Sharugesh";
  String studentId = "24CS036";
  String email = "sharugesh@college.edu";
  String department = "Computer Science";
  String section = "A";
  String year = "III";
  String sprNo = "SPR-2024-089";
  String semester = "VI Semester";
  String phone = "+91 98765 43210";
  int score = 95;
  int streak = 12;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    if (widget.token == "debug_token") {
      setState(() {
        isLoading = false;
      });
      return;
    }
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/auth/me"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final resData = data["data"];
          setState(() {
            studentName = resData["fullName"] ?? "Sharugesh";
            studentId = resData["username"] ?? "24CS036";
            email = resData["email"] ?? "sharugesh@college.edu";
            section = resData["section"] ?? "A";
            year = resData["year"] ?? "III";
            sprNo = resData["sprNo"] ?? "SPR-2024-089";
            semester = resData["semester"] ?? "VI Semester";
            phone = resData["phone"] ?? "+91 98765 43210";
            department = resData["department"] ?? "Computer Science";
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Keep mock values
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 36),

              // Profile Avatar Display
              Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: const CircleBorder(),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: const Color(0xFF4F46E5).withOpacity(0.08),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 60,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Name & Roll
              Text(
                studentName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                "Register ID: $studentId",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Details Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildProfileRow("Role", "STUDENT"),
                      const Divider(height: 20, thickness: 0.8),
                      _buildProfileRow("Full Name", studentName),
                      const Divider(height: 20, thickness: 0.8),
                      _buildProfileRow("Register No.", studentId),
                      const Divider(height: 20, thickness: 0.8),
                      _buildProfileRow("SPR No.", sprNo),
                      const Divider(height: 20, thickness: 0.8),
                      _buildProfileRow("Academic Year", "$year Year - Sec $section"),
                      const Divider(height: 20, thickness: 0.8),
                      _buildProfileRow("Semester", semester),
                      const Divider(height: 20, thickness: 0.8),
                      _buildProfileRow("Department", department),
                      const Divider(height: 20, thickness: 0.8),
                      _buildProfileRow("Email Address", email),
                      const Divider(height: 20, thickness: 0.8),
                      _buildProfileRow("Phone No.", phone),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text("Sign Out"),
                        content: const Text("Are you sure you want to sign out of your account?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                                (route) => false,
                              );
                            },
                            child: const Text("Sign Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: const Text(
                    "Sign Out",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
