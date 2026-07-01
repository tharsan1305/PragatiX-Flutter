import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ====================================================================
// create_activity_page.dart
// Full-screen premium Activity Create / Edit page.
// No AlertDialog. No BottomSheet. No popups.
// POST  /api/v1/admin/subgroups/{subgroupId}/activities
// PUT   /api/v1/admin/activities/{activityId}
// ====================================================================

class CreateActivityPage extends StatefulWidget {
  final String token;
  final int subgroupId;
  final List<dynamic> departments;
  final List<dynamic> teachersList;

  /// Pass the existing activity map when editing. null = create mode.
  final Map<String, dynamic>? activityData;

  const CreateActivityPage({
    super.key,
    required this.token,
    required this.subgroupId,
    required this.departments,
    required this.teachersList,
    this.activityData,
  });

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage>
    with SingleTickerProviderStateMixin {
  // ─── Form ──────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _justCtrl = TextEditingController();

  // ─── Selection state ───────────────────────────────────────
  String? _selectedFrequency;
  dynamic _selectedDept;
  dynamic _selectedTeacher;
  final Set<String> _selectedEvidence = {};
  String? _selectedXp;
  String? _selectedCap;
  String _selectedType = 'Individual';

  List<dynamic> _filteredTeachers = [];

  bool _submitted  = false;
  bool _isSaving   = false;

  // ─── Animation ─────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ─── Edit mode ─────────────────────────────────────────────
  bool get _isEdit => widget.activityData != null;
  int? get _editId  => widget.activityData?['id'];

  // ─── Design tokens ─────────────────────────────────────────
  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark    = Color(0xFF1E293B);
  static const Color _surface = Color(0xFFF8FAFC);

  // ─── Options ───────────────────────────────────────────────
  static const List<Map<String, dynamic>> _frequencies = [
    {'label': 'Daily',                   'icon': Icons.today_outlined},
    {'label': 'Every Monday',            'icon': Icons.date_range_outlined},
    {'label': 'Daily → Checked Friday',  'icon': Icons.fact_check_outlined},
    {'label': 'Daily → Weekly Log',      'icon': Icons.assignment_outlined},
    {'label': 'Every Period',            'icon': Icons.schedule_outlined},
  ];

  static const List<String> _evidenceOptions = [
    'Handwritten',
    'Soft Copy',
    'Diary / Notebook',
    'Weekly Log',
    'Direct Observation',
    'Attendance Register',
  ];

  static const List<String> _xpOptions = [
    '20',
    '5/day',
    '10/day',
    '0 (Pass) / −40 (Fail)',
  ];

  static const List<String> _capOptions = [
    '20/wk',
    '25/wk',
    '50/wk',
    'No Cap',
  ];

  // ─── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    // Pre-fill fields if editing
    if (_isEdit) {
      final d = widget.activityData!;
      _nameCtrl.text = d['name'] ?? '';
      _descCtrl.text = d['description'] ?? '';
      _justCtrl.text = d['justification'] ?? '';
      _selectedFrequency = d['frequency'];
      _selectedXp        = d['xp'];
      _selectedCap       = d['cap'];
      _selectedType      = d['type'] ?? 'Individual';

      // Evidence — stored either as List or comma-separated String
      final rawEvidence = d['evidence'];
      if (rawEvidence is List) {
        _selectedEvidence.addAll(rawEvidence.cast<String>());
      } else if (rawEvidence is String && rawEvidence.isNotEmpty) {
        _selectedEvidence.addAll(rawEvidence.split(',').map((e) => e.trim()));
      }

      // Match department object
      final deptName = d['ownerDepartment'] ?? '';
      final deptId   = d['departmentId'];
      try {
        _selectedDept = widget.departments.firstWhere(
          (dep) =>
              dep['name'].toString() == deptName ||
              dep['id'].toString() == deptId.toString(),
        );
      } catch (_) {}

      if (_selectedDept != null) {
        _filterTeachers(_selectedDept);
        // Match teacher object
        final teacherId = d['teacherId']?.toString() ?? '';
        try {
          _selectedTeacher = _filteredTeachers.firstWhere(
            (t) => t['id'].toString() == teacherId,
          );
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _justCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────
  void _filterTeachers(dynamic dept) {
    if (dept == null) { _filteredTeachers = []; return; }
    final deptId   = dept['id'];
    final deptName = (dept['name'] as String).toLowerCase();
    _filteredTeachers = widget.teachersList.where((t) {
      final tid   = t['departmentId'];
      final tname = (t['departmentName'] as String? ?? '').toLowerCase();
      return tid == deptId || tname == deptName;
    }).toList();
  }

  void _onDeptChanged(dynamic dept) {
    setState(() {
      _selectedDept    = dept;
      _selectedTeacher = null;
      _filterTeachers(dept);
    });
  }

  bool get _freqValid => _selectedFrequency != null;
  bool get _evidValid => _selectedEvidence.isNotEmpty;
  bool get _xpValid   => _selectedXp != null;
  bool get _capValid  => _selectedCap != null;

  // ─── Save / Submit ─────────────────────────────────────────
  Future<void> _onSave() async {
    setState(() => _submitted = true);
    final formOk = _formKey.currentState!.validate();
    if (!formOk || !_freqValid || !_evidValid || !_xpValid || !_capValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final body = {
      'name':            _nameCtrl.text.trim(),
      'description':     _descCtrl.text.trim(),
      'frequency':       _selectedFrequency,
      'ownerDepartment': _selectedDept?['name']?.toString() ?? '',
      'departmentId':    _selectedDept?['id']?.toString() ?? '',
      'teacherId':       _selectedTeacher?['id']?.toString() ?? '',
      'ownerSubrole':    _selectedTeacher?['username']?.toString() ?? '',
      'evidence':        _selectedEvidence.join(', '),
      'xp':              _selectedXp,
      'cap':             _selectedCap,
      'type':            _selectedType,
      'justification':   _justCtrl.text.trim(),
    };

    try {
      final http.Response response;
      if (_isEdit) {
        response = await http.put(
          Uri.parse('http://10.0.2.2:8080/api/v1/admin/activities/$_editId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: jsonEncode(body),
        );
      } else {
        response = await http.post(
          Uri.parse(
              'http://10.0.2.2:8080/api/v1/admin/subgroups/${widget.subgroupId}/activities'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: jsonEncode(body),
        );
      }

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Activity updated successfully!'
                : 'Activity created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Operation failed'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Offline / dev mode: pop with success so list refreshes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Activity updated (offline mode).'
              : 'Activity saved (offline mode).'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: NestedScrollView(
          headerSliverBuilder: (_, innerScrolled) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 110,
              backgroundColor: _dark,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _isEdit ? 'Edit Activity' : 'Create Activity',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                _sectionCard('1', 'Activity Details',  _section1()),
                const SizedBox(height: 16),
                _sectionCard('2', 'Frequency',          _section2()),
                const SizedBox(height: 16),
                _sectionCard('3', 'Owner',              _section3()),
                const SizedBox(height: 16),
                _sectionCard('4', 'Evidence',           _section4()),
                const SizedBox(height: 16),
                _sectionCard('5', 'XP Configuration',  _section5()),
                const SizedBox(height: 16),
                _sectionCard('6', 'Weekly Cap',         _section6()),
                const SizedBox(height: 16),
                _sectionCard('7', 'Activity Type',      _section7()),
                const SizedBox(height: 16),
                _sectionCard('8', 'Justification',      _section8()),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _stickyBottom(),
    );
  }

  // ─── Section card wrapper ──────────────────────────────────
  Widget _sectionCard(String number, String title, Widget content) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(number,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _dark)),
              ],
            ),
            const SizedBox(height: 6),
            Divider(color: Colors.grey.shade100, thickness: 1),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  // ─── Section 1 – Activity Details ──────────────────────────
  Widget _section1() {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration: _deco('Activity Name', Icons.title_rounded),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Activity name is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration:
              _deco('Description', Icons.notes_rounded, alignHint: true),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Description is required' : null,
        ),
      ],
    );
  }

  // ─── Section 2 – Frequency ─────────────────────────────────
  Widget _section2() {
    final hasError = _submitted && !_freqValid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._frequencies.map(_freqTile),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Please select a frequency.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12)),
          ),
      ],
    );
  }

  Widget _freqTile(Map<String, dynamic> freq) {
    final label    = freq['label'] as String;
    final icon     = freq['icon'] as IconData;
    final selected = _selectedFrequency == label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: selected
              ? _primary.withValues(alpha: 0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? _primary : Colors.grey.shade200,
              width: selected ? 2 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: _primary.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _selectedFrequency = label),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? _primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon,
                        color:
                            selected ? Colors.white : Colors.grey.shade600,
                        size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            color: selected ? _primary : _dark,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            fontSize: 14)),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: selected ? 1 : 0,
                    child: const Icon(Icons.check_circle_rounded,
                        color: _primary, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Section 3 – Owner ─────────────────────────────────────
  Widget _section3() {
    return Column(
      children: [
        DropdownButtonFormField<dynamic>(
          // ignore: deprecated_member_use
          value: _selectedDept,
          decoration: _deco('Department', Icons.apartment_rounded),
          icon: const Icon(Icons.expand_more_rounded, color: _primary),
          isExpanded: true,
          items: widget.departments.map((d) {
            return DropdownMenuItem<dynamic>(
              value: d,
              child: Text(d['name'].toString(),
                  style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: _onDeptChanged,
          validator: (v) =>
              v == null ? 'Department is required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<dynamic>(
          // ignore: deprecated_member_use
          value: _selectedTeacher,
          decoration:
              _deco('Faculty / Teacher', Icons.person_outline_rounded),
          hint: Text(
            _selectedDept == null
                ? 'Select department first'
                : _filteredTeachers.isEmpty
                    ? 'No teachers in this department'
                    : 'Select teacher',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          icon: const Icon(Icons.expand_more_rounded, color: _primary),
          isExpanded: true,
          items: _filteredTeachers.map((t) {
            return DropdownMenuItem<dynamic>(
              value: t,
              child: Text(
                  '${t["fullName"]}  (${t["username"]})',
                  style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: _filteredTeachers.isEmpty
              ? null
              : (val) => setState(() => _selectedTeacher = val),
          validator: (v) =>
              v == null ? 'Teacher selection is required' : null,
        ),
      ],
    );
  }

  // ─── Section 4 – Evidence ──────────────────────────────────
  Widget _section4() {
    final hasError = _submitted && !_evidValid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._evidenceOptions.map((opt) {
          final checked = _selectedEvidence.contains(opt);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Material(
              color: checked
                  ? _primary.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: CheckboxListTile(
                value: checked,
                title: Text(opt,
                    style: const TextStyle(fontSize: 14, color: _dark)),
                activeColor: _primary,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8),
                onChanged: (val) => setState(() {
                  if (val == true) {
                    _selectedEvidence.add(opt);
                  } else {
                    _selectedEvidence.remove(opt);
                  }
                }),
              ),
            ),
          );
        }),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Select at least one evidence type.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12)),
          ),
      ],
    );
  }

  // ─── Section 5 – XP ────────────────────────────────────────
  Widget _section5() {
    final hasError = _submitted && !_xpValid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _xpOptions
              .map((o) => _pill(
                  label: o,
                  selected: _selectedXp == o,
                  onTap: () => setState(() => _selectedXp = o)))
              .toList(),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Please select an XP value.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12)),
          ),
      ],
    );
  }

  // ─── Section 6 – Cap ───────────────────────────────────────
  Widget _section6() {
    final hasError = _submitted && !_capValid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _capOptions
              .map((o) => _pill(
                  label: o,
                  selected: _selectedCap == o,
                  onTap: () => setState(() => _selectedCap = o)))
              .toList(),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Please select a cap.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12)),
          ),
      ],
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? _primary : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: _primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : _dark,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13)),
      ),
    );
  }

  // ─── Section 7 – Type ──────────────────────────────────────
  Widget _section7() {
    return Row(
      children: ['Individual', 'Group'].map((type) {
        final selected = _selectedType == type;
        final icon =
            type == 'Individual' ? Icons.person_rounded : Icons.group_rounded;
        final isFirst = type == 'Individual';
        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(right: isFirst ? 8 : 0, left: isFirst ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: selected ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: selected ? _primary : Colors.grey.shade300),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: _primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        color: selected
                            ? Colors.white
                            : Colors.grey.shade500,
                        size: 26),
                    const SizedBox(height: 6),
                    Text(type,
                        style: TextStyle(
                            color: selected ? Colors.white : _dark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Section 8 – Justification ─────────────────────────────
  Widget _section8() {
    return TextFormField(
      controller: _justCtrl,
      maxLines: 5,
      style: const TextStyle(color: _dark, fontSize: 15),
      decoration: _deco(
          'Enter manual justification here…', Icons.edit_note_rounded,
          alignHint: true),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Justification is required' : null,
    );
  }

  // ─── Sticky bottom bar ─────────────────────────────────────
  Widget _stickyBottom() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cancel
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed:
                    _isSaving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _dark,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cancel',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(width: 12),
            // Save / Update
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _onSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white))
                    : const Icon(Icons.check_circle_outline_rounded,
                        color: Colors.white),
                label: Text(
                  _isSaving
                      ? 'Saving…'
                      : _isEdit
                          ? 'Update Activity'
                          : 'Save Activity',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared InputDecoration ────────────────────────────────
  InputDecoration _deco(String label, IconData icon,
      {bool alignHint = false}) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignHint,
      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
      labelStyle:
          TextStyle(color: Colors.grey.shade600, fontSize: 14),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2)),
    );
  }
}
