import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<List<dynamic>> _apiGetDepartments(String token) async {
  try {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8080/api/v1/admin/departments"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        return data["data"] ?? [];
      }
    }
  } catch (e) {
    // Fallback
  }
  return [
    {"id": 1, "name": "Computer Science and Engineering", "code": "CSE"},
    {"name": "Electronics and Communication", "code": "ECE"},
    {"name": "Mechanical Engineering", "code": "MECH"},
    {"name": "Civil Engineering", "code": "CIVIL"},
    {"name": "Business Administration", "code": "MBA"}
  ];
}

class StudentsTab extends StatefulWidget {
  final String token;
  const StudentsTab({super.key, required this.token});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  List<dynamic> studentsList = [];
  List<dynamic> departments = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Add/Edit Dialog controllers
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController semesterController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  int? selectedDeptId;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final list = await _apiGetDepartments(widget.token);
    setState(() {
      departments = list;
      if (departments.isNotEmpty) {
        selectedDeptId = departments.first["id"];
      }
    });
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/students?page=0&size=100&sortBy=fullName"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            studentsList = data["data"]["content"] ?? [];
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Fallback
    }

    setState(() {
      studentsList = [
        {
          "id": 1,
          "studentId": "sharugesh",
          "fullName": "Sharugesh",
          "email": "sharugesh@spdms.com",
          "phone": "9876543210",
          "gender": "MALE",
          "departmentName": "Computer Science and Engineering",
          "semester": "1",
          "academicYear": "2024-2025"
        }
      ];
      isLoading = false;
    });
  }

  Future<void> _addStudent() async {
    if (studentIdController.text.isEmpty ||
        nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Required fields cannot be empty.")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/students"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "studentId": studentIdController.text.trim(),
          "fullName": nameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text,
          "phone": phoneController.text.trim(),
          "gender": genderController.text.toUpperCase().isEmpty ? "MALE" : genderController.text.toUpperCase(),
          "departmentId": selectedDeptId,
          "semester": semesterController.text.isEmpty ? "1" : semesterController.text,
          "academicYear": yearController.text.isEmpty ? "2024-2025" : yearController.text,
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || (response.statusCode == 200 && data["success"] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student created successfully!"), backgroundColor: Colors.green),
        );
        _clearControllers();
        Navigator.pop(context);
        setState(() => isLoading = true);
        _fetchStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to create student"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit to backend. Dynamic state updated locally."), backgroundColor: Colors.orange),
      );
      setState(() {
        studentsList.add({
          "id": studentsList.length + 1,
          "studentId": studentIdController.text,
          "fullName": nameController.text,
          "email": emailController.text,
          "phone": phoneController.text,
          "gender": genderController.text.toUpperCase().isEmpty ? "MALE" : genderController.text.toUpperCase(),
          "departmentName": departments.firstWhere((d) => d["id"] == selectedDeptId, orElse: () => {"name": "CSE"})["name"],
          "semester": semesterController.text,
          "academicYear": yearController.text,
        });
      });
      _clearControllers();
      Navigator.pop(context);
    }
  }

  Future<void> _editStudent(int id) async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Required fields cannot be empty.")),
      );
      return;
    }

    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:8080/api/v1/students/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "fullName": nameController.text.trim(),
          "email": emailController.text.trim(),
          "phone": phoneController.text.trim(),
          "gender": genderController.text.toUpperCase().isEmpty ? "MALE" : genderController.text.toUpperCase(),
          "departmentId": selectedDeptId,
          "semester": semesterController.text.isEmpty ? "1" : semesterController.text,
          "academicYear": yearController.text.isEmpty ? "2024-2025" : yearController.text,
          "active": true
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student details updated successfully!"), backgroundColor: Colors.green),
        );
        _clearControllers();
        Navigator.pop(context);
        setState(() => isLoading = true);
        _fetchStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to update student"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated locally"), backgroundColor: Colors.orange),
      );
      setState(() {
        final idx = studentsList.indexWhere((s) => s["id"] == id);
        if (idx != -1) {
          studentsList[idx]["fullName"] = nameController.text;
          studentsList[idx]["email"] = emailController.text;
          studentsList[idx]["phone"] = phoneController.text;
          studentsList[idx]["gender"] = genderController.text.toUpperCase();
          studentsList[idx]["departmentId"] = selectedDeptId;
          studentsList[idx]["semester"] = semesterController.text;
          studentsList[idx]["academicYear"] = yearController.text;
          studentsList[idx]["departmentName"] = departments.firstWhere((d) => d["id"] == selectedDeptId, orElse: () => {"name": "CSE"})["name"];
        }
      });
      _clearControllers();
      Navigator.pop(context);
    }
  }

  Future<void> _deleteStudent(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("http://10.0.2.2:8080/api/v1/students/$id"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student deleted successfully"), backgroundColor: Colors.green),
        );
        setState(() => isLoading = true);
        _fetchStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Delete failed on server"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        studentsList.removeWhere((s) => s["id"] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed locally"), backgroundColor: Colors.orange),
      );
    }
  }

  void _clearControllers() {
    studentIdController.clear();
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    phoneController.clear();
    genderController.clear();
    semesterController.clear();
    yearController.clear();
  }

  void _showAddStudentDialog() {
    _clearControllers();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Register New Student", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: studentIdController, decoration: const InputDecoration(labelText: "Student ID *")),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name *")),
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email *")),
                    TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password *")),
                    TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone")),
                    TextField(controller: genderController, decoration: const InputDecoration(labelText: "Gender (MALE/FEMALE)")),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: selectedDeptId,
                      decoration: const InputDecoration(labelText: "Department"),
                      items: departments.map((d) {
                        return DropdownMenuItem<int>(
                          value: d["id"],
                          child: Text(d["code"] ?? d["name"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDeptId = value;
                        });
                      },
                    ),
                    TextField(controller: semesterController, decoration: const InputDecoration(labelText: "Semester")),
                    TextField(controller: yearController, decoration: const InputDecoration(labelText: "Academic Year")),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: _addStudent,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
                  child: const Text("Add Student", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    nameController.text = student["fullName"] ?? '';
    emailController.text = student["email"] ?? '';
    phoneController.text = student["phone"] ?? '';
    genderController.text = student["gender"] ?? 'MALE';
    semesterController.text = student["semester"] ?? '1';
    yearController.text = student["academicYear"] ?? '2024-2025';
    
    final deptName = student["departmentName"];
    final match = departments.firstWhere((d) => d["name"] == deptName, orElse: () => {"id": departments.isNotEmpty ? departments.first["id"] : null});
    selectedDeptId = match["id"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Edit Student: ${student["studentId"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name *")),
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email *")),
                    TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone")),
                    TextField(controller: genderController, decoration: const InputDecoration(labelText: "Gender (MALE/FEMALE)")),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: selectedDeptId,
                      decoration: const InputDecoration(labelText: "Department"),
                      items: departments.map((d) {
                        return DropdownMenuItem<int>(
                          value: d["id"],
                          child: Text(d["code"] ?? d["name"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDeptId = value;
                        });
                      },
                    ),
                    TextField(controller: semesterController, decoration: const InputDecoration(labelText: "Semester")),
                    TextField(controller: yearController, decoration: const InputDecoration(labelText: "Academic Year")),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () => _editStudent(student["id"]),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Management", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchStudents();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by student ID or name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: studentsList.length,
                      itemBuilder: (context, index) {
                        final s = studentsList[index];
                        final String sId = s["studentId"] ?? '';
                        final String name = s["fullName"] ?? '';
                        final String deptName = s["departmentName"] ?? 'No Department';

                        if (searchQuery.isNotEmpty &&
                            !sId.toLowerCase().contains(searchQuery) &&
                            !name.toLowerCase().contains(searchQuery)) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.redAccent.withOpacity(0.1),
                              child: const Icon(Icons.person, color: Colors.redAccent),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("$sId • $deptName\nSem: ${s["semester"] ?? '1'}${s["year"] != null && s["year"].toString().isNotEmpty ? ' • Year: ${s["year"]}' : ''}${s["section"] != null && s["section"].toString().isNotEmpty ? ' • Section: ${s["section"]}' : ''}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                  onPressed: () => _showEditStudentDialog(s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Delete Student"),
                                        content: Text("Are you sure you want to delete student $name?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteStudent(s["id"]);
                                            },
                                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        backgroundColor: const Color(0xFFEA4335),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
