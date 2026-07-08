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
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/groups"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final List<dynamic> groups = data["data"] ?? [];

          // Build dynamic filter options from members
          final deptSet = <String>{};
          final yearSet = <String>{};
          final sectionSet = <String>{};
          for (final g in groups) {
            for (final m in (g["students"] ?? [])) {
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
      // fallback
    }
    setState(() => _isLoading = false);
  }

  List<dynamic> get _filteredGroups {
    return _groups.where((g) {
      final members = (g["students"] ?? []) as List<dynamic>;
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
                            final memberCount = (g["students"] as List?)?.length ?? 0;
                            final groupName = g["name"] ?? "Group";
                            final size = g["size"] ?? 0;

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
                                children: (g["students"] as List? ?? []).map<Widget>((m) {
                                  final isCaptain = m["studentId"] == g["captainStudentId"];
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
                                    trailing: isCaptain
                                        ? const Chip(
                                            label: Text("Captain", style: TextStyle(fontSize: 10)),
                                            backgroundColor: Colors.amber,
                                          )
                                        : null,
                                  );
                                }).toList(),
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
}
