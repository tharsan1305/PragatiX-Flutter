import 'package:flutter/material.dart';

class EditStudentDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  final TextEditingController regNoController;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController sprNoController;
  final List<dynamic> departments;
  final List<dynamic> academicYears;
  final List<dynamic> years;
  final List<dynamic> semesters;
  final List<dynamic> genders;
  final List<dynamic> groups;
  final Future<void> Function(int?, void Function(void Function())) fetchSectionsForDept;
  final Future<void> Function({
    required int id,
    required String fullName,
    required String email,
    required String phone,
    required int? genderId,
    required int? departmentId,
    required int? academicYearId,
    required int? yearId,
    required int? semesterId,
    required int? sectionId,
    required int? groupId,
    required String sprNo,
    required DateTime? dob,
    required String address,
    required bool active,
    required String password,
  }) onEditStudent;
  final VoidCallback clearControllers;

  const EditStudentDialog({
    super.key,
    required this.student,
    required this.regNoController,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.sprNoController,
    required this.departments,
    required this.academicYears,
    required this.years,
    required this.semesters,
    required this.genders,
    required this.groups,
    required this.fetchSectionsForDept,
    required this.onEditStudent,
    required this.clearControllers,
  });

  @override
  State<EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<EditStudentDialog> {
  int? lastFetchedDeptId;
  int? selectedDeptId;
  int? selectedAcademicYearId;
  int? selectedYearId;
  int? selectedSemesterId;
  int? selectedGenderId;
  int? selectedSectionId;
  int? selectedGroupId;
  DateTime? selectedDob;
  final TextEditingController addressController = TextEditingController();
  List<dynamic> dialogSections = [];
  bool isActive = true;
  final TextEditingController passwordController = TextEditingController();

  String _normalizeSectionName(String name) {
    String cleaned = name.trim().toLowerCase();
    if (cleaned.startsWith('section ')) {
      cleaned = cleaned.substring(8).trim();
    }
    return cleaned;
  }

  @override
  void initState() {
    super.initState();
    widget.clearControllers();
    
    final s = widget.student;
    widget.regNoController.text = s['regNo'] ?? '';
    widget.nameController.text = s['fullName'] ?? '';
    widget.emailController.text = s['email'] ?? '';
    widget.phoneController.text = s['phone'] ?? '';
    widget.sprNoController.text = s['sprNo'] ?? '';
    addressController.text = s['address'] ?? '';
    isActive = s['active'] ?? true;
    passwordController.text = '';

    if (s['dob'] != null) {
      try {
        selectedDob = DateTime.parse(s['dob']);
      } catch (e) {
        selectedDob = null;
      }
    }

    final deptData = s['department'];
    selectedDeptId = deptData != null ? deptData['id'] : null;
    if (selectedDeptId != null && !widget.departments.any((d) => d['id'] == selectedDeptId)) {
      selectedDeptId = null;
    }

    final ayData = s['academicYear'];
    selectedAcademicYearId = ayData != null ? ayData['id'] : null;
    if (selectedAcademicYearId != null && !widget.academicYears.any((ay) => ay['id'] == selectedAcademicYearId)) {
      selectedAcademicYearId = null;
    }

    final yData = s['year'];
    selectedYearId = yData != null ? yData['id'] : null;
    if (selectedYearId != null && !widget.years.any((y) => y['id'] == selectedYearId)) {
      selectedYearId = null;
    }

    final semData = s['semester'];
    selectedSemesterId = semData != null ? semData['id'] : null;
    if (selectedSemesterId != null && !widget.semesters.any((sem) => sem['id'] == selectedSemesterId)) {
      selectedSemesterId = null;
    }

    final gData = s['gender'];
    if (gData != null) {
      selectedGenderId = gData['id'];
    } else if (s['genderName'] != null) {
      final match = widget.genders.firstWhere((g) => g['genderName'] == s['genderName'], orElse: () => null);
      if (match != null) selectedGenderId = match['id'];
    }

    final grpData = s['group'];
    selectedGroupId = grpData != null ? grpData['id'] : null;

    final secData = s['section'];
    if (secData != null) {
      selectedSectionId = secData['id'];
    } else if (s['sectionName'] != null) {
      final normalizedTarget = _normalizeSectionName(s['sectionName']);
      final match = dialogSections.firstWhere((sec) => _normalizeSectionName(sec['sectionName'] ?? '') == normalizedTarget, orElse: () => null);
      if (match != null) selectedSectionId = match['id'];
    }
    
    // We will trigger section fetch in build if needed
  }

  @override
  void dispose() {
    addressController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (lastFetchedDeptId != selectedDeptId) {
      Future.microtask(() => widget.fetchSectionsForDept(selectedDeptId, setState)).then((_) {
        if (mounted && widget.student['sectionName'] != null && selectedSectionId == null) {
          final normalizedTarget = _normalizeSectionName(widget.student['sectionName']);
          final match = dialogSections.firstWhere((sec) => _normalizeSectionName(sec['sectionName'] ?? '') == normalizedTarget, orElse: () => null);
          if (match != null) {
            setState(() {
              selectedSectionId = match['id'];
            });
          }
        }
      });
      lastFetchedDeptId = selectedDeptId;
    }

    final filteredSections = dialogSections;
    if (selectedSectionId != null && !filteredSections.any((sec) => sec['id'] == selectedSectionId)) {
      selectedSectionId = null;
    }

    return AlertDialog(
      title: const Text('Edit Student', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: widget.regNoController, decoration: const InputDecoration(labelText: 'Student ID *'), readOnly: true),
            TextField(controller: widget.nameController, decoration: const InputDecoration(labelText: 'Full Name *')),
            TextField(controller: widget.emailController, decoration: const InputDecoration(labelText: 'Email *')),
            TextField(
              controller: widget.phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Phone',
                counterText: '',
              ),
            ),
            TextField(controller: widget.sprNoController, decoration: const InputDecoration(labelText: 'SPR No')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDob == null
                      ? 'Select Date of Birth'
                      : "DOB: ${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDob ?? DateTime(2004),
                      firstDate: DateTime(1995),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDob = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Pick'),
                )
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: selectedDeptId,
              decoration: const InputDecoration(labelText: 'Department'),
              items: widget.departments.map((d) {
                return DropdownMenuItem<int>(
                  value: d['id'],
                  child: Text(d['code'] ?? d['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDeptId = value;
                  selectedSectionId = null;
                });
              },
            ),
            DropdownButtonFormField<int>(
              initialValue: selectedAcademicYearId,
              decoration: const InputDecoration(labelText: 'Academic Year'),
              items: widget.academicYears.map((ay) {
                return DropdownMenuItem<int>(
                  value: ay['id'],
                  child: Text(ay['academicYear'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAcademicYearId = value;
                });
              },
            ),
            DropdownButtonFormField<int>(
              initialValue: selectedYearId,
              decoration: const InputDecoration(labelText: 'Year'),
              items: widget.years.map((y) {
                return DropdownMenuItem<int>(
                  value: y['id'],
                  child: Text(y['yearNo'] != null ? "Year ${y['yearNo']}" : ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedYearId = value;
                });
              },
            ),
            DropdownButtonFormField<int>(
              initialValue: selectedSemesterId,
              decoration: const InputDecoration(labelText: 'Semester'),
              items: widget.semesters.map((sem) {
                return DropdownMenuItem<int>(
                  value: sem['id'],
                  child: Text(sem['semesterNo'] != null ? "Semester ${sem['semesterNo']}" : ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSemesterId = value;
                });
              },
            ),
            DropdownButtonFormField<int>(
              initialValue: selectedGenderId,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: widget.genders.map((g) {
                return DropdownMenuItem<int>(
                  value: g['id'],
                  child: Text(g['genderName'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGenderId = value;
                });
              },
            ),
            DropdownButtonFormField<int>(
              initialValue: selectedSectionId,
              decoration: const InputDecoration(labelText: 'Section'),
              items: filteredSections.map((sec) {
                return DropdownMenuItem<int>(
                  value: sec['id'],
                  child: Text(sec['sectionName'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSectionId = value;
                });
              },
            ),
            DropdownButtonFormField<int>(
              initialValue: selectedGroupId,
              decoration: const InputDecoration(labelText: 'Group'),
              items: widget.groups.map((grp) {
                return DropdownMenuItem<int>(
                  value: grp['id'],
                  child: Text(grp['groupName'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGroupId = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Active Account'),
              value: isActive,
              onChanged: (val) => setState(() => isActive = val),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password (Optional)',
                helperText: 'Leave blank to keep current password',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            widget.onEditStudent(
              id: widget.student['id'],
              fullName: widget.nameController.text.trim(),
              email: widget.emailController.text.trim(),
              phone: widget.phoneController.text.trim(),
              genderId: selectedGenderId,
              departmentId: selectedDeptId,
              academicYearId: selectedAcademicYearId,
              yearId: selectedYearId,
              semesterId: selectedSemesterId,
              sectionId: selectedSectionId,
              groupId: selectedGroupId,
              sprNo: widget.sprNoController.text.trim(),
              dob: selectedDob,
              address: addressController.text.trim(),
              active: isActive,
              password: passwordController.text.trim(),
            );
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
