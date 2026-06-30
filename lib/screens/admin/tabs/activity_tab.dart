import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  Future<void> _assignFaculty(int subId, int? userId) async {
    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/subgroups/$subId/assign-faculty"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({"userId": userId}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Faculty assigned successfully!"), backgroundColor: Colors.green),
        );
        _fetchStages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to assign faculty")),
        );
      }
    } catch (e) {
      setState(() {
        for (var stage in stagesList) {
          for (var sub in stage["subgroups"]) {
            if (sub["id"] == subId) {
              if (userId == null) {
                sub["assignedFacultyId"] = null;
                sub["assignedFacultyName"] = null;
              } else {
                final teacher = teachersList.firstWhere((t) => t["id"] == userId, orElse: () => null);
                sub["assignedFacultyId"] = userId;
                sub["assignedFacultyName"] = teacher != null ? teacher["fullName"] : "Assigned";
              }
            }
          }
        }
      });
    }
  }

  void _showAssignFacultyDialog(int subId, int? currentFacultyId) {
    int? selectedFacultyId = currentFacultyId;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Assign Faculty to Activity", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select a faculty member who will be solely responsible for points allocation on this activity:"),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<int?>(
                    value: selectedFacultyId,
                    decoration: const InputDecoration(labelText: "Faculty Member"),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("Unassigned (All teachers can adjust points)"),
                      ),
                      ...teachersList.map((t) {
                        return DropdownMenuItem<int?>(
                          value: t["id"],
                          child: Text("${t["fullName"]} (${t["username"]})"),
                        );
                      })
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedFacultyId = value;
                      });
                    },
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _assignFaculty(subId, selectedFacultyId);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
    );
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

  Future<void> _createSubgroup(int stageId) async {
    if (subNameController.text.trim().isEmpty || subThreshController.text.trim().isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/stages/$stageId/subgroups"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "name": subNameController.text.trim(),
          "threshold": int.parse(subThreshController.text.trim()),
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || (response.statusCode == 200 && data["success"] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subgroup created successfully!"), backgroundColor: Colors.green),
        );
        subNameController.clear();
        subThreshController.clear();
        Navigator.pop(context);
        setState(() => isLoading = true);
        _fetchStages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to create subgroup")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subgroup added locally"), backgroundColor: Colors.orange),
      );
      setState(() {
        final stage = stagesList.firstWhere((element) => element["id"] == stageId);
        stage["subgroups"].add({
          "id": 999 + stage["subgroups"].length,
          "name": subNameController.text,
          "threshold": int.parse(subThreshController.text),
        });
      });
      subNameController.clear();
      subThreshController.clear();
      Navigator.pop(context);
    }
  }

  Future<void> _editSubgroup(int subId, String currentName, int currentThresh) async {
    subNameController.text = currentName;
    subThreshController.text = currentThresh.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Subgroup", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: subNameController, decoration: const InputDecoration(labelText: "Subgroup Name *")),
              TextField(controller: subThreshController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Threshold Value *")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                try {
                  final res = await http.put(
                    Uri.parse("http://10.0.2.2:8080/api/v1/admin/subgroups/$subId"),
                    headers: {
                      "Content-Type": "application/json",
                      "Authorization": "Bearer ${widget.token}",
                    },
                    body: jsonEncode({
                      "name": subNameController.text.trim(),
                      "threshold": int.parse(subThreshController.text.trim()),
                    }),
                  );
                  if (!mounted) return;
                  if (res.statusCode == 200) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text("Subgroup updated"), backgroundColor: Colors.green),
                    );
                    navigator.pop();
                    setState(() => isLoading = true);
                    _fetchStages();
                  }
                } catch (e) {
                  if (!mounted) return;
                  navigator.pop();
                  setState(() {
                    for (var stage in stagesList) {
                      for (var sub in stage["subgroups"]) {
                        if (sub["id"] == subId) {
                          sub["name"] = subNameController.text;
                          sub["threshold"] = int.parse(subThreshController.text);
                        }
                      }
                    }
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  Future<void> _deleteSubgroup(int subId) async {
    try {
      final response = await http.delete(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/subgroups/$subId"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subgroup deleted"), backgroundColor: Colors.green),
        );
        setState(() => isLoading = true);
        _fetchStages();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        for (var stage in stagesList) {
          stage["subgroups"].removeWhere((s) => s["id"] == subId);
        }
      });
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

  void _showAddSubgroupDialog(int stageId) {
    subNameController.clear();
    subThreshController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Subgroup to Stage", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: subNameController, decoration: const InputDecoration(labelText: "Subgroup Name * (e.g. must (individual))")),
              TextField(controller: subThreshController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Threshold Value * (e.g. 30)")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () => _createSubgroup(stageId),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
              child: const Text("Add", style: TextStyle(color: Colors.white)),
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
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            desc,
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _showAddSubgroupDialog(stage["id"]),
                                          icon: const Icon(Icons.add, size: 16, color: Colors.blue),
                                          label: const Text("Subgroup", style: TextStyle(fontSize: 12, color: Colors.blue)),
                                        ),
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
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                if (subgroups.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      "No subgroups configured for this stage yet.",
                                      style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: subgroups.length,
                                    itemBuilder: (context, subIndex) {
                                      final sub = subgroups[subIndex];
                                      final String subName = sub["name"] ?? '';
                                      final int threshold = sub["threshold"] ?? 0;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(subName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                                  const SizedBox(height: 2),
                                                  Text("Threshold: $threshold pts", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "Faculty: ${sub["assignedFacultyName"] ?? "All Teachers"}",
                                                    style: TextStyle(
                                                      color: sub["assignedFacultyName"] != null ? Colors.teal : Colors.grey.shade500,
                                                      fontSize: 12,
                                                      fontWeight: sub["assignedFacultyName"] != null ? FontWeight.bold : FontWeight.normal
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.assignment_ind_outlined, color: Colors.teal, size: 18),
                                              tooltip: "Assign Faculty",
                                              onPressed: () => _showAssignFacultyDialog(sub["id"], sub["assignedFacultyId"]),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                                              onPressed: () => _editSubgroup(sub["id"], subName, threshold),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text("Delete Subgroup"),
                                                    content: Text("Are you sure you want to delete subgroup $subName?"),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(context);
                                                          _deleteSubgroup(sub["id"]);
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
