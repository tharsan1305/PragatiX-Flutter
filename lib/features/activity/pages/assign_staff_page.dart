import 'package:flutter/material.dart';
import 'package:spdms_app/features/activity/models/activity_model.dart';
import 'package:spdms_app/features/activity/providers/activity_provider.dart';
import 'package:spdms_app/core/theme/app_colors.dart';
import 'package:spdms_app/core/utils/error_handler.dart';

class AssignStaffPage extends StatefulWidget {
  final ActivityProvider provider;
  final ActivityModel activity;

  const AssignStaffPage({
    super.key,
    required this.provider,
    required this.activity,
  });

  @override
  State<AssignStaffPage> createState() => _AssignStaffPageState();
}

class _AssignStaffPageState extends State<AssignStaffPage> {
  static const Color _dark = AppColors.darkSlate;
  bool _isLoading = false;

  bool _globalAssignment = false;
  bool _ccAssignment = false;

  List<dynamic> _assignments = [];

  @override
  void initState() {
    super.initState();
    _globalAssignment = widget.activity.assignmentMode == 'GLOBAL';
    _ccAssignment = widget.activity.assignmentMode == 'CLASS_COORDINATOR';
    _loadAssignments();
    if (widget.provider.departments.isEmpty || widget.provider.allTeachers.isEmpty) {
      widget.provider.loadDependencies();
    }
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.provider.getAssignments(widget.activity.id);
      if (mounted) setState(() => _assignments = list);
    } catch (e) {
      if (mounted) ErrorHandler.showSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfiguration() async {
    setState(() => _isLoading = true);
    try {
      await widget.provider.assignActivity(
        widget.activity.id,
        _ccAssignment,
        _globalAssignment,
      );
      ErrorHandler.showSnackBar(context, 'Assignments saved successfully!');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ErrorHandler.showSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addAssignment(int teacherId, int? departmentId, String? year, int? sectionId) async {
    setState(() => _isLoading = true);
    try {
      await widget.provider.addAssignment(
        widget.activity.id,
        departmentId ?? 1,
        year ?? '1',
        sectionId,
        teacherId,
        sectionId == null ? 'DEPARTMENT' : 'SECTION',
      );
      ErrorHandler.showSnackBar(context, 'Faculty assigned successfully!');
      await _loadAssignments();
    } catch (e) {
      if (mounted) ErrorHandler.showSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeAssignment(int assignmentId) async {
    setState(() => _isLoading = true);
    try {
      await widget.provider.removeAssignment(assignmentId);
      ErrorHandler.showSnackBar(context, 'Assignment removed.');
      await _loadAssignments();
    } catch (e) {
      if (mounted) ErrorHandler.showSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmRemoveAssignment(int assignmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Assignment'),
        content: const Text('Remove this faculty assignment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _removeAssignment(assignmentId);
    }
  }

  Future<void> _unassignAll() async {
    setState(() => _isLoading = true);
    try {
      await widget.provider.clearAllAssignments(widget.activity.id);
      ErrorHandler.showSnackBar(context, 'All faculty assignments removed.');
      await _loadAssignments();
    } catch (e) {
      if (mounted) ErrorHandler.showSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmUnassignAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove All Faculty Assignments?'),
        content: const Text('This will remove every faculty assignment from every department and section for this activity.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _unassignAll();
    }
  }

  void _showAssignBottomSheet(int deptId, int? secId, String deptName, String? secName) {
    // Show ALL active teachers across the entire system. Do not filter by department.
    final availableTeachers = widget.provider.allTeachers;

    String searchQuery = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filteredTeachers = availableTeachers.where((t) {
              final name = (t['fullName'] ?? '').toString().toLowerCase();
              final empId = (t['username'] ?? '').toString().toLowerCase();
              final dept = (t['departmentName'] ?? '').toString().toLowerCase();
              final roles = (t['roles'] as List<dynamic>?)?.join(',').toLowerCase() ?? '';
              final search = searchQuery.toLowerCase();
              return name.contains(search) || empId.contains(search) || dept.contains(search) || roles.contains(search);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Assign Faculty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(ctx),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Department: $deptName', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        if (secName != null)
                          Text('Section: $secName', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search faculty...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredTeachers.isEmpty
                        ? const Center(child: Text('No faculty found.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTeachers.length,
                            itemBuilder: (context, index) {
                              final teacher = filteredTeachers[index];
                              final name = teacher['fullName'] ?? 'Unknown';
                              final empId = teacher['username'] ?? 'N/A';
                              final roles = (teacher['roles'] as List<dynamic>?) ?? [];
                              final isCC = roles.contains('ROLE_CC') || teacher['sectionId'] != null;
                              
                              final isAssignedHere = _assignments.any((a) => a['teacherId'] == teacher['id'] && a['sectionId'] == secId && a['departmentId'] == deptId);

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.adminPrimary.withValues(alpha: 0.1),
                                        child: const Icon(Icons.person, color: AppColors.adminPrimary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            Text('$empId • ${isCC ? 'CC' : 'Teacher'} • ${teacher['departmentName'] ?? 'Unknown Dept'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      if (isAssignedHere)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 12),
                                          child: Text('Assigned', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                                        )
                                      else
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _addAssignment(teacher['id'], deptId, '1', secId);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.adminPrimary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Assign'),
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
            );
          }
        );
      },
    );
  }

  Widget _buildActivitySummary() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.activity.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _Tag('Type: ${widget.activity.type}', Colors.purple),
                _Tag('Category: ${widget.activity.xpCategory}', Colors.blue),
                if (widget.activity.awardEnabled) _Tag('Award XP: ${widget.activity.awardXp}', Colors.green),
                if (widget.activity.penaltyEnabled) _Tag('Penalty XP: ${widget.activity.penaltyXp}', Colors.red),
                _Tag('${_assignments.length} Total Assignments', AppColors.adminPrimary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationToggles() {
    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GLOBAL ASSIGNMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Enable to assign this activity to ALL departments, ALL sections and ALL faculty members.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                Switch(
                  value: _globalAssignment,
                  activeColor: Colors.purple,
                  onChanged: (val) {
                    setState(() {
                      _globalAssignment = val;
                      if (val) _ccAssignment = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CLASS COORDINATOR ASSIGNMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Automatically assign this activity to the Class Coordinator of every section.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                Switch(
                  value: _ccAssignment,
                  activeColor: Colors.purple,
                  onChanged: (val) {
                    setState(() {
                      _ccAssignment = val;
                      if (val) _globalAssignment = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentWidget(bool isAssigned, List<dynamic> allAssignments, int deptId, int? secId, String deptName, String? secName) {
    final validAssignments = allAssignments.where((a) => a['teacherId'] != null).toList();
    
    return InkWell(
      onTap: () => _showAssignBottomSheet(deptId, secId, deptName, secName),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: validAssignments.isEmpty ? Colors.red.shade50 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: validAssignments.isEmpty ? Colors.red.shade300 : Colors.green.shade300,
            width: 1,
          ),
        ),
        child: validAssignments.isEmpty
            ? const Row(
                children: [
                  Icon(Icons.close, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('❌ No Faculty Assigned\nTap to Assign', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: validAssignments.map((a) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${a['teacherName'] ?? 'Unknown'}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('Role • ${a['teacherUsername'] ?? 'N/A'} • $deptName', style: const TextStyle(color: Colors.green, fontSize: 12)),
                              const Text('Tap to Change', style: TextStyle(color: Colors.green, fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                          onPressed: () => _confirmRemoveAssignment(a['id']),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildDepartmentList() {
    final depts = widget.provider.departments;
    if (depts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Text('No departments available.', style: TextStyle(color: Colors.grey))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: depts.length,
      itemBuilder: (context, index) {
        final dept = depts[index];
        final deptId = dept['id'] as int;
        final deptName = dept['name'] ?? 'Unknown Dept';
        final hasSections = dept['hasSections'] == true;
        final sections = (dept['sections'] as List<dynamic>?) ?? [];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blueGrey.shade100)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏢 $deptName', style: const TextStyle(fontWeight: FontWeight.bold, color: _dark, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Configure Assignments', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                if (hasSections)
                  ...sections.map((sec) {
                    final secId = sec['id'] as int;
                    final secName = sec['sectionName'] ?? 'Section';
                    final secAssignments = _assignments.where((a) => a['sectionId'] == secId && a['departmentId'] == deptId).toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(secName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                          const SizedBox(height: 8),
                          _buildAssignmentWidget(secAssignments.isNotEmpty, secAssignments, deptId, secId, deptName, secName),
                        ],
                      ),
                    );
                  })
                else
                  Builder(
                    builder: (context) {
                      final deptAssignments = _assignments.where((a) => a['sectionId'] == null && a['departmentId'] == deptId).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Department Faculty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                          const SizedBox(height: 8),
                          _buildAssignmentWidget(deptAssignments.isNotEmpty, deptAssignments, deptId, null, deptName, null),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Assign Faculty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _dark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AnimatedBuilder(
        animation: widget.provider,
        builder: (context, child) {
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildActivitySummary(),
                          const SizedBox(height: 24),
                          _buildConfigurationToggles(),
                          const SizedBox(height: 32),
                          const Text('CLASS COORDINATOR ASSIGNMENTS (Auto-Resolved)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.blue, letterSpacing: 0.5)),
                          const SizedBox(height: 16),
                          _buildDepartmentList(),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: Colors.grey),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading || _assignments.isEmpty ? null : _confirmUnassignAll,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: _assignments.isEmpty ? Colors.grey.shade300 : Colors.red),
                            ),
                            child: Text('Unassign All', style: TextStyle(color: _assignments.isEmpty ? Colors.grey : Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveConfiguration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.adminPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Save Assignments', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isLoading || widget.provider.isLoadingDependencies || widget.provider.isSaving)
                Container(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
