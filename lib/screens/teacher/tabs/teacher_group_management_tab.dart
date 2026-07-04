import 'package:flutter/material.dart';

class TeacherGroupManagementTab extends StatefulWidget {
  final String token;
  const TeacherGroupManagementTab({super.key, required this.token});

  @override
  State<TeacherGroupManagementTab> createState() => _TeacherGroupManagementTabState();
}

class _TeacherGroupManagementTabState extends State<TeacherGroupManagementTab> {
  // Dummy data representing existing groups
  final List<Map<String, String>> dummyGroups = [
    {"groupName": "Science Club", "captain": "Alice Johnson", "dept": "CSE", "year": "1st Year", "section": "A"},
    {"groupName": "Sports Team Alpha", "captain": "Bob Smith", "dept": "ECE", "year": "2nd Year", "section": "B"},
    {"groupName": "Robotics Squad", "captain": "Charlie Brown", "dept": "CSE", "year": "2nd Year", "section": "A"},
  ];

  // Filter States
  String? selectedDept;
  String? selectedYear;
  String? selectedSection;

  @override
  Widget build(BuildContext context) {
    // Apply filters to our dummy list
    List<Map<String, String>> filteredGroups = dummyGroups.where((group) {
      bool matchesDept = selectedDept == null || selectedDept == "All" || group["dept"] == selectedDept;
      bool matchesYear = selectedYear == null || selectedYear == "All" || group["year"] == selectedYear;
      bool matchesSection = selectedSection == null || selectedSection == "All" || group["section"] == selectedSection;
      return matchesDept && matchesYear && matchesSection;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Groups'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // FILTERS UI
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterDropdown("Dept", ["All", "CSE", "ECE", "MECH"], selectedDept, (val) {
                  setState(() => selectedDept = val);
                }),
                _buildFilterDropdown("Year", ["All", "1st Year", "2nd Year", "3rd Year", "4th Year"], selectedYear, (val) {
                  setState(() => selectedYear = val);
                }),
                _buildFilterDropdown("Class", ["All", "A", "B", "C"], selectedSection, (val) {
                  setState(() => selectedSection = val);
                }),
              ],
            ),
          ),
          
          // LIST OF GROUPS
          Expanded(
            child: filteredGroups.isEmpty
                ? const Center(child: Text("No groups match your filters!"))
                : ListView.builder(
                    itemCount: filteredGroups.length,
                    itemBuilder: (context, index) {
                      final group = filteredGroups[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.group_work_rounded, color: Colors.indigo, size: 32),
                          title: Text(group['groupName']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Captain: ${group['captain']} | ${group['dept']} - ${group['year']} - Sec ${group['section']}"),
                          trailing: const Icon(Icons.visibility_rounded, color: Colors.grey),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Viewing members of ${group['groupName']}')),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Helper method to build tiny dropdowns
  Widget _buildFilterDropdown(String hint, List<String> options, String? currentValue, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      hint: Text(hint),
      value: currentValue,
      icon: const Icon(Icons.arrow_drop_down, size: 16),
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      underline: Container(), // hide the underline
      onChanged: onChanged,
      items: options.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
