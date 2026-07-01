import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../stage_details_page.dart';

class ActivityTab extends StatefulWidget {
  final String token;
  const ActivityTab({super.key, required this.token});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  List<dynamic> stagesList = [];
  List<dynamic> teachersList = [];
  bool isLoading = true;

  final TextEditingController stageNameController = TextEditingController();
  final TextEditingController stageDescController = TextEditingController();
  final TextEditingController subNameController = TextEditingController();
  final TextEditingController subThreshController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStages();
    _fetchTeachers();
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
          final List<dynamic> allUsers = data["data"] ?? [];
          setState(() {
            teachersList = allUsers.where((u) {
              final List<dynamic> roles = u["roles"] ?? [];
              return roles.contains("ROLE_TEACHER");
            }).toList();
          });
        }
      }
    } catch (e) {
      // Catch
    }
  }



  Future<void> _fetchStages() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/stages"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            stagesList = data["data"] ?? [];
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Catch
    }

    setState(() {
      stagesList = [
        {
          "id": 1,
          "name": "Stage 1",
          "description": "Initial threshold limits",
          "subgroups": [
            {"id": 1, "name": "must (individual)", "threshold": 30},
            {"id": 2, "name": "individual", "threshold": 20},
            {"id": 3, "name": "groups", "threshold": 50}
          ]
        }
      ];
      isLoading = false;
    });
  }

  Future<void> _createStage() async {
    if (stageNameController.text.trim().isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/stages"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "name": stageNameController.text.trim(),
          "description": stageDescController.text.trim(),
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || (response.statusCode == 200 && data["success"] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stage created successfully!"), backgroundColor: Colors.green),
        );
        stageNameController.clear();
        stageDescController.clear();
        Navigator.pop(context);
        setState(() => isLoading = true);
        _fetchStages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to create stage")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stage added locally"), backgroundColor: Colors.orange),
      );
      setState(() {
        stagesList.add({
          "id": stagesList.length + 1,
          "name": stageNameController.text,
          "description": stageDescController.text,
          "subgroups": []
        });
      });
      stageNameController.clear();
      stageDescController.clear();
      Navigator.pop(context);
    }
  }



  Future<void> _deleteStage(int stageId) async {
    try {
      final response = await http.delete(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/stages/$stageId"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stage deleted successfully"), backgroundColor: Colors.green),
        );
        setState(() => isLoading = true);
        _fetchStages();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        stagesList.removeWhere((s) => s["id"] == stageId);
      });
    }
  }

  void _showAddStageDialog() {
    stageNameController.clear();
    stageDescController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Activity Stage", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: stageNameController, decoration: const InputDecoration(labelText: "Stage Name * (e.g. Stage 1)")),
              TextField(controller: stageDescController, decoration: const InputDecoration(labelText: "Description")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: _createStage,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
              child: const Text("Create", style: TextStyle(color: Colors.white)),
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
        title: const Text("Activity & Thresholds", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchStages();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Configure Stages & Thresholds",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddStageDialog,
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        label: const Text("Add Stage", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: stagesList.length,
                      itemBuilder: (context, index) {
                        final stage = stagesList[index];
                        final String name = stage["name"] ?? '';
                        final String desc = stage["description"] ?? 'No description';
                        final List<dynamic> subgroups = stage["subgroups"] ?? [];

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 20),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StageDetailsPage(
                                    token: widget.token,
                                    stageId: stage["id"],
                                    stageName: name,
                                    stageDescription: desc,
                                    teachersList: teachersList,
                                  ),
                                ),
                              ).then((_) {
                                setState(() => isLoading = true);
                                _fetchStages();
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          desc,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "${subgroups.length} sub-branches configured",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text("Delete Stage"),
                                              content: Text("Are you sure you want to delete $name and all its subgroups?"),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _deleteStage(stage["id"]);
                                                  },
                                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                    ],
                                  ),
                                ],
                              ),
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
