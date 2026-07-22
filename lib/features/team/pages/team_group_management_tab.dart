import 'package:spdms_app/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:spdms_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:spdms_app/features/team/services/team_proxy_service.dart';
import 'package:spdms_app/core/di/service_locator.dart';
import 'package:spdms_app/shared/widgets/student_search/student_search_field.dart';

import 'package:spdms_app/features/team/pages/team_details_page.dart';

// Dialogs removed from here

class TeamGroupManagementTab extends StatefulWidget {
  const TeamGroupManagementTab({super.key, });

  @override
  State<TeamGroupManagementTab> createState() => _TeamGroupManagementTabState();
}

class _TeamGroupManagementTabState extends State<TeamGroupManagementTab> {
  bool _isLoading = true;
  List<dynamic> _groups = [];

  // Dynamic filter values built from live data
  List<String> _depts = ['All'];
  List<String> _years = ['All'];
  List<String> _sections = ['All'];

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
    const url = '${ApiConfig.baseUrl}/api/v1/teams';
    debugPrint('API URL: $url');
    try {
      final response = await getIt<TeamProxyService>().get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${context.read<AuthProvider>().token!}'},
      );
      debugPrint('HTTP Status Code: ${response.statusCode}');
      debugPrint('Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> groups = data['data'] ?? [];
          debugPrint('Parsed Team Count: ${groups.length}');

          // Build dynamic filter options from members
          final deptSet = <String>{};
          final yearSet = <String>{};
          final sectionSet = <String>{};
          for (final g in groups) {
            for (final m in (g['teamMembers'] ?? [])) {
              if (m['department'] != null) deptSet.add(m['department']);
              if (m['year'] != null) yearSet.add(m['year'].toString());
              if (m['section'] != null) sectionSet.add(m['section']);
            }
          }

          setState(() {
            _groups = groups;
            _depts = ['All', ...deptSet.toList()..sort()];
            _years = ['All', ...yearSet.toList()..sort()];
            _sections = ['All', ...sectionSet.toList()..sort()];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching teams: $e');
    }
    setState(() => _isLoading = false);
  }

  List<dynamic> get _filteredGroups {
    return _groups.where((g) {
      final members = (g['teamMembers'] ?? []) as List<dynamic>;
      if (selectedDept != null && selectedDept != 'All') {
        if (!members.any((m) => m['department'] == selectedDept)) return false;
      }
      if (selectedYear != null && selectedYear != 'All') {
        if (!members.any((m) => m['year']?.toString() == selectedYear)) return false;
      }
      if (selectedSection != null && selectedSection != 'All') {
        if (!members.any((m) => m['section'] == selectedSection)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final role = context.read<AuthProvider>().role;
    final subroles = currentUser?['subRoles'] as List<dynamic>? ?? [];
    final isCC = subroles.any((r) => r == 'CC' || (r is Map && r['name'] == 'CC'));
    final isAdmin = role == 'ROLE_ADMIN' || role == 'ADMIN';
    final canManage = isCC || isAdmin;

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
                      _buildFilterDropdown('Dept', _depts, selectedDept, (val) => setState(() => selectedDept = val)),
                      _buildFilterDropdown('Year', _years, selectedYear, (val) => setState(() => selectedYear = val)),
                      _buildFilterDropdown('Section', _sections, selectedSection, (val) => setState(() => selectedSection = val)),
                    ],
                  ),
                ),
                if (canManage)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showCreateGroupDialog,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Create Team', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
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
                              const Text('No groups found', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _fetchGroups,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredGroups.length,
                          itemBuilder: (context, index) {
                            final g = _filteredGroups[index];
                            final captainName = g['captainName'] ?? 'No Captain';
                            final memberCount = (g['teamMembers'] as List?)?.length ?? 0;
                            final groupName = g['teamName'] ?? 'Group';
                            final size = g['teamCapacity'] ?? 0;

                            final currentStage = (g['teamMembers'] as List?)?.isNotEmpty == true
                                ? (g['teamMembers'][0]['currentStage'] ?? 1)
                                : 1;
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeamDetailsPage(
                                        teamId: g['teamId'] ?? g['id'],
                                        canManage: canManage,
                                      ),
                                    ),
                                  );
                                  // Refresh if a team was deleted or changed
                                  if (result == true) {
                                    _fetchGroups();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                                        child: const Icon(Icons.groups_rounded, color: Colors.indigo),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              groupName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Captain: $captainName  •  $memberCount/$size members',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${g['departmentName'] ?? '-'} • ${g['year'] ?? '-'} - ${g['sectionName'] ?? '-'}",
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                                                  child: Text(
                                                    'Stage $currentStage',
                                                    style: TextStyle(color: Colors.amber.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.grey),
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
    );
  }

  Widget _buildFilterDropdown(String hint, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: DropdownButtonFormField<String>(
          initialValue: value,
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


  Future<void> _createGroup(String name, int limit, String captainStudentId) async {
    try {
      final body = jsonEncode({
        'name': name,
        'size': limit,
        'captainStudentId': captainStudentId,
      });

      final response = await getIt<TeamProxyService>().post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final data = json.decode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team created successfully!'), backgroundColor: Colors.green),
          );
          _fetchGroups();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to create team'), backgroundColor: Colors.redAccent),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to create team'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: "5");
    Map<String, dynamic>? selectedCaptain;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Team'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Team Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: limitCtrl,
                      decoration: const InputDecoration(labelText: 'Max Size Limit', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    StudentSearchField(
                      selectedStudent: selectedCaptain,
                      onStudentSelected: (student) {
                        setState(() {
                          selectedCaptain = student;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final limit = int.tryParse(limitCtrl.text) ?? 5;
                    
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Team Name is required'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }
                    if (limit < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Team Capacity must be at least 1'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }
                    if (selectedCaptain == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Captain is required'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    _createGroup(name, limit, selectedCaptain!['regNo']);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
