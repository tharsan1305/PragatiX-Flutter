import 'package:spdms_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TeacherGroupManagementTab extends StatefulWidget {
  final String token;
  const TeacherGroupManagementTab({super.key, required this.token});

  @override
  State<TeacherGroupManagementTab> createState() => _TeacherGroupManagementTabState();
}

class _TeacherGroupManagementTabState extends State<TeacherGroupManagementTab> {
  bool _isLoading = true;
  List<dynamic> _groups = [];

  // Dynamic filter values built from live data
  List<String> _depts = ["All"];
  List<String> _years = ["All"];
  List<String> _sections = ["All"];

  String? selectedDept;
  String? selectedYear;
  String? selectedSection;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() => _isLoading = true);
    const url = "${ApiConfig.baseUrl}/api/v1/teams";
    debugPrint("API URL: $url");
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      debugPrint("HTTP Status Code: ${response.statusCode}");
      debugPrint("Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final List<dynamic> groups = data["data"] ?? [];
          debugPrint("Parsed Team Count: ${groups.length}");

          // Build dynamic filter options from members
          final deptSet = <String>{};
          final yearSet = <String>{};
          final sectionSet = <String>{};
          for (final g in groups) {
            for (final m in (g["teamMembers"] ?? [])) {
              if (m["department"] != null) deptSet.add(m["department"]);
              if (m["year"] != null) yearSet.add(m["year"].toString());
              if (m["section"] != null) sectionSet.add(m["section"]);
            }
          }

          setState(() {
            _groups = groups;
            _depts = ["All", ...deptSet.toList()..sort()];
            _years = ["All", ...yearSet.toList()..sort()];
            _sections = ["All", ...sectionSet.toList()..sort()];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching teams: $e");
    }
    setState(() => _isLoading = false);
  }

  List<dynamic> get _filteredGroups {
    return _groups.where((g) {
      final members = (g["teamMembers"] ?? []) as List<dynamic>;
      if (selectedDept != null && selectedDept != "All") {
        if (!members.any((m) => m["department"] == selectedDept)) return false;
      }
      if (selectedYear != null && selectedYear != "All") {
        if (!members.any((m) => m["year"]?.toString() == selectedYear)) return false;
      }
      if (selectedSection != null && selectedSection != "All") {
        if (!members.any((m) => m["section"] == selectedSection)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Groups'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchGroups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // FILTERS
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.indigo.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFilterDropdown("Dept", _depts, selectedDept, (val) => setState(() => selectedDept = val)),
                      _buildFilterDropdown("Year", _years, selectedYear, (val) => setState(() => selectedYear = val)),
                      _buildFilterDropdown("Section", _sections, selectedSection, (val) => setState(() => selectedSection = val)),
                    ],
                  ),
                ),
                // GROUPS LIST
                Expanded(
                  child: _filteredGroups.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.group_off_rounded, size: 64, color: Colors.grey),
                              const SizedBox(height: 12),
                              const Text("No groups found", style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _fetchGroups,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Refresh"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredGroups.length,
                          itemBuilder: (context, index) {
                            final g = _filteredGroups[index];
                            final captainName = g["captainName"] ?? "No Captain";
                            final memberCount = (g["teamMembers"] as List?)?.length ?? 0;
                            final groupName = g["teamName"] ?? "Group";
                            final size = g["teamCapacity"] ?? 0;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo.withOpacity(0.1),
                                  child: const Icon(Icons.groups_rounded, color: Colors.indigo),
                                ),
                                title: Text(
                                  groupName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "Captain: $captainName  •  $memberCount/$size members",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _showAddMemberDialog(g["teamId"]),
                                          icon: const Icon(Icons.person_add, size: 16),
                                          label: const Text("Add Member"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade50,
                                            foregroundColor: Colors.green.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _showUpdateLimitDialog(g["teamId"], size),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text("Edit Limit"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.indigo.shade50,
                                            foregroundColor: Colors.indigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...(g["teamMembers"] as List? ?? []).map<Widget>((m) {
                                    final isCaptain = m["studentId"] == g["captainId"];
                                    return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isCaptain ? Colors.amber : Colors.indigo.shade100,
                                      child: Icon(
                                        isCaptain ? Icons.star_rounded : Icons.person,
                                        size: 16,
                                        color: isCaptain ? Colors.white : Colors.indigo,
                                      ),
                                    ),
                                    title: Text(m["fullName"] ?? "Student"),
                                    subtitle: Text(
                                      "${m["studentId"]} • ${m["department"] ?? ''} ${m["year"] ?? ''} ${m["section"] ?? ''}".trim(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isCaptain)
                                          const Chip(
                                            label: Text("Captain", style: TextStyle(fontSize: 10)),
                                            backgroundColor: Colors.amber,
                                          ),
                                        if (!isCaptain)
                                          IconButton(
                                            icon: const Icon(Icons.person_remove, color: Colors.red, size: 20),
                                            tooltip: "Remove Member",
                                            onPressed: () => _removeMemberByCC(g["teamId"], m["studentId"], m["fullName"] ?? "Student"),
                                          ),
                                      ],
                                    ),
                                  );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterDropdown(String hint, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            isDense: true,
          ),
          items: items
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showUpdateLimitDialog(int teamId, int currentSize) {
    final limitCtrl = TextEditingController(text: currentSize.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Group Limit"),
          content: TextField(
            controller: limitCtrl,
            decoration: const InputDecoration(
              labelText: "Max Size Limit",
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newSize = int.tryParse(limitCtrl.text);
                if (newSize == null || newSize <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid positive number')),
                  );
                  return;
                }
                Navigator.pop(context);
                await _updateGroupLimit(teamId, newSize);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateGroupLimit(int teamId, int newSize) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/teams/$teamId/limit?size=$newSize"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group limit updated successfully!'), backgroundColor: Colors.green),
        );
        _fetchGroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? 'Failed to update group limit'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showAddMemberDialog(int teamId) {
    final studentIdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Member"),
          content: TextField(
            controller: studentIdCtrl,
            decoration: const InputDecoration(
              labelText: "Student ID (e.g. 24CS01)",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final studentId = studentIdCtrl.text.trim();
                if (studentId.isNotEmpty) {
                  Navigator.pop(context);
                  _addMemberByCC(teamId, studentId);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMemberByCC(int teamId, String studentId) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/teams/$teamId/add-member?studentId=$studentId"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully!'), backgroundColor: Colors.green),
        );
        _fetchGroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? 'Failed to add member'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _removeMemberByCC(int teamId, String studentId, String name) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/teams/$teamId/remove-member?studentId=$studentId"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed $name successfully!'), backgroundColor: Colors.green),
        );
        _fetchGroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? 'Failed to remove member'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }
}
