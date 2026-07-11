import 'package:spdms_app/core/config/api_config.dart';
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
  bool _isLoading = true;
  String _name = "Teacher";
  String _email = "";
  String _role = "TEACHER";
  String _department = "";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/auth/me"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final d = data["data"];
          setState(() {
            _name = d["fullName"] ?? d["username"] ?? "Teacher";
            _email = d["email"] ?? "";
            _role = d["role"] ?? "TEACHER";
            _department = d["department"] ?? "";
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // fallback
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Summary", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color(0xFFF1F5F9),
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Card(
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF11998e).withOpacity(0.1),
                      child: const Icon(
                        Icons.assignment_ind_rounded,
                        size: 70,
                        color: Color(0xFF11998e),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (_email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(_email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                  const SizedBox(height: 6),
                  const Text(
                    "Access Scope: Student Discipline Monitoring",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _buildProfileRow("Role", _role.replaceAll("ROLE_", "")),
                            const Divider(height: 24),
                            _buildProfileRow("Active System Session", "Yes"),
                            if (_department.isNotEmpty) ...[
                              const Divider(height: 24),
                              _buildProfileRow("Department", _department),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Sign Out"),
                              content: const Text("Are you sure you want to sign out?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginPage()),
                                      (route) => false,
                                    );
                                  },
                                  child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
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
                          backgroundColor: const Color(0xFF11998e),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
