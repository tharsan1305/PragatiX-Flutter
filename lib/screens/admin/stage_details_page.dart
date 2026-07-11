import 'package:spdms_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../admin/activity/pages/activity_list_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stage Details Page – shows subgroup list for a given stage.
// Tapping a subgroup navigates to ActivityListPage (new module).
// ─────────────────────────────────────────────────────────────────────────────

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

  final TextEditingController _subNameCtrl = TextEditingController();
  final TextEditingController _subThreshCtrl = TextEditingController();

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _fetchSubgroups();
  }

  @override
  void dispose() {
    _subNameCtrl.dispose();
    _subThreshCtrl.dispose();
    super.dispose();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _fetchSubgroups() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/stages'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final stages = data['data'] as List<dynamic>? ?? [];
          final stage = stages.cast<Map<String, dynamic>?>().firstWhere(
            (s) => s?['id'] == widget.stageId,
            orElse: () => null,
          );
          if (stage != null) {
            setState(() {
              _subgroups = stage['subgroups'] as List<dynamic>? ?? [];
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (_) {}
    setState(() {
      if (_subgroups.isEmpty) {
        _subgroups = [
          {'id': 1, 'name': 'must (individual)', 'threshold': 30, 'assignedFacultyName': null},
          {'id': 2, 'name': 'individual', 'threshold': 20, 'assignedFacultyName': null},
          {'id': 3, 'name': 'groups', 'threshold': 50, 'assignedFacultyName': null},
        ];
      }
      _isLoading = false;
    });
  }

  Future<void> _createSubgroup(String typeName, String category) async {
    if (_subThreshCtrl.text.trim().isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/admin/stages/${widget.stageId}/subgroups'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': typeName,
          'threshold': int.parse(_subThreshCtrl.text.trim()),
          'category': category,
        }),
      );
      if (!mounted) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 ||
          (response.statusCode == 200 && data['success'] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Subgroup created successfully!'),
              backgroundColor: Colors.green),
        );
        _subThreshCtrl.clear();
        setState(() => _isLoading = true);
        _fetchSubgroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ?? 'Failed to create subgroup')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Subgroup added locally'),
            backgroundColor: Colors.orange),
      );
      final thresh = int.tryParse(_subThreshCtrl.text) ?? 0;
      setState(() {
        _subgroups.add({
          'id': 999 + _subgroups.length,
          'name': typeName,
          'threshold': thresh,
          'assignedFacultyName': null,
        });
      });
      _subThreshCtrl.clear();
    }
  }

  Future<void> _deleteSubgroup(int subId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/subgroups/$subId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Subgroup deleted'),
              backgroundColor: Colors.green),
        );
        setState(() => _isLoading = true);
        _fetchSubgroups();
      }
    } catch (_) {
      setState(() {
        _subgroups.removeWhere((s) => s['id'] == subId);
      });
    }
  }

  Future<void> _updateSubgroup(
      int subId, String fullName, int threshold) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/subgroups/$subId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'name': fullName, 'threshold': threshold}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Subgroup updated'),
              backgroundColor: Colors.green),
        );
        setState(() => _isLoading = true);
        _fetchSubgroups();
      }
    } catch (_) {
      setState(() {
        for (final sub in _subgroups) {
          if (sub['id'] == subId) {
            sub['name'] = fullName;
            sub['threshold'] = threshold;
          }
        }
      });
    }
  }



  // ── Helpers ───────────────────────────────────────────────────────────────

  String _getCleanName(String fullName) {
    final lower = fullName.toLowerCase();
    if (lower.endsWith(' (must)')) {
      return fullName.substring(0, fullName.length - 7);
    }
    if (lower.endsWith(' (individual)')) {
      return fullName.substring(0, fullName.length - 13);
    }
    if (lower.endsWith(' (group)')) {
      return fullName.substring(0, fullName.length - 8);
    }
    return fullName;
  }

  String _getSuffix(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('must')) return ' (must)';
    if (lower.contains('group')) return ' (group)';
    return ' (individual)';
  }

  String _getCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('must')) return 'must';
    if (lower.contains('group')) return 'group';
    return 'individual';
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showAddSubgroupDialog() {
    String selectedType = 'must(individual)';
    _subNameCtrl.text = '';
    _subThreshCtrl.text = '';
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Subgroup to Stage',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _subNameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Subgroup Name * (e.g. must (individual))'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 'must(individual)',
                          child: Text('Must (Individual)')),
                      DropdownMenuItem(
                          value: 'individual', child: Text('Individual')),
                      DropdownMenuItem(value: 'Group', child: Text('Group')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _subThreshCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Threshold Value * (e.g. 70)'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (_subNameCtrl.text.trim().isEmpty ||
                        _subThreshCtrl.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(ctx);
                    String suffix = ' (individual)';
                    String catVal = 'individual';
                    if (selectedType == 'must(individual)') {
                      suffix = ' (must)';
                      catVal = 'must';
                    } else if (selectedType == 'Group') {
                      suffix = ' (group)';
                      catVal = 'group';
                    }
                    final fullName = _subNameCtrl.text.trim() + suffix;
                    _createSubgroup(fullName, catVal);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary),
                  child: const Text('Add',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditSubgroupDialog(
      int subId, String currentName, int currentThresh) {
    final lower = currentName.toLowerCase();
    String cleanName = currentName;
    String suffix = '';
    if (lower.endsWith(' (must)')) {
      cleanName = currentName.substring(0, currentName.length - 7);
      suffix = ' (must)';
    } else if (lower.endsWith(' (individual)')) {
      cleanName = currentName.substring(0, currentName.length - 13);
      suffix = ' (individual)';
    } else if (lower.endsWith(' (group)')) {
      cleanName = currentName.substring(0, currentName.length - 8);
      suffix = ' (group)';
    } else {
      suffix = _getSuffix(currentName);
    }

    _subNameCtrl.text = cleanName;
    _subThreshCtrl.text = currentThresh.toString();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Subgroup',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _subNameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Subgroup Name *')),
              TextField(
                controller: _subThreshCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Threshold Value *'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (_subNameCtrl.text.trim().isEmpty ||
                    _subThreshCtrl.text.trim().isEmpty) {
                  return;
                }
                final fullName = _subNameCtrl.text.trim() + suffix;
                final thresh =
                    int.tryParse(_subThreshCtrl.text.trim()) ?? 0;
                Navigator.pop(ctx);
                _updateSubgroup(subId, fullName, thresh);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text('Save',
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
        title: Text(widget.stageName,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stage header card ────────────────────────────────────
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    color: Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.stageName,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: _dark)),
                                const SizedBox(height: 6),
                                Text(widget.stageDescription,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddSubgroupDialog,
                            icon: const Icon(Icons.add,
                                color: Colors.white, size: 18),
                            label: const Text('Subgroup',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Configure Sub-branches',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _dark),
                  ),
                  const SizedBox(height: 10),

                  // ── Subgroup list ─────────────────────────────────────────
                  Expanded(
                    child: _subgroups.isEmpty
                        ? Center(
                            child: Text(
                              'No subgroups configured for this stage yet.',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _subgroups.length,
                            itemBuilder: (context, index) {
                              final sub = _subgroups[index]
                                  as Map<String, dynamic>;
                              final subName =
                                  sub['name'] as String? ?? '';
                              final threshold =
                                  sub['threshold'] as int? ?? 0;

                              String catVal =
                                  sub['category'] as String? ?? '';
                              if (catVal.isEmpty) {
                                catVal = _getCategory(subName);
                              }

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16)),
                                margin:
                                    const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ActivityListPage(
                                          token: widget.token,
                                          subgroupId:
                                              sub['id'] as int,
                                          subgroupName: subName,
                                          subgroupCategory: catVal,
                                          teachersList:
                                              widget.teachersList,
                                          isAdmin: true,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                _getCleanName(subName),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Threshold: $threshold pts',
                                                style: TextStyle(
                                                    color: Colors
                                                        .grey.shade600,
                                                    fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.edit_outlined,
                                              color: Colors.blue,
                                              size: 22),
                                          tooltip: 'Edit Subgroup',
                                          onPressed: () =>
                                              _showEditSubgroupDialog(
                                                  sub['id'] as int,
                                                  subName,
                                                  threshold),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 22),
                                          tooltip: 'Delete Subgroup',
                                          onPressed: () {
                                            showDialog<void>(
                                              context: context,
                                              builder: (ctx) =>
                                                  AlertDialog(
                                                title: const Text(
                                                    'Delete Subgroup'),
                                                content: Text(
                                                    'Are you sure you want to delete $subName?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            ctx),
                                                    child: const Text(
                                                        'Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(ctx);
                                                      _deleteSubgroup(
                                                          sub['id']
                                                              as int);
                                                    },
                                                    child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .red)),
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
