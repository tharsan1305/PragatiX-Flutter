import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../stage_details_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity Tab – Stage list with create / delete.
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

  final TextEditingController _stageNameCtrl = TextEditingController();
  final TextEditingController _stageDescCtrl = TextEditingController();

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _fetchStages();
    _fetchTeachers();
  }

  @override
  void dispose() {
    _stageNameCtrl.dispose();
    _stageDescCtrl.dispose();
    super.dispose();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _fetchTeachers() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/v1/admin/users'),
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
        Uri.parse('http://10.0.2.2:8080/api/v1/admin/stages'),
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

  Future<void> _createStage() async {
    if (_stageNameCtrl.text.trim().isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/v1/admin/stages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': _stageNameCtrl.text.trim(),
          'description': _stageDescCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 ||
          (response.statusCode == 200 && data['success'] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Stage created successfully!'),
              backgroundColor: Colors.green),
        );
        _stageNameCtrl.clear();
        _stageDescCtrl.clear();
        Navigator.pop(context);
        setState(() => _isLoading = true);
        _fetchStages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ?? 'Failed to create stage')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Stage added locally'),
            backgroundColor: Colors.orange),
      );
      setState(() {
        _stagesList.add({
          'id': _stagesList.length + 1,
          'name': _stageNameCtrl.text,
          'description': _stageDescCtrl.text,
          'subgroups': <dynamic>[],
        });
      });
      _stageNameCtrl.clear();
      _stageDescCtrl.clear();
      Navigator.pop(context);
    }
  }

  Future<void> _deleteStage(int stageId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8080/api/v1/admin/stages/$stageId'),
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
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stagesList.removeWhere((s) => s['id'] == stageId);
      });
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showAddStageDialog() {
    _stageNameCtrl.clear();
    _stageDescCtrl.clear();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Activity Stage',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _stageNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Stage Name * (e.g. Stage 1)')),
              TextField(
                  controller: _stageDescCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Description')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: _createStage,
              style:
                  ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text('Create',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
                            color: _dark),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddStageDialog,
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
                                        Text(name,
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: _dark)),
                                        const SizedBox(height: 6),
                                        Text(desc,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600)),
                                        const SizedBox(height: 10),
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
