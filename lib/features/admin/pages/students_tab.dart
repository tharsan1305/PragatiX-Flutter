
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:spdms_app/features/admin/repository/admin_repository.dart';
import 'package:spdms_app/core/di/service_locator.dart';

import '../dialogs/add_student_dialog.dart';
import '../dialogs/edit_student_dialog.dart';
import '../widgets/student_filter_panel.dart';
import '../widgets/student_list.dart';
import '../widgets/student_fab.dart';





class StudentsTab extends StatefulWidget {

  

  const StudentsTab({super.key});



  @override

  State<StudentsTab> createState() => _StudentsTabState();

}



class _StudentsTabState extends State<StudentsTab> {

  List<dynamic> studentsList = [];

  List<dynamic> departments = [];

  List<dynamic> academicYears = [];

  List<dynamic> years = [];

  List<dynamic> semesters = [];

  List<dynamic> genders = [];

  List<dynamic> sections = [];

  List<dynamic> groups = [];



  List<dynamic> dialogSections = [];

  bool isLoadingSections = false;

  int? lastFetchedDeptId;



  Future<void> _fetchSectionsForDept(int? deptId, void Function(void Function()) setDialogState) async {

    if (deptId == null) {

      setDialogState(() {

        dialogSections = [];

        lastFetchedDeptId = null;

      });

      return;

    }

    setDialogState(() {

      isLoadingSections = true;

      lastFetchedDeptId = deptId;

    });

    try {
      final list = await getIt<AdminRepository>().getDepartmentSections(deptId);
      setDialogState(() {
        dialogSections = list;
      });
    } catch (e) {
      debugPrint('Error fetching dialog sections: $e');
    } finally {

      setDialogState(() {

        isLoadingSections = false;

      });

    }

  }



  bool isLoading = true;

  bool isLoadingLookups = true;

  String searchQuery = '';

  final TextEditingController _searchController = TextEditingController();



  // Controllers

  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController sprNoController = TextEditingController();

  final TextEditingController regNoController = TextEditingController();

  DateTime? selectedDob;

  int? selectedDeptId;



  @override

  void initState() {

    super.initState();

    _fetchStudents();

    _loadAllLookups();

  }



  @override

  void dispose() {

    _searchController.dispose();

    nameController.dispose();

    emailController.dispose();

    phoneController.dispose();

    sprNoController.dispose();

    regNoController.dispose();

    super.dispose();

  }



  Future<void> _loadAllLookups() async {
    try {
      final repo = getIt<AdminRepository>();
      final results = await Future.wait([
        repo.getDepartments(),
        repo.getAcademicYears(),
        repo.getYears(),
        repo.getSemesters(),
        repo.getGenders(),
        repo.getSections(),
        repo.getTeams(),
      ]);

      if (!mounted) return;
      setState(() {
        departments = results[0];
        academicYears = results[1];
        years = results[2];
        semesters = results[3];
        genders = results[4];
        sections = results[5];
        groups = results[6];
        isLoadingLookups = false;

        if (departments.isNotEmpty) selectedDeptId = departments.first['id'];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingLookups = false);
    }
  }



  Future<void> _fetchStudents() async {
    try {
      final fetchedStudents = await getIt<AdminRepository>().getStudents();
      if (!mounted) return;
      setState(() {
        studentsList = fetchedStudents;
        isLoading = false;
      });
    } catch (e) {
      // Fallback
      if (!mounted) return;
      setState(() {
        studentsList = [];
        isLoading = false;
      });
    }
  }



  String _normalizeSectionName(String name) {

    String cleaned = name.trim().toLowerCase();

    if (cleaned.startsWith('section ')) {

      cleaned = cleaned.substring(8).trim();

    }

    return cleaned;

  }



  Future<void> _addStudent({

    required int? departmentId,

    required int? academicYearId,

    required int? yearId,

    required int? semesterId,

    required int? genderId,

    required int? sectionId,

    required int? groupId,

    required String address,

  }) async {

    if (regNoController.text.trim().isEmpty ||

        nameController.text.trim().isEmpty ||

        emailController.text.trim().isEmpty ||

        selectedDob == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Required fields cannot be empty.')),

      );

      return;

    }



    final formattedDob = "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}";

    final passwordDob = "${selectedDob!.day.toString().padLeft(2, '0')}${selectedDob!.month.toString().padLeft(2, '0')}${selectedDob!.year}";



    try {
      await getIt<AdminRepository>().addStudent({
        'regNo': regNoController.text.trim(),
        'fullName': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordDob,
        'phone': phoneController.text.trim(),
        'sprNo': sprNoController.text.trim(),
        'dateOfBirth': formattedDob,
        'address': address,
        'departmentId': departmentId,
        'academicYearId': academicYearId,
        'yearId': yearId,
        'semesterId': semesterId,
        'genderId': genderId,
        'sectionId': sectionId,
        'teamId': groupId,
        'active': true
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student created successfully!'), backgroundColor: Colors.green),
      );
      _clearControllers();
      Navigator.pop(context);
      setState(() => isLoading = true);
      _fetchStudents();
    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Network Error: $e'), backgroundColor: Colors.redAccent),

      );

    }

  }



