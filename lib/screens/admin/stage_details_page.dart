import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'subgroup_activities_page.dart';

class StageDetailsPage extends StatefulWidget {
  final String token;
  final int stageId;
  final String stageName;
  final String stageDescription;
  final List<dynamic> teachersList;

  const StageDetailsPage({
    super.key,
    required this.token,
    required this.stageId,
    required this.stageName,
    required this.stageDescription,
    required this.teachersList,
  });

  @override
  State<StageDetailsPage> createState() => _StageDetailsPageState();
}

class _StageDetailsPageState extends State<StageDetailsPage> {
  List<dynamic> _subgroups = [];
  bool _isLoading = true;

  final TextEditingController subNameController = TextEditingController();
  final TextEditingController subThreshController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSubgroups();
  }

  Future<void> _fetchSubgroups() async {
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
          final List<dynamic> stages = data["data"] ?? [];
          final stage = stages.firstWhere((s) => s["id"] == widget.stageId, orElse: () => null);
          if (stage != null) {
            setState(() {
              _subgroups = stage["subgroups"] ?? [];
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      // Offline fallback
    }

    // Offline mock data if fetch fails
    setState(() {
      if (_subgroups.isEmpty) {
        _subgroups = [
          {"id": 1, "name": "must (individual)", "threshold": 30, "assignedFacultyName": null},
          {"id": 2, "name": "individual", "threshold": 20, "assignedFacultyName": null},
          {"id": 3, "name": "groups", "threshold": 50, "assignedFacultyName": null}
        ];
      }
      _isLoading = false;
    });
  }

  String _getCleanSubgroupName(String fullName) {
    final lower = fullName.toLowerCase();
    if (lower.endsWith(" (must)")) {
      return fullName.substring(0, fullName.length - 7);
    } else if (lower.endsWith(" (individual)")) {
      return fullName.substring(0, fullName.length - 13);
    } else if (lower.endsWith(" (group)")) {
      return fullName.substring(0, fullName.length - 8);
    }
    return fullName;
  }

  Future<void> _createSubgroup(String typeName, String category) async {
    if (subThreshController.text.trim().isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/stages/${widget.stageId}/subgroups"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "name": typeName,
          "threshold": int.parse(subThreshController.text.trim()),
          "category": category,
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || (response.statusCode == 200 && data["success"] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subgroup created successfully!"), backgroundColor: Colors.green),
        );
        subThreshController.clear();
        setState(() => _isLoading = true);
        _fetchSubgroups();
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
        _subgroups.add({
          "id": 999 + _subgroups.length,
          "name": typeName,
          "threshold": int.parse(subThreshController.text),
          "assignedFacultyName": null
        });
      });
      subThreshController.clear();
    }
  }

  Future<void> _editSubgroup(int subId, String currentName, int currentThresh) async {
    String cleanName = currentName;
    String suffix = "";
    final lower = currentName.toLowerCase();
    if (lower.endsWith(" (must)")) {
      cleanName = currentName.substring(0, currentName.length - 7);
      suffix = " (must)";
    } else if (lower.endsWith(" (individual)")) {
      cleanName = currentName.substring(0, currentName.length - 13);
      suffix = " (individual)";
    } else if (lower.endsWith(" (group)")) {
      cleanName = currentName.substring(0, currentName.length - 8);
      suffix = " (group)";
    } else {
      if (lower.contains("must")) {
        suffix = " (must)";
      } else if (lower.contains("group")) {
        suffix = " (group)";
      } else {
        suffix = " (individual)";
      }
    }

    subNameController.text = cleanName;
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
                if (subNameController.text.trim().isEmpty || subThreshController.text.trim().isEmpty) return;

                final String fullName = subNameController.text.trim() + suffix;
                try {
                  final res = await http.put(
                    Uri.parse("http://10.0.2.2:8080/api/v1/admin/subgroups/$subId"),
                    headers: {
                      "Content-Type": "application/json",
                      "Authorization": "Bearer ${widget.token}",
                    },
                    body: jsonEncode({
                      "name": fullName,
                      "threshold": int.parse(subThreshController.text.trim()),
                    }),
                  );
                  if (!mounted) return;
                  if (res.statusCode == 200) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text("Subgroup updated"), backgroundColor: Colors.green),
                    );
                    navigator.pop();
                    setState(() => _isLoading = true);
                    _fetchSubgroups();
                  }
                } catch (e) {
                  if (!mounted) return;
                  navigator.pop();
                  setState(() {
                    for (var sub in _subgroups) {
                      if (sub["id"] == subId) {
                        sub["name"] = fullName;
                        sub["threshold"] = int.parse(subThreshController.text);
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
        setState(() => _isLoading = true);
        _fetchSubgroups();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subgroups.removeWhere((s) => s["id"] == subId);
      });
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
        _fetchSubgroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to assign faculty")),
        );
      }
    } catch (e) {
      setState(() {
        for (var sub in _subgroups) {
          if (sub["id"] == subId) {
            if (userId == null) {
              sub["assignedFacultyId"] = null;
              sub["assignedFacultyName"] = null;
            } else {
              final teacher = widget.teachersList.firstWhere((t) => t["id"] == userId, orElse: () => null);
              sub["assignedFacultyId"] = userId;
              sub["assignedFacultyName"] = teacher != null ? teacher["fullName"] : "Assigned";
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
                      ...widget.teachersList.map((t) {
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

  void _showAddSubgroupDialog() {
    String selectedType = "must(individual)";
    subNameController.text = "";
    subThreshController.text = "";
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Subgroup to Stage", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subNameController,
                    decoration: const InputDecoration(labelText: "Subgroup Name * (e.g. must (individual))"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: "Sub-branch Type *"),
                    items: const [
                      DropdownMenuItem(value: "must(individual)", child: Text("Must (Individual)")),
                      DropdownMenuItem(value: "individual", child: Text("Individual")),
                      DropdownMenuItem(value: "Group", child: Text("Group")),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        selectedType = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subThreshController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Threshold Value * (e.g. 70)"),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (subNameController.text.trim().isEmpty || subThreshController.text.trim().isEmpty) return;
                    Navigator.pop(context);

                    String suffix = "";
                    String catVal = "individual";
                    if (selectedType == "must(individual)") {
                      suffix = " (must)";
                      catVal = "must";
                    } else if (selectedType == "individual") {
                      suffix = " (individual)";
                      catVal = "individual";
                    } else if (selectedType == "Group") {
                      suffix = " (group)";
                      catVal = "group";
                    }

                    final String fullName = subNameController.text.trim() + suffix;
                    _createSubgroup(fullName, catVal);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA4335)),
                  child: const Text("Add", style: TextStyle(color: Colors.white)),
                )
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
        title: Text(widget.stageName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stage details card
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.stageName,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.stageDescription,
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddSubgroupDialog,
                            icon: const Icon(Icons.add, color: Colors.white, size: 18),
                            label: const Text("Subgroup", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA4335),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Configure Sub-branches",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _subgroups.isEmpty
                        ? Center(
                            child: Text(
                              "No subgroups configured for this stage yet.",
                              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _subgroups.length,
                            itemBuilder: (context, index) {
                              final sub = _subgroups[index];
                              final String subName = sub["name"] ?? '';
                              final int threshold = sub["threshold"] ?? 0;

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    String catVal = sub["category"] ?? "";
                                    if (catVal.isEmpty) {
                                      final String nameLower = subName.toLowerCase();
                                      if (nameLower.contains("must")) {
                                        catVal = "must";
                                      } else if (nameLower.contains("group")) {
                                        catVal = "group";
                                      } else {
                                        catVal = "individual";
                                      }
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SubgroupActivitiesPage(
                                          token: widget.token,
                                          subgroupId: sub["id"],
                                          subgroupName: subName,
                                          subgroupCategory: catVal,
                                          teachersList: widget.teachersList,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_getCleanSubgroupName(subName), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 4),
                                              Text("Threshold: $threshold pts", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Faculty: ${sub["assignedFacultyName"] ?? "All Teachers"}",
                                                style: TextStyle(
                                                  color: sub["assignedFacultyName"] != null ? Colors.teal : Colors.grey.shade500,
                                                  fontSize: 13,
                                                  fontWeight: sub["assignedFacultyName"] != null ? FontWeight.bold : FontWeight.normal
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.assignment_ind_outlined, color: Colors.teal, size: 22),
                                          tooltip: "Assign Faculty",
                                          onPressed: () => _showAssignFacultyDialog(sub["id"], sub["assignedFacultyId"]),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 22),
                                          tooltip: "Edit Subgroup",
                                          onPressed: () => _editSubgroup(sub["id"], subName, threshold),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                          tooltip: "Delete Subgroup",
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
