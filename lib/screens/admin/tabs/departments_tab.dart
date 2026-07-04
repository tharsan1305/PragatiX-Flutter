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
  return [];
}

class DepartmentsTab extends StatefulWidget {
  final String token;
  const DepartmentsTab({super.key, required this.token});

  @override
  State<DepartmentsTab> createState() => _DepartmentsTabState();
}

class _DepartmentsTabState extends State<DepartmentsTab> {
  List<dynamic> departments = [];
  bool isLoading = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  //final TextEditingController descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      final list = await _apiGetDepartments(widget.token);
      setState(() {
        departments = list;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addDepartment() async {
    if (nameController.text.isEmpty || codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Code are required")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/departments"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "name": nameController.text.trim(),
          "code": codeController.text.trim().toUpperCase(),
          //"description": descController.text.trim(),
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || (response.statusCode == 200 && data["success"] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Department added successfully!"), backgroundColor: Colors.green),
        );
        nameController.clear();
        codeController.clear();
       // descController.clear();
        Navigator.pop(context);
        setState(() => isLoading = true);
        _fetchDepartments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to create department")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Department added locally"), backgroundColor: Colors.orange),
      );
      setState(() {
        departments.add({
          "id": departments.length + 1,
          "name": nameController.text,
          "code": codeController.text.toUpperCase(),
          //"description": descController.text,
        });
      });
      nameController.clear();
      codeController.clear();
     // descController.clear();
      Navigator.pop(context);
    }
  }

  Future<void> _editDepartment(int id) async {
    if (nameController.text.isEmpty || codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Code are required")),
      );
      return;
    }

    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/departments/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "name": nameController.text.trim(),
          "code": codeController.text.trim().toUpperCase(),
          //"description": descController.text.trim(),
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Department updated successfully!"), backgroundColor: Colors.green),
        );
        nameController.clear();
        codeController.clear();
        //descController.clear();
        Navigator.pop(context);
        setState(() => isLoading = true);
        _fetchDepartments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to update department")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated locally"), backgroundColor: Colors.orange),
      );
      setState(() {
        final idx = departments.indexWhere((d) => d["id"] == id);
        if (idx != -1) {
          departments[idx]["name"] = nameController.text;
          departments[idx]["code"] = codeController.text.toUpperCase();
        //  departments[idx]["description"] = descController.text;
        }
      });
      nameController.clear();
      codeController.clear();
      //descController.clear();
      Navigator.pop(context);
    }
  }

  Future<void> _deleteDepartment(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/departments/$id"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Department deleted successfully"), backgroundColor: Colors.green),
        );
        setState(() => isLoading = true);
        _fetchDepartments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete department on server"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        departments.removeWhere((d) => d["id"] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Department deleted locally"), backgroundColor: Colors.orange),
      );
    }
  }

  void _showAddDeptDialog() {
    nameController.clear();
    codeController.clear();
    //descController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Department", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Department Name *")),
                TextField(controller: codeController, decoration: const InputDecoration(labelText: "Department Code * (e.g. IT)")),
                //TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: _addDepartment,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  void _showEditDeptDialog(Map<String, dynamic> dept) {
    nameController.text = dept["name"] ?? '';
    codeController.text = dept["code"] ?? '';
   // descController.text = dept["description"] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Department: ${dept["code"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Department Name *")),
                TextField(controller: codeController, decoration: const InputDecoration(labelText: "Department Code *")),
               // TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () => _editDepartment(dept["id"]),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Academic Departments", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: departments.length,
                itemBuilder: (context, index) {
                  final dept = departments[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.account_balance, color: Colors.amber.shade700, size: 30),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dept["name"]!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Department Code: ${dept["code"]}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                //if (dept["description"] != null && dept["description"].toString().isNotEmpty) ...[
                                 // const SizedBox(height: 4),
                                 // Text(
                                 //   dept["description"],
                                //    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                 // ),
                                //],
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                onPressed: () => _showEditDeptDialog(dept),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Delete Department"),
                                      content: Text("Are you sure you want to delete department ${dept["code"]}?"),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteDepartment(dept["id"]);
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeptDialog,
        backgroundColor: const Color(0xFFEA4335),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
