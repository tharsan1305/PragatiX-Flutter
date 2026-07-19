import 'package:spdms_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../stage_details_page.dart';
import '../create_stage_page.dart';
import '../edit_stage_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity Tab – Stage list with create / edit / delete.
// Tapping a stage navigates to StageDetailsPage → Subgroup → ActivityListPage.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityTab extends StatefulWidget {
  final String token;

  const ActivityTab({super.key, required this.token});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  List<dynamic> _stagesList = [];
  List<dynamic> _teachersList = [];
  bool _isLoading = true;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _fetchStages();
    _fetchTeachers();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _fetchTeachers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/users'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final allUsers = data['data'] as List<dynamic>? ?? [];
          if (!mounted) return;
          setState(() {
            _teachersList = allUsers.where((u) {
              final roles = u['roles'] as List<dynamic>? ?? [];
              return roles.contains('ROLE_TEACHER');
            }).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchStages() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/stages'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          if (!mounted) return;
          setState(() {
            _stagesList = data['data'] as List<dynamic>? ?? [];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _stagesList = [
        {
          'id': 1,
          'name': 'Stage 1',
          'description': 'Initial threshold limits',
          'startDate': '2026-01-01',
          'endDate': '2026-01-31',
          'displayOrder': 1,
          'isActive': true,
          'subgroups': [
            {'id': 1, 'name': 'must (individual)', 'threshold': 30},
            {'id': 2, 'name': 'individual', 'threshold': 20},
            {'id': 3, 'name': 'groups', 'threshold': 50},
          ],
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _deleteStage(int stageId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/stages/$stageId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Stage deleted successfully'),
              backgroundColor: Colors.green),
        );
        setState(() => _isLoading = true);
        _fetchStages();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ?? 'Failed to delete stage'),
              backgroundColor: Colors.redAccent),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stagesList.removeWhere((s) => s['id'] == stageId);
      });
    }
  }

  String _formatDuration(String? start, String? end) {
    if (start == null || end == null || start.isEmpty || end.isEmpty) {
      return 'No duration set';
    }
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      return '${DateFormat('dd MMM yyyy').format(s)} → ${DateFormat('dd MMM yyyy').format(e)}';
    } catch (_) {
      return '$start → $end';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity & Thresholds',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _dark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchStages();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Configure Stages & Thresholds',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateStagePage(token: widget.token),
                            ),
                          ).then((value) {
                            if (value == true) {
                              setState(() => _isLoading = true);
                              _fetchStages();
                            }
                          });
                        },
                        icon: const Icon(Icons.add,
                            color: Colors.white, size: 18),
                        label: const Text('Add Stage',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _stagesList.length,
                      itemBuilder: (context, index) {
                        final stage =
                            _stagesList[index] as Map<String, dynamic>;
                        final name = stage['name'] as String? ?? '';
                        final desc = stage['description'] as String? ??
                            'No description';
                        final subgroups =
                            stage['subgroups'] as List<dynamic>? ?? [];
                        final String statusStr = stage['status'] as String? ?? 'UPCOMING';
                        final displayOrder = stage['displayOrder'] ?? 0;

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 20),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StageDetailsPage(
                                    token: widget.token,
                                    stageId: stage['id'] as int,
                                    stageName: name,
                                    stageDescription: desc,
                                    teachersList: _teachersList,
                                  ),
                                ),
                              ).then((_) {
                                setState(() => _isLoading = true);
                                _fetchStages();
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(name,
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: _dark)),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusStr == 'ACTIVE' ? Colors.green.shade50 : (statusStr == 'UPCOMING' ? Colors.blue.shade50 : Colors.grey.shade100),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: statusStr == 'ACTIVE' ? Colors.green.shade300 : (statusStr == 'UPCOMING' ? Colors.blue.shade300 : Colors.grey.shade400),
                                                ),
                                              ),
                                              child: Text(
                                                statusStr,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: statusStr == 'ACTIVE' ? Colors.green.shade800 : (statusStr == 'UPCOMING' ? Colors.blue.shade800 : Colors.grey.shade700),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(desc,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600)),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Order: $displayOrder',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: _dark,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.access_time_rounded, size: 14, color: Colors.blue),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDuration(stage['startDate'] as String?, stage['endDate'] as String?),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade700,
                                                      fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${subgroups.length} sub-branches configured',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.edit_outlined,
                                            color: Colors.blue),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditStagePage(
                                                token: widget.token,
                                                stage: stage,
                                              ),
                                            ),
                                          ).then((value) {
                                            if (value == true) {
                                              setState(() => _isLoading = true);
                                              _fetchStages();
                                            }
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red),
                                        onPressed: () {
                                          showDialog<void>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                  'Delete Stage'),
                                              content: Text(
                                                  'Are you sure you want to delete $name and all its subgroups?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child:
                                                      const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                    _deleteStage(
                                                        stage['id'] as int);
                                                  },
                                                  child: const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.grey),
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
