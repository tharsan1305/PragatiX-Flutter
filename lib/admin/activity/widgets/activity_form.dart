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

  /// Pass existing activity to pre-fill form (edit mode). null = create mode.
  final ActivityModel? initialData;

  const ActivityForm({
    super.key,
    required this.departments,
    required this.allTeachers,
    this.initialData,
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

  // ── Selection state ───────────────────────────────────────────────────────
  String? _selectedFrequency;
  dynamic _selectedDept;
  dynamic _selectedTeacher;
  Set<String> _selectedEvidence = {};
  String? _selectedXp;
  String? _selectedCap;
  String _selectedType = 'Individual';

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
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<dynamic> get _filteredTeachers {
    if (_selectedDept == null) return [];
    final deptId = _selectedDept['id'];
    final deptName =
        (_selectedDept['name'] as String).toLowerCase();
    return widget.allTeachers.where((t) {
      final tid = t['departmentId'];
      final tname = (t['departmentName'] as String? ?? '').toLowerCase();
      return tid == deptId || tname == deptName;
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
    final teacherOk = _selectedTeacher != null;

    if (!formOk || !freqOk || !evidOk || !xpOk || !capOk || !deptOk || !teacherOk) {
      return null;
    }

    return {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'frequency': _selectedFrequency,
      'ownerDepartment': _selectedDept?['name']?.toString() ?? '',
      'departmentId': _selectedDept?['id']?.toString() ?? '',
      'teacherId': _selectedTeacher?['id']?.toString() ?? '',
      'ownerSubrole': _selectedTeacher?['username']?.toString() ?? '',
      'evidence': _selectedEvidence.toList(),
      'xp': _selectedXp,
      'cap': _selectedCap,
      'type': _selectedType,
      'justification': _justCtrl.text.trim(),
    };
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          ActivitySection(
            number: '1',
            title: 'Activity Details',
            child: _buildDetailsSection(),
          ),
          const SizedBox(height: 16),
          ActivitySection(
            number: '2',
            title: 'Frequency',
            child: FrequencySelector(
              selected: _selectedFrequency,
              onChanged: (v) => setState(() => _selectedFrequency = v),
              showError: _submitted,
            ),
          ),
          const SizedBox(height: 16),
          ActivitySection(
            number: '3',
            title: 'Owner',
            child: OwnerSelector(
              departments: widget.departments,
              allTeachers: widget.allTeachers,
              selectedDept: _selectedDept,
              selectedTeacher: _selectedTeacher,
              onDeptChanged: (val) {
                setState(() {
                  _selectedDept = val;
                  _selectedTeacher = null;
                });
              },
              onTeacherChanged: (val) =>
                  setState(() => _selectedTeacher = val),
              showError: _submitted,
            ),
          ),
          const SizedBox(height: 16),
          ActivitySection(
            number: '4',
            title: 'Evidence',
            child: EvidenceSelector(
              selected: _selectedEvidence,
              onChanged: (next) => setState(() => _selectedEvidence = next),
              showError: _submitted,
            ),
          ),
          const SizedBox(height: 16),
          ActivitySection(
            number: '5',
            title: 'XP Configuration',
            child: XpSelector(
              selected: _selectedXp,
              onChanged: (v) => setState(() => _selectedXp = v),
              showError: _submitted,
            ),
          ),
          const SizedBox(height: 16),
          ActivitySection(
            number: '6',
            title: 'Weekly Cap',
            child: CapSelector(
              selected: _selectedCap,
              onChanged: (v) => setState(() => _selectedCap = v),
              showError: _submitted,
            ),
          ),
          const SizedBox(height: 16),
          ActivitySection(
            number: '7',
            title: 'Activity Type',
            child: TypeSelector(
              selected: _selectedType,
              onChanged: (v) => setState(() => _selectedType = v),
            ),
          ),
          const SizedBox(height: 16),
          ActivitySection(
            number: '8',
            title: 'Justification',
            child: _buildJustificationSection(),
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