  Future<void> _editStudent({

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

  }) async {

    if (fullName.isEmpty || email.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('Required fields cannot be empty.')),

      );

      return;

    }



    try {
      final formattedDob = dob != null ? "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}" : null;
      await getIt<AdminRepository>().updateStudent(id, {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'sprNo': sprNo,
        if (formattedDob != null) 'dateOfBirth': formattedDob,
        'address': address,
        'departmentId': departmentId,
        'academicYearId': academicYearId,
        'yearId': yearId,
        'semesterId': semesterId,
        'genderId': genderId,
        'sectionId': sectionId,
        'teamId': groupId,
        'active': active,
        if (password.isNotEmpty) 'password': password,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student details updated successfully!'), backgroundColor: Colors.green),
      );
      _clearControllers();
      Navigator.pop(context);
      setState(() => isLoading = true);
      _fetchStudents();
    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Network Error: $e'), backgroundColor: Colors.redAccent),

      );

    }

  }



  Future<void> _deleteStudent(int id) async {

    try {
      await getIt<AdminRepository>().deleteStudent(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted successfully'), backgroundColor: Colors.green),
      );
      setState(() => isLoading = true);
      _fetchStudents();
    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('Network Error: $e'), backgroundColor: Colors.redAccent),

      );

    }

  }



  void _clearControllers() {

    regNoController.clear();

    nameController.clear();

    emailController.clear();

    phoneController.clear();

    sprNoController.clear();

    selectedDob = null;

  }




  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddStudentDialog(
        regNoController: regNoController,
        nameController: nameController,
        emailController: emailController,
        phoneController: phoneController,
        sprNoController: sprNoController,
        departments: departments,
        academicYears: academicYears,
        years: years,
        semesters: semesters,
        genders: genders,
        groups: groups,
        fetchSectionsForDept: (deptId, setStateCb) => _fetchSectionsForDept(deptId, setStateCb),
        clearControllers: _clearControllers,
        onAddStudent: ({
          required departmentId,
          required academicYearId,
          required yearId,
          required semesterId,
          required genderId,
          required sectionId,
          required groupId,
          required address,
          required dob,
        }) async {
          selectedDob = dob;
          await _addStudent(
            departmentId: departmentId,
            academicYearId: academicYearId,
            yearId: yearId,
            semesterId: semesterId,
            genderId: genderId,
            sectionId: sectionId,
            groupId: groupId,
            address: address,
          );
        },
      ),
    );
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => EditStudentDialog(
        student: student,
        regNoController: regNoController,
        nameController: nameController,
        emailController: emailController,
        phoneController: phoneController,
        sprNoController: sprNoController,
        departments: departments,
        academicYears: academicYears,
        years: years,
        semesters: semesters,
        genders: genders,
        groups: groups,
        fetchSectionsForDept: (deptId, setStateCb) => _fetchSectionsForDept(deptId, setStateCb),
        clearControllers: _clearControllers,
        onEditStudent: ({
          required id,
          required fullName,
          required email,
          required phone,
          required genderId,
          required departmentId,
          required academicYearId,
          required yearId,
          required semesterId,
          required sectionId,
          required groupId,
          required sprNo,
          required dob,
          required address,
          required active,
          required password,
        }) async {
          await _editStudent(
            id: id,
            fullName: fullName,
            email: email,
            phone: phone,
            genderId: genderId,
            departmentId: departmentId,
            academicYearId: academicYearId,
            yearId: yearId,
            semesterId: semesterId,
            sectionId: sectionId,
            groupId: groupId,
            sprNo: sprNo,
            dob: dob,
            address: address,
            active: active,
            password: password,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchStudents();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  StudentFilterPanel(
                    searchController: _searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StudentList(
                      studentsList: studentsList,
                      searchQuery: searchQuery,
                      onEdit: _showEditStudentDialog,
                      onDelete: _deleteStudent,
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: StudentFab(
        onPressed: _showAddStudentDialog,
      ),
    );
  }
}
