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

Future<List<dynamic>> _apiGetRoles(String token) async {
  try {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8080/api/v1/admin/roles"),
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
    {"name": "ROLE_ADMIN"},
    {"name": "ROLE_TEACHER"},
    {"name": "ROLE_STUDENT"}
  ];
}

Future<List<dynamic>> _apiGetSubjects(String token) async {
  try {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8080/api/v1/admin/subjects"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        return data["data"] ?? [];
      }
    }
  } catch (e) {
    // Catch
  }
  return [];
}

class TeachersTab extends StatefulWidget {
  final String token;
  const TeachersTab({super.key, required this.token});

  @override
  State<TeachersTab> createState() => _TeachersTabState();
}

class _TeachersTabState extends State<TeachersTab> {
  List<dynamic> usersList = [];
  List<dynamic> departments = [];
  List<dynamic> availableRoles = [];
  List<dynamic> subjectsList = [];
  bool isLoading = true;

  // Add/Edit Dialog controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();
  int? selectedDeptId;
  String selectedMainRole = "ROLE_TEACHER";
  Set<String> selectedSubRoles = {};
  String? selectedYear;

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final depts = await _apiGetDepartments(widget.token);
    final roles = await _apiGetRoles(widget.token);
    final subjects = await _apiGetSubjects(widget.token);
    setState(() {
      departments = depts;
      availableRoles = roles;
      subjectsList = subjects;
      if (departments.isNotEmpty) {
        selectedDeptId = departments.first["id"];
      }
    });
  }

  Future<void> _fetchTeachers() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/users"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final allUsers = data["data"] ?? [];
          setState(() {
            usersList = allUsers.where((u) {
              final List<dynamic> roles = u["roles"] ?? [];
              return roles.contains("ROLE_TEACHER") || roles.contains("ROLE_TRANSPORT");
            }).toList();
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Catch
    }

    setState(() {
      usersList = [
        {
          "id": 1,
          "username": "teacher1",
          "fullName": "Sample Teacher",
          "email": "teacher1@spdms.com",
          "roles": ["ROLE_TEACHER"],
          "subRoles": ["HOD"],
          "departmentId": 1,
          "departmentName": "CSE"
        }
      ];
      isLoading = false;
    });
  }

  Future<void> _addTeacher() async {
    if (usernameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
        emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Required fields cannot be empty.")),
      );
      return;
    }

    if (selectedSubRoles.contains("CC") && (selectedYear == null || selectedYear!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Year for Class Coordinator (CC).")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/users"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "username": usernameController.text.trim(),
          "password": passwordController.text,
          "fullName": nameController.text.trim(),
          "email": emailController.text.trim(),
          "departmentId": selectedDeptId,
          "roles": [selectedMainRole],
          "subRoles": selectedSubRoles.toList(),
          "section": selectedSubRoles.contains("CC") && sectionController.text.trim().isNotEmpty ? sectionController.text.trim() : null,
          "year": selectedSubRoles.contains("CC") ? selectedYear : null
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || (response.statusCode == 200 && data["success"] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User added successfully!"), backgroundColor: Colors.green),
        );
        _clearControllers();
        Navigator.pop(context);
        setState(() => isLoading = true);
        _fetchTeachers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to create user"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User added locally"), backgroundColor: Colors.orange),
      );
      setState(() {
        usersList.add({
          "id": usersList.length + 1,
          "username": usernameController.text,
          "fullName": nameController.text,
          "email": emailController.text,
          "roles": [selectedMainRole],
          "subRoles": selectedSubRoles.toList(),
          "departmentId": selectedDeptId,
          "departmentName": departments.firstWhere((d) => d["id"] == selectedDeptId, orElse: () => {"name": "CSE"})["name"],
          "section": selectedSubRoles.contains("CC") && sectionController.text.trim().isNotEmpty ? sectionController.text.trim() : null,
          "year": selectedSubRoles.contains("CC") ? selectedYear : null
        });
      });
      _clearControllers();
      Navigator.pop(context);
    }
  }

  Future<void> _editTeacher(int id) async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Required fields cannot be empty.")),
      );
      return;
    }

    if (selectedSubRoles.contains("CC") && (selectedYear == null || selectedYear!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Year for Class Coordinator (CC).")),
      );
      return;
    }

    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/users/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "fullName": nameController.text.trim(),
          "email": emailController.text.trim(),
          "departmentId": selectedDeptId,
          "roles": [selectedMainRole],
          "subRoles": selectedSubRoles.toList(),
          "section": selectedSubRoles.contains("CC") && sectionController.text.trim().isNotEmpty ? sectionController.text.trim() : null,
          "year": selectedSubRoles.contains("CC") ? selectedYear : null,
          "active": true
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User details updated successfully!"), backgroundColor: Colors.green),
        );
        _clearControllers();
        Navigator.pop(context);
        setState(() => isLoading = true);
        _fetchTeachers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to update user"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated locally"), backgroundColor: Colors.orange),
      );
      setState(() {
        final index = usersList.indexWhere((u) => u["id"] == id);
        if (index != -1) {
          usersList[index]["fullName"] = nameController.text;
          usersList[index]["email"] = emailController.text;
          usersList[index]["departmentId"] = selectedDeptId;
          usersList[index]["roles"] = [selectedMainRole];
          usersList[index]["subRoles"] = selectedSubRoles.toList();
          usersList[index]["section"] = selectedSubRoles.contains("CC") && sectionController.text.trim().isNotEmpty ? sectionController.text.trim() : null;
          usersList[index]["year"] = selectedSubRoles.contains("CC") ? selectedYear : null;
          usersList[index]["departmentName"] = departments.firstWhere((d) => d["id"] == selectedDeptId, orElse: () => {"name": "CSE"})["name"];
        }
      });
      _clearControllers();
      Navigator.pop(context);
    }
  }

  Future<void> _deleteTeacher(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/users/$id"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User deleted successfully!"), backgroundColor: Colors.green),
        );
        setState(() => isLoading = true);
        _fetchTeachers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to delete user")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        usersList.removeWhere((u) => u["id"] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User deleted locally"), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _addSubject(String name) async {
    if (name.trim().isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/subjects"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({"name": name.trim()}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || (response.statusCode == 200 && data["success"] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subject created successfully!"), backgroundColor: Colors.green),
        );
        _loadMetadata();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to create subject")),
        );
      }
    } catch (e) {
      setState(() {
        subjectsList.add({"id": subjectsList.length + 1, "name": name.trim()});
      });
    }
  }

  Future<void> _deleteSubject(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/subjects/$id"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subject deleted successfully!"), backgroundColor: Colors.green),
        );
        _loadMetadata();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to delete subject")),
        );
      }
    } catch (e) {
      setState(() {
        subjectsList.removeWhere((s) => s["id"] == id);
      });
    }
  }

  void _showManageSubjectsDialog() {
    final TextEditingController subjectController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Manage Subjects", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subjectController,
                            decoration: const InputDecoration(
                              labelText: "New Subject Name",
                              hintText: "e.g. Mathematics",
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (subjectController.text.trim().isEmpty) return;
                            await _addSubject(subjectController.text.trim());
                            subjectController.clear();
                            final freshSubjects = await _apiGetSubjects(widget.token);
                            setDialogState(() {
                              subjectsList = freshSubjects;
                            });
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
                          child: const Text("Add", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Configured Subjects:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: subjectsList.isEmpty
                          ? const Center(child: Text("No subjects created yet.", style: TextStyle(fontStyle: FontStyle.italic)))
                          : ListView.builder(
                              itemCount: subjectsList.length,
                              itemBuilder: (context, index) {
                                final s = subjectsList[index];
                                return ListTile(
                                  title: Text(s["name"] ?? ""),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () async {
                                      await _deleteSubject(s["id"]);
                                      final freshSubjects = await _apiGetSubjects(widget.token);
                                      setDialogState(() {
                                        subjectsList = freshSubjects;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _clearControllers() {
    usernameController.clear();
    passwordController.clear();
    nameController.clear();
    emailController.clear();
    sectionController.clear();
    selectedMainRole = "ROLE_TEACHER";
    selectedSubRoles = {};
    selectedYear = null;
    if (departments.isNotEmpty) {
      selectedDeptId = departments.first["id"];
    }
  }

  void _showAddTeacherDialog() {
    _clearControllers();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add New Staff / User", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: usernameController, decoration: const InputDecoration(labelText: "Username *")),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name *")),
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email *")),
                    TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password *")),
                    const SizedBox(height: 15),
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
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: selectedMainRole,
                      decoration: const InputDecoration(labelText: "System Role *"),
                      items: const [
                        DropdownMenuItem(value: "ROLE_TEACHER", child: Text("Teacher")),
                        DropdownMenuItem(value: "ROLE_TRANSPORT", child: Text("Transport")),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMainRole = value ?? "ROLE_TEACHER";
                        });
                      },
                    ),
                    if (selectedMainRole == "ROLE_TEACHER") ...[
                      const SizedBox(height: 15),
                      const Text("Teacher Sub-Roles:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ...["HOD", "CC", "Discipline Commitee", "Lab instructor", "PET"].map((subRole) {
                        return CheckboxListTile(
                          title: Text(subRole),
                          value: selectedSubRoles.contains(subRole),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedSubRoles.add(subRole);
                              } else {
                                selectedSubRoles.remove(subRole);
                                if (subRole == "CC") {
                                  selectedYear = null;
                                  sectionController.clear();
                                }
                              }
                            });
                          },
                        );
                      }),
                      if (selectedSubRoles.contains("CC")) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedYear,
                          decoration: const InputDecoration(
                            labelText: "Coordinator Year *",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: "I", child: Text("I Year")),
                            DropdownMenuItem(value: "II", child: Text("II Year")),
                            DropdownMenuItem(value: "III", child: Text("III Year")),
                            DropdownMenuItem(value: "IV", child: Text("IV Year")),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedYear = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: sectionController,
                          decoration: const InputDecoration(
                            labelText: "Coordinator Section Name (Optional)",
                            hintText: "e.g. CSE-A or Section A",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Text("Subject Specialization:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      if (subjectsList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text("No subjects configured. Add subjects under 'Manage Subjects'.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        )
                      else
                        ...subjectsList.map((subject) {
                          final String subjName = subject["name"];
                          final String subjSubrole = "Subject: $subjName";
                          return CheckboxListTile(
                            title: Text(subjName),
                            value: selectedSubRoles.contains(subjSubrole),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  selectedSubRoles.add(subjSubrole);
                                } else {
                                  selectedSubRoles.remove(subjSubrole);
                                }
                              });
                            },
                          );
                        }),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: _addTeacher,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
                  child: const Text("Create", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTeacherDialog(Map<String, dynamic> teacher) {
    nameController.text = teacher["fullName"] ?? '';
    emailController.text = teacher["email"] ?? '';
    selectedDeptId = teacher["departmentId"];
    
    final List<dynamic> rolesList = teacher["roles"] ?? [];
    if (rolesList.isNotEmpty) {
      selectedMainRole = rolesList.first.toString();
    } else {
      selectedMainRole = "ROLE_TEACHER";
    }

    final List<dynamic> subRolesList = teacher["subRoles"] ?? [];
    selectedSubRoles = subRolesList.map((e) => e.toString()).toSet();
    sectionController.text = teacher["section"] ?? '';
    selectedYear = teacher["year"]?.toString();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Edit User: ${teacher["username"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name *")),
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email *")),
                    const SizedBox(height: 15),
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
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: selectedMainRole,
                      decoration: const InputDecoration(labelText: "System Role *"),
                      items: const [
                        DropdownMenuItem(value: "ROLE_TEACHER", child: Text("Teacher")),
                        DropdownMenuItem(value: "ROLE_TRANSPORT", child: Text("Transport")),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMainRole = value ?? "ROLE_TEACHER";
                        });
                      },
                    ),
                    if (selectedMainRole == "ROLE_TEACHER") ...[
                      const SizedBox(height: 15),
                      const Text("Teacher Sub-Roles:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ...["HOD", "CC", "Discipline Commitee", "Lab instructor", "PET"].map((subRole) {
                        return CheckboxListTile(
                          title: Text(subRole),
                          value: selectedSubRoles.contains(subRole),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedSubRoles.add(subRole);
                              } else {
                                selectedSubRoles.remove(subRole);
                                if (subRole == "CC") {
                                  selectedYear = null;
                                  sectionController.clear();
                                }
                              }
                            });
                          },
                        );
                      }),
                      if (selectedSubRoles.contains("CC")) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedYear,
                          decoration: const InputDecoration(
                            labelText: "Coordinator Year *",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: "I", child: Text("I Year")),
                            DropdownMenuItem(value: "II", child: Text("II Year")),
                            DropdownMenuItem(value: "III", child: Text("III Year")),
                            DropdownMenuItem(value: "IV", child: Text("IV Year")),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedYear = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: sectionController,
                          decoration: const InputDecoration(
                            labelText: "Coordinator Section Name (Optional)",
                            hintText: "e.g. CSE-A or Section A",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Text("Subject Specialization:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      if (subjectsList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text("No subjects configured. Add subjects under 'Manage Subjects'.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        )
                      else
                        ...subjectsList.map((subject) {
                          final String subjName = subject["name"];
                          final String subjSubrole = "Subject: $subjName";
                          return CheckboxListTile(
                            title: Text(subjName),
                            value: selectedSubRoles.contains(subjSubrole),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  selectedSubRoles.add(subjSubrole);
                                } else {
                                  selectedSubRoles.remove(subjSubrole);
                                }
                              });
                            },
                          );
                        }),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () => _editTeacher(teacher["id"]),
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
        title: const Text("Teacher Directory", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchTeachers();
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showManageSubjectsDialog,
                        icon: const Icon(Icons.book_outlined, color: Colors.white, size: 18),
                        label: const Text("Manage Subjects", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddTeacherDialog,
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        label: const Text("Add Teacher", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: usersList.length,
                      itemBuilder: (context, index) {
                        final t = usersList[index];
                        final String name = t["fullName"] ?? '';
                        final String username = t["username"] ?? '';
                        final String email = t["email"] ?? '';
                        final String deptName = t["departmentName"] ?? 'No Department';
                        final List<dynamic> rolesList = t["roles"] ?? [];
                        final rolesStr = rolesList.map((e) => e.toString().replaceAll("ROLE_", "")).join(", ");
                        final List<dynamic> subRolesList = t["subRoles"] ?? [];
                        String subRolesStr = "";
                        if (subRolesList.isNotEmpty) {
                          final List<String> mappedSubs = [];
                          for (var r in subRolesList) {
                            if (r.toString() == "CC") {
                              String ccDetails = "CC";
                              List<String> ccParts = [];
                              if (t["year"] != null && t["year"].toString().isNotEmpty) {
                                ccParts.add("Year: ${t["year"]}");
                              }
                              if (t["section"] != null && t["section"].toString().isNotEmpty) {
                                ccParts.add("Section: ${t["section"]}");
                              }
                              if (ccParts.isNotEmpty) {
                                ccDetails += " (${ccParts.join(" | ")})";
                              }
                              mappedSubs.add(ccDetails);
                            } else {
                              mappedSubs.add(r.toString());
                            }
                          }
                          subRolesStr = " | Sub-roles: " + mappedSubs.join(", ");
                        }

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              child: const Icon(Icons.assignment_ind, color: Colors.green),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Username: $username\nEmail: $email\nDept: $deptName\nRole: $rolesStr$subRolesStr"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                  onPressed: () => _showEditTeacherDialog(t),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Delete Teacher"),
                                        content: Text("Are you sure you want to delete teacher $name?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteTeacher(t["id"]);
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
    );
  }
}
