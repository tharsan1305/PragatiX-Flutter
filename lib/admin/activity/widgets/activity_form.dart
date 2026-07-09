import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../utils/validators.dart';
import 'activity_section.dart';
import 'frequency_selector.dart';
import 'evidence_selector.dart';
import 'xp_selector.dart';
import 'cap_selector.dart';
import 'type_selector.dart';
import 'owner_selector.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared activity form used by both CreateActivityPage and EditActivityPage.
// Parent pages access buildBody() via GlobalKey<ActivityFormState>.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityForm extends StatefulWidget {
  final List<dynamic> departments;
  final List<dynamic> allTeachers;
  final List<dynamic> sections;

  /// Pass existing activity to pre-fill form (edit mode). null = create mode.
  final ActivityModel? initialData;
  final bool isCc;

  const ActivityForm({
    super.key,
    required this.departments,
    required this.allTeachers,
    required this.sections,
    this.initialData,
    this.isCc = false,
  });

  @override
  ActivityFormState createState() => ActivityFormState();
}

// Public state class so parent pages can call buildBody() via GlobalKey.
class ActivityFormState extends State<ActivityForm> {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);
  static const Color _surface = Color(0xFFF8FAFC);

  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _justCtrl = TextEditingController();
  final _teacherSearchCtrl = TextEditingController();

  // ── Selection state ───────────────────────────────────────────────────────
  String? _selectedFrequency;
  dynamic _selectedDept;
  dynamic _selectedTeacher;
  dynamic _selectedSection;
  Set<String> _selectedEvidence = {};
  String? _selectedXp;
  String? _selectedCap;
  String _selectedType = 'Individual';
  String _teacherSearchQuery = '';

  bool _submitted = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    if (d != null) {
      _nameCtrl.text = d.name;
      _descCtrl.text = d.description;
      _justCtrl.text = d.justification;
      _selectedFrequency = d.frequency.isNotEmpty ? d.frequency : null;
      _selectedXp = d.xp.isNotEmpty ? d.xp : null;
      _selectedCap = d.cap.isNotEmpty ? d.cap : null;
      _selectedType = d.type.isNotEmpty ? d.type : 'Individual';
      _selectedEvidence = Set<String>.from(d.evidence);

      // Match department object
      if (d.ownerDepartment.isNotEmpty || d.departmentId.isNotEmpty) {
        try {
          _selectedDept = widget.departments.firstWhere(
            (dep) =>
                dep['name'].toString() == d.ownerDepartment ||
                dep['id'].toString() == d.departmentId,
          );
        } catch (_) {}
      }

      // Match teacher object
      if (_selectedDept != null && d.teacherId.isNotEmpty) {
        final filtered = _filteredTeachers;
        try {
          _selectedTeacher = filtered.firstWhere(
            (t) => t['id'].toString() == d.teacherId,
          );
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _justCtrl.dispose();
    _teacherSearchCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<dynamic> get _searchedTeachers {
    final filtered = _filteredTeachers;
    if (_teacherSearchQuery.trim().isEmpty) {
      return filtered;
    }
    final query = _teacherSearchQuery.toLowerCase();
    return filtered.where((t) {
      final name = (t['fullName'] as String? ?? '').toLowerCase();
      final username = (t['username'] as String? ?? '').toLowerCase();
      final dept = (t['departmentName'] as String? ?? '').toLowerCase();
      return name.contains(query) || username.contains(query) || dept.contains(query);
    }).toList();
  }
  List<dynamic> get _filteredTeachers {
    if (_selectedDept == null) return [];
    final deptId = _selectedDept['id'];
    if (deptId == 'all') {
      return widget.allTeachers;
    }
    final deptName = (_selectedDept['name'] as String).toLowerCase();
    return widget.allTeachers.where((t) {
      final tid = t['departmentId'];
      final tname = (t['departmentName'] as String? ?? '').toLowerCase();
      return (tid != null && deptId != null && tid.toString() == deptId.toString()) || tname == deptName;
    }).toList();
  }

  List<dynamic> get _filteredSections {
    if (_selectedDept == null) return [];
    final deptId = _selectedDept['id'];
    final deptName = (_selectedDept['name'] as String).toLowerCase();
    return widget.sections.where((sec) {
      final dep = sec['department'];
      if (dep == null) return false;
      return dep['id'] == deptId || (dep['name'] as String).toLowerCase() == deptName;
    }).toList();
  }

  List<Widget> _buildAdminAssignmentSummaryRows() {
    final summary = widget.initialData?.assignmentSummary ?? [];
    if (summary.isEmpty) {
      return [
        const Text(
          'No assignments defined for this department.',
          style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
        )
      ];
    }

    return summary.map((assign) {
      final secName = assign['section'] as String?;
      final teachName = assign['teacherName'] as String? ?? 'Not Assigned';
      final isAssigned = teachName.toLowerCase() != 'not assigned';

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            if (secName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  secName,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            CircleAvatar(
              radius: 12,
              backgroundColor: isAssigned ? Colors.blue.shade50 : Colors.grey.shade100,
              child: Icon(
                Icons.person_rounded,
                size: 14,
                color: isAssigned ? Colors.blue : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                teachName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isAssigned ? _dark : Colors.grey.shade500,
                ),
              ),
            ),
            if (!isAssigned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text(
                  'Not Assigned',
                  style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  InputDecoration _deco(String label, IconData icon,
      {bool alignHint = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary, size: 20),
      alignLabelWithHint: alignHint,
      filled: true,
      fillColor: _surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Validates the form and returns the assembled body, or null if invalid.
  Map<String, dynamic>? buildBody() {
    setState(() => _submitted = true);
    final formOk = _formKey.currentState?.validate() ?? false;
    final freqOk = _selectedFrequency != null;
    final evidOk = _selectedEvidence.isNotEmpty;
    final xpOk = _selectedXp != null;
    final capOk = _selectedCap != null;
    final deptOk = _selectedDept != null;

    if (!formOk || !freqOk || !evidOk || !xpOk || !capOk || !deptOk) {
      return null;
    }

    return {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'frequency': _selectedFrequency,
      'ownerDepartment': _selectedDept?['name']?.toString() ?? '',
      'departmentId': _selectedDept?['id']?.toString() ?? '',
      'teacherId': '',
      'ownerSubrole': '',
      'evidence': _selectedEvidence.toList(),
      'xp': _selectedXp,
      'cap': _selectedCap,
      'type': _selectedType,
      'justification': _justCtrl.text.trim(),
    };
  }

  Map<String, dynamic>? buildCcAssignmentBody() {
    setState(() => _submitted = true);
    final hasSections = _filteredSections.isNotEmpty;
    if (_selectedTeacher == null || (hasSections && _selectedSection == null)) {
      return null;
    }
    return {
      'sectionId': _selectedSection?['id'],
      'teacherId': _selectedTeacher['id'],
    };
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    int stepNum = 1;
    final filteredSecs = _filteredSections;
    final hasSections = filteredSecs.isNotEmpty;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          AbsorbPointer(
            absorbing: widget.isCc,
            child: Opacity(
              opacity: widget.isCc ? 0.75 : 1.0,
              child: Column(
                children: [
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'Activity Details',
                    child: _buildDetailsSection(),
                  ),
                  const SizedBox(height: 16),
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'Frequency',
                    child: FrequencySelector(
                      selected: _selectedFrequency,
                      onChanged: (v) => setState(() => _selectedFrequency = v),
                      showError: _submitted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!widget.isCc)
            ActivitySection(
              number: (stepNum++).toString(),
              title: widget.initialData == null ? 'Department' : 'Department Assignment Summary',
              child: widget.initialData == null
                  ? OwnerSelector(
                      departments: widget.departments,
                      allTeachers: widget.allTeachers,
                      selectedDept: _selectedDept,
                      selectedTeacher: _selectedTeacher,
                      showTeacher: false,
                      onDeptChanged: (val) {
                        setState(() {
                          _selectedDept = val;
                          _selectedTeacher = null;
                        });
                      },
                      onTeacherChanged: (val) =>
                          setState(() => _selectedTeacher = val),
                      showError: _submitted,
                    )
                  : Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.apartment_rounded, color: _primary, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDept?['name']?.toString() ?? 'Unassigned',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _dark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            ..._buildAdminAssignmentSummaryRows(),
                          ],
                        ),
                      ),
                    ),
            )
          else
            ActivitySection(
              number: (stepNum++).toString(),
              title: 'Assign Teacher',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.initialData != null && widget.initialData!.assignmentSummary.isNotEmpty) ...[
                    const Text(
                      'Current Assignments:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _dark),
                    ),
                    const SizedBox(height: 6),
                    ...widget.initialData!.assignmentSummary.map((assign) {
                      final secName = assign['section'] as String?;
                      final teachName = assign['teacher'] as String?;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          secName != null ? 'Section $secName → $teachName' : 'Assigned to → $teachName',
                          style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                  ],
                  const Text(
                    'New Assignment:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _dark),
                  ),
                  const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final ccDeps = [
                        {'id': 'all', 'name': 'Individual Staff'},
                        ...widget.departments,
                      ];
                      return InputDecorator(
                        decoration: _deco('Department', Icons.apartment_rounded).copyWith(
                          errorText: (_submitted && _selectedDept == null) ? 'Department is required' : null,
                        ),
                        child: DropdownButton<dynamic>(
                          value: _selectedDept != null
                              ? ccDeps.firstWhere(
                                  (d) => d['id'] == _selectedDept['id'] || d['name'] == _selectedDept['name'],
                                  orElse: () => null,
                                )
                              : null,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.expand_more_rounded, color: _primary),
                          hint: const Text('Select department', style: TextStyle(fontSize: 14)),
                          items: ccDeps.map((d) {
                            return DropdownMenuItem<dynamic>(
                              value: d,
                              child: Text(d['name'].toString(), style: const TextStyle(fontSize: 14, color: _dark)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedDept = val;
                              _selectedTeacher = null;
                              _selectedSection = null;
                            });
                          },
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 16),
                  if (hasSections) ...[
                    InputDecorator(
                      decoration: _deco('Section', Icons.class_outlined).copyWith(
                        errorText: (_submitted && _selectedSection == null) ? 'Section is required' : null,
                      ),
                      child: DropdownButton<dynamic>(
                        value: _selectedSection != null
                            ? filteredSecs.firstWhere(
                                (s) => s['id'] == _selectedSection['id'],
                                orElse: () => null,
                              )
                            : null,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.expand_more_rounded, color: _primary),
                        hint: const Text('Select section', style: TextStyle(fontSize: 14)),
                        items: filteredSecs.map((s) {
                          return DropdownMenuItem<dynamic>(
                            value: s,
                            child: Text(s['sectionName'].toString(), style: const TextStyle(fontSize: 14, color: _dark)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSection = val),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedTeacher != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.person_rounded, size: 16, color: Colors.blue),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedTeacher['fullName']?.toString() ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _dark),
                                    ),
                                    Text(
                                      '${_selectedTeacher['username'] ?? ''} • ${_selectedTeacher['departmentName'] ?? ''}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                                onPressed: () => setState(() => _selectedTeacher = null),
                                tooltip: 'Clear selection',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ],
                      TextFormField(
                        controller: _teacherSearchCtrl,
                        style: const TextStyle(color: _dark, fontSize: 14),
                        decoration: _deco('Search Teacher by Name/Dept', Icons.search_rounded).copyWith(
                          suffixIcon: _teacherSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _teacherSearchCtrl.clear();
                                    setState(() => _teacherSearchQuery = '');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setState(() => _teacherSearchQuery = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 320,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Builder(
                            builder: (context) {
                              final list = _searchedTeachers;
                              if (list.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No teachers found',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _dark),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Try another keyword.',
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: list.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                  final t = list[idx];
                                  final isSelected = _selectedTeacher != null && _selectedTeacher['id'] == t['id'];
                                  final deptName = t['departmentName'] ?? 'No Department';
                                  final uName = t['username'] ?? '';
                                  final fullName = t['fullName'] ?? '';

                                  return Card(
                                    margin: EdgeInsets.zero,
                                    elevation: isSelected ? 2 : 1,
                                    shadowColor: Colors.black.withOpacity(0.08),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isSelected ? Colors.blue : Colors.grey.shade200,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () {
                                        setState(() {
                                          _selectedTeacher = t;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: _primary.withOpacity(0.1),
                                              child: const Icon(
                                                Icons.person_rounded,
                                                size: 26,
                                                color: _primary,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    fullName,
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.w600,
                                                      color: _dark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '$uName • $deptName',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            if (isSelected)
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.green,
                                                size: 24,
                                              )
                                            else
                                              Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Colors.grey.shade400,
                                                size: 16,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          ),
                        ),
                      ),
                      if (_submitted && _selectedTeacher == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12),
                          child: Text(
                            'Teacher is required',
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          AbsorbPointer(
            absorbing: widget.isCc,
            child: Opacity(
              opacity: widget.isCc ? 0.75 : 1.0,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'Evidence',
                    child: EvidenceSelector(
                      selected: _selectedEvidence,
                      onChanged: (next) => setState(() => _selectedEvidence = next),
                      showError: _submitted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'XP Configuration',
                    child: XpSelector(
                      selected: _selectedXp,
                      onChanged: (v) => setState(() => _selectedXp = v),
                      showError: _submitted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'Weekly Cap',
                    child: CapSelector(
                      selected: _selectedCap,
                      onChanged: (v) => setState(() => _selectedCap = v),
                      showError: _submitted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'Activity Type',
                    child: TypeSelector(
                      selected: _selectedType,
                      onChanged: (v) => setState(() => _selectedType = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'Justification',
                    child: _buildJustificationSection(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration: _deco('Activity Name', Icons.title_rounded),
          validator: ActivityValidators.validateName,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration: _deco('Description', Icons.notes_rounded,
              alignHint: true),
          validator: ActivityValidators.validateDescription,
        ),
      ],
    );
  }

  Widget _buildJustificationSection() {
    return TextFormField(
      controller: _justCtrl,
      maxLines: 5,
      style: const TextStyle(color: _dark, fontSize: 15),
      decoration: _deco(
        'Enter manual justification here…',
        Icons.edit_note_rounded,
        alignHint: true,
      ),
      validator: ActivityValidators.validateJustification,
    );
  }
}
