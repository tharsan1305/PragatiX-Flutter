import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'create_activity_page.dart';

// ====================================================================
// subgroup_activities_page.dart
// Stripped of all old dialog / form / save logic.
// Activity creation & editing delegated entirely to CreateActivityPage.
// ====================================================================

class SubgroupActivitiesPage extends StatefulWidget {
  final String token;
  final int subgroupId;
  final String subgroupName;
  final String subgroupCategory;
  final List<dynamic> teachersList;

  const SubgroupActivitiesPage({
    super.key,
    required this.token,
    required this.subgroupId,
    required this.subgroupName,
    required this.subgroupCategory,
    required this.teachersList,
  });

  @override
  State<SubgroupActivitiesPage> createState() => _SubgroupActivitiesPageState();
}

class _SubgroupActivitiesPageState extends State<SubgroupActivitiesPage> {
  // ─── State ──────────────────────────────────────────────────
  List<dynamic> _activities = [];
  List<dynamic> _departments = [];
  bool _isLoading = true;
  bool _isDeptsLoading = true;

  // ─── Helpers ────────────────────────────────────────────────
  String _getCleanSubgroupName(String fullName) {
    final lower = fullName.toLowerCase();
    if (lower.endsWith(' (must)'))       return fullName.substring(0, fullName.length - 7);
    if (lower.endsWith(' (individual)')) return fullName.substring(0, fullName.length - 13);
    if (lower.endsWith(' (group)'))      return fullName.substring(0, fullName.length - 8);
    return fullName;
  }

  String get _categoryType {
    final cat = widget.subgroupCategory.toLowerCase();
    if (cat == 'must' || cat == 'group' || cat == 'individual') return cat;
    final name = widget.subgroupName.toLowerCase();
    if (name.contains('must'))  return 'must';
    if (name.contains('group')) return 'group';
    return 'individual';
  }

  // ─── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchActivities();
    _fetchDepartments();
  }

  // ─── API calls ──────────────────────────────────────────────
  Future<void> _fetchDepartments() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/v1/admin/departments'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _departments = data['data'] ?? [];
            _isDeptsLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() {
      _departments = [
        {'id': 1, 'name': 'Computer Science and Engineering', 'code': 'CSE'},
        {'id': 2, 'name': 'Information Technology',          'code': 'IT'},
      ];
      _isDeptsLoading = false;
    });
  }

  Future<void> _fetchActivities() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:8080/api/v1/admin/subgroups/${widget.subgroupId}/activities'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _activities = data['data'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _deleteActivity(int actId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8080/api/v1/admin/activities/$actId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Activity deleted successfully'),
              backgroundColor: Colors.green),
        );
        setState(() => _isLoading = true);
        _fetchActivities();
      }
    } catch (_) {
      setState(() {
        _activities.removeWhere((a) => a['id'] == actId);
      });
    }
  }

  // ─── Navigation helpers ─────────────────────────────────────
  void _openCreate() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateActivityPage(
          token: widget.token,
          subgroupId: widget.subgroupId,
          departments: _departments,
          teachersList: widget.teachersList,
        ),
      ),
    ).then((saved) {
      if (saved == true) {
        setState(() => _isLoading = true);
        _fetchActivities();
      }
    });
  }

  void _openEdit(Map<String, dynamic> activity) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateActivityPage(
          token: widget.token,
          subgroupId: widget.subgroupId,
          departments: _departments,
          teachersList: widget.teachersList,
          activityData: activity,
        ),
      ),
    ).then((saved) {
      if (saved == true) {
        setState(() => _isLoading = true);
        _fetchActivities();
      }
    });
  }

  void _confirmDelete(Map<String, dynamic> act) {
    final actName = act['name'] ?? '';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Activity',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '$actName'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteActivity(act['id']);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cleanTitle = _getCleanSubgroupName(widget.subgroupName);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$cleanTitle Activities',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: (_isLoading || _isDeptsLoading)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Subgroup header card ──
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
                                Text(
                                  cleanTitle,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Configured type: ${_categoryType.toUpperCase()}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _openCreate,
                            icon: const Icon(Icons.add,
                                color: Colors.white, size: 18),
                            label: const Text('Activity',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA4335),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Configured Activities (${_activities.length})',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 10),

                  // ── Activities list ──
                  Expanded(
                    child: _activities.isEmpty
                        ? Center(
                            child: Text(
                              'No activities created under this sub-branch yet.',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _activities.length,
                            itemBuilder: (context, index) {
                              final act =
                                  Map<String, dynamic>.from(_activities[index]);
                              return _buildActivityCard(act);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> act) {
    final actName = act['name'] ?? '';
    final xpVal   = act['xp']        ?? '0';
    final capVal  = act['cap']        ?? 'No cap';
    final freqVal = act['frequency']  ?? 'Once';
    final deptVal = act['ownerDepartment'] ?? 'All';
    final roleVal = act['ownerSubrole']    ?? 'All Teachers';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    actName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B)),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.blue, size: 20),
                      onPressed: () => _openEdit(act),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: () => _confirmDelete(act),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),

            if ((act['description'] ?? '').toString().isNotEmpty) ...[
              Text(
                act['description'],
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 8),
            ],

            const Divider(),
            const SizedBox(height: 4),

            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildTag('XP: $xpVal',       Colors.green),
                _buildTag('Cap: $capVal',      Colors.teal),
                _buildTag('Freq: $freqVal',    Colors.amber.shade800),
                _buildTag('Type: ${act['type'] ?? 'Individual'}',
                    Colors.purple),
              ],
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.assignment_ind_outlined,
                    size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Owner: $deptVal ($roleVal)',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            if ((act['justification'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Justification: ${act['justification']}',
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
