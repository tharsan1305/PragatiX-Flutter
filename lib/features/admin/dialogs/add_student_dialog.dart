import 'package:flutter/material.dart';

class AddStudentDialog extends StatefulWidget {
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
    required int? departmentId,
    required int? academicYearId,
    required int? yearId,
    required int? semesterId,
    required int? genderId,
    required int? sectionId,
    required int? groupId,
    required String address,
    required DateTime? dob,
  }) onAddStudent;
  final VoidCallback clearControllers;

  const AddStudentDialog({
    super.key,
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
    required this.onAddStudent,
    required this.clearControllers,
  });

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
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

  @override
  void initState() {
    super.initState();
    widget.clearControllers();
    if (widget.departments.isNotEmpty) selectedDeptId = widget.departments.first['id'];
    if (widget.academicYears.isNotEmpty) selectedAcademicYearId = widget.academicYears.first['id'];
    if (widget.years.isNotEmpty) selectedYearId = widget.years.first['id'];
    if (widget.semesters.isNotEmpty) selectedSemesterId = widget.semesters.first['id'];
    if (widget.genders.isNotEmpty) selectedGenderId = widget.genders.first['id'];
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (lastFetchedDeptId != selectedDeptId) {
      Future.microtask(() => widget.fetchSectionsForDept(selectedDeptId, setState));
      lastFetchedDeptId = selectedDeptId;
    }
    
    final filteredSections = dialogSections;
    if (selectedSectionId != null && !filteredSections.any((sec) => sec['id'] == selectedSectionId)) {
      selectedSectionId = null;
    }

    return AlertDialog(
      title: const Text('Register New Student', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: widget.regNoController, decoration: const InputDecoration(labelText: 'Student ID *')),
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
                      ? 'Select Date of Birth *'
                      : "DOB: ${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: selectedDob == null ? Colors.redAccent : Colors.black87),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2004),
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
              decoration: const InputDecoration(labelText: 'Department *'),
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
              decoration: const InputDecoration(labelText: 'Academic Year *'),
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
              decoration: const InputDecoration(labelText: 'Year *'),
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
              decoration: const InputDecoration(labelText: 'Semester *'),
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
              decoration: const InputDecoration(labelText: 'Gender *'),
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
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            widget.onAddStudent(
              departmentId: selectedDeptId,
              academicYearId: selectedAcademicYearId,
              yearId: selectedYearId,
              semesterId: selectedSemesterId,
              genderId: selectedGenderId,
              sectionId: selectedSectionId,
              groupId: selectedGroupId,
              address: addressController.text,
              dob: selectedDob,
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
