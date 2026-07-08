import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../teacher_student_detail.dart';

Future<List<dynamic>> _apiGetDepartments(String token) async {
  try {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8080/api/v1/admin/departments"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        return data["data"] ?? [];
      }
    }
  } catch (e) {
    // Fail silently
  }
  return [
    {"id": 1, "name": "Computer Science and Engineering", "code": "CSE"},
    {"id": 2, "name": "Electronics and Communication", "code": "ECE"},
  ];
}

class StudentsTab extends StatefulWidget {
  final String token;
  final List<String> subRoles;
  const StudentsTab({super.key, required this.token, required this.subRoles});

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
  bool isLoadingLookups = true;
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String? filterYear;
  final TextEditingController filterSectionController = TextEditingController();

  // Single Student controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController sprNoController = TextEditingController();
  final TextEditingController regNoController = TextEditingController();
  DateTime? selectedDob;
  int? selectedDeptId;

  // Student Edit controllers
  final TextEditingController editNameController = TextEditingController();
  final TextEditingController editEmailController = TextEditingController();
  final TextEditingController editPhoneController = TextEditingController();
  final TextEditingController editSprNoController = TextEditingController();
  final TextEditingController editGenderController = TextEditingController();
  final TextEditingController editSemesterController = TextEditingController();
  final TextEditingController editYearController = TextEditingController();
  int? editSelectedDeptId;
  DateTime? editSelectedDob;

  @override
  void dispose() {
    _searchController.dispose();
    filterSectionController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    sprNoController.dispose();
    regNoController.dispose();
    editNameController.dispose();
    editEmailController.dispose();
    editPhoneController.dispose();
    editSprNoController.dispose();
    editGenderController.dispose();
    editSemesterController.dispose();
    editYearController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    bool isHod = widget.subRoles.contains("HOD");
    bool isCc = widget.subRoles.contains("CC");
    if (isCc) {
      _fetchStudents();
    } else {
      isLoading = false;
    }
    _loadAllLookups();
  }

  Future<void> _loadAllLookups() async {
    try {
      final headers = {"Authorization": "Bearer ${widget.token}"};
      final results = await Future.wait([
        http.get(Uri.parse("http://10.0.2.2:8080/api/v1/admin/departments"), headers: headers),
        http.get(Uri.parse("http://10.0.2.2:8080/api/v1/admin/academic-years"), headers: headers),
        http.get(Uri.parse("http://10.0.2.2:8080/api/v1/admin/years"), headers: headers),
        http.get(Uri.parse("http://10.0.2.2:8080/api/v1/admin/semesters"), headers: headers),
        http.get(Uri.parse("http://10.0.2.2:8080/api/v1/admin/genders"), headers: headers),
        http.get(Uri.parse("http://10.0.2.2:8080/api/v1/admin/sections"), headers: headers),
        http.get(Uri.parse("http://10.0.2.2:8080/api/v1/groups"), headers: headers),
      ]);

      if (!mounted) return;

      setState(() {
        departments = jsonDecode(results[0].body)["data"] ?? [];
        academicYears = jsonDecode(results[1].body)["data"] ?? [];
        years = jsonDecode(results[2].body)["data"] ?? [];
        semesters = jsonDecode(results[3].body)["data"] ?? [];
        genders = jsonDecode(results[4].body)["data"] ?? [];
        sections = jsonDecode(results[5].body)["data"] ?? [];
        groups = jsonDecode(results[6].body)["data"] ?? [];
        isLoadingLookups = false;

        if (departments.isNotEmpty) selectedDeptId = departments.first["id"];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingLookups = false);
    }
  }

  Future<void> _fetchStudents() async {
    bool isHod = widget.subRoles.contains("HOD");
    bool isCc = widget.subRoles.contains("CC");

    if (!isHod && !isCc) {
      setState(() {
        studentsList = [];
        isLoading = false;
      });
      return;
    }

    if (isHod && (filterYear == null || filterYear!.isEmpty)) {
      setState(() {
        studentsList = [];
        isLoading = false;
      });
      return;
    }

    String url = "http://10.0.2.2:8080/api/v1/students?page=0&size=100&sortBy=fullName";
    if (isHod) {
      url += "&year=$filterYear";
      if (filterSectionController.text.trim().isNotEmpty) {
        url += "&section=${Uri.encodeComponent(filterSectionController.text.trim())}";
      }
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            studentsList = data["data"]["content"] ?? [];
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Fallback
    }

    setState(() {
      studentsList = [];
      isLoading = false;
    });
  }

  Future<void> _searchStudents(String query) async {
    if (query.trim().isEmpty) {
      setState(() => isLoading = true);
      _fetchStudents();
      return;
    }
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/students/search?keyword=${Uri.encodeComponent(query.trim())}"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            studentsList = data["data"]["content"] ?? [];
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Fallback
    }
    setState(() {
      studentsList = [];
      isLoading = false;
    });
  }

  Future<void> _addSingleStudent({
    required int? departmentId,
    required int? academicYearId,
    required int? yearId,
    required int? semesterId,
    required int? genderId,
    required int? sectionId,
    required int? groupId,
    required String address,
  }) async {
    if (nameController.text.trim().isEmpty ||
        regNoController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name, Reg No, Email and DOB are required.")),
      );
      return;
    }

    final formattedDob = "${selectedDob!.year}-${selectedDob!.month.toString().padLeft(2, '0')}-${selectedDob!.day.toString().padLeft(2, '0')}";

    // Generates DOB as ddMMyyyy (e.g. 15102004)
    final passwordDob = "${selectedDob!.day.toString().padLeft(2, '0')}${selectedDob!.month.toString().padLeft(2, '0')}${selectedDob!.year}";

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/students"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "studentId": regNoController.text.trim(),
          "fullName": nameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordDob,
          "phone": phoneController.text.trim(),
          "dateOfBirth": formattedDob,
          "dob": formattedDob,
          "address": address,
          "departmentId": departmentId,
          "academicYearId": academicYearId,
          "yearId": yearId,
          "semesterId": semesterId,
          "genderId": genderId,
          "sectionId": sectionId,
          "groupId": groupId,
          "sprNo": sprNoController.text.trim(),
          "active": true
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || (response.statusCode == 200 && data["success"] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student registered successfully!"), backgroundColor: Colors.green),
        );
        _clearControllers();
        Navigator.pop(context);
        setState(() => isLoading = true);
        _fetchStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Registration Failed"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added student locally"), backgroundColor: Colors.orange),
      );
      setState(() {
        studentsList.add({
          "id": studentsList.length + 1,
          "studentId": regNoController.text.trim(),
          "fullName": nameController.text.trim(),
          "email": emailController.text.trim(),
          "phone": phoneController.text.trim(),
          "departmentName": departments.firstWhere((d) => d["id"] == departmentId, orElse: () => {"name": "CSE"})["name"],
          "semester": "1",
          "sprNo": sprNoController.text.trim(),
          "dateOfBirth": formattedDob
        });
      });
      _clearControllers();
      Navigator.pop(context);
    }
  }

  Future<void> _uploadBulkExcel() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.path == null) return;
      final filePath = result.files.single.path!;

      setState(() => isLoading = true);

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("http://10.0.2.2:8080/api/v1/students/bulk-parse"),
      );
      request.headers["Authorization"] = "Bearer ${widget.token}";
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response.statusCode == 200 && data["success"] == true) {
        final List<dynamic> parsedStudents = data["data"] ?? [];
        if (parsedStudents.isEmpty) {
          messenger.showSnackBar(
            const SnackBar(content: Text("No valid student records found in the Excel sheet."), backgroundColor: Colors.orange),
          );
          return;
        }

        final bool? importCompleted = await navigator.push<bool>(
          MaterialPageRoute(
            builder: (context) => BulkVerificationScreen(
              parsedStudents: parsedStudents,
              token: widget.token,
              departments: departments,
            ),
          ),
        );

        if (importCompleted == true) {
          setState(() => isLoading = true);
          _fetchStudents();
        }
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to parse spreadsheet file."), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      messenger.showSnackBar(
        SnackBar(content: Text("Error picking/parsing file: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _clearControllers() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    sprNoController.clear();
    regNoController.clear();
    selectedDob = null;
    if (departments.isNotEmpty) {
      selectedDeptId = departments.first["id"];
    }
  }

  void _showAddStudentOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Students", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF11998e)),
                title: const Text("Register Single Student"),
                subtitle: const Text("Enter Name, Reg No, DOB, and details manually"),
                onTap: () {
                  Navigator.pop(context);
                  _showSingleStudentDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.upload_file_rounded, color: Colors.green),
                title: const Text("Excel Bulk Upload"),
                subtitle: const Text("Upload spreadsheet with columns mapping details"),
                onTap: () {
                  Navigator.pop(context);
                  _uploadBulkExcel();
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ],
        );
      },
    );
  }

  void _showSingleStudentDialog() {
    _clearControllers();
    int? selectedDeptId = departments.isNotEmpty ? departments.first["id"] : null;
    int? selectedAcademicYearId = academicYears.isNotEmpty ? academicYears.first["id"] : null;
    int? selectedYearId = years.isNotEmpty ? years.first["id"] : null;
    int? selectedSemesterId = semesters.isNotEmpty ? semesters.first["id"] : null;
    int? selectedGenderId = genders.isNotEmpty ? genders.first["id"] : null;
    int? selectedSectionId;
    int? selectedGroupId;
    final TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filter sections by department ID
            final filteredSections = sections.where((sec) => sec["departmentId"] == selectedDeptId).toList();
            if (selectedSectionId != null && !filteredSections.any((sec) => sec["id"] == selectedSectionId)) {
              selectedSectionId = null;
            }

            return AlertDialog(
              title: const Text("Register Single Student", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: "Student Name *")),
                    TextField(controller: regNoController, decoration: const InputDecoration(labelText: "Register Number * (reg_no)")),
                    TextField(controller: sprNoController, decoration: const InputDecoration(labelText: "SPR Number (spr_no)")),
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email *")),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        counterText: "",
                      ),
                    ),
                    TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDob == null
                              ? "Select Date of Birth *"
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
                              setDialogState(() {
                                selectedDob = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text("Pick"),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: selectedDeptId,
                      decoration: const InputDecoration(labelText: "Department *"),
                      items: departments.map((d) {
                        return DropdownMenuItem<int>(
                          value: d["id"],
                          child: Text(d["code"] ?? d["name"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDeptId = value;
                          selectedSectionId = null; // Clear Section on department change
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: selectedAcademicYearId,
                      decoration: const InputDecoration(labelText: "Academic Year *"),
                      items: academicYears.map((ay) {
                        return DropdownMenuItem<int>(
                          value: ay["id"],
                          child: Text(ay["academicYear"] ?? ""),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAcademicYearId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: selectedYearId,
                      decoration: const InputDecoration(labelText: "Year *"),
                      items: years.map((y) {
                        return DropdownMenuItem<int>(
                          value: y["id"],
                          child: Text(y["yearNo"] != null ? "Year ${y["yearNo"]}" : ""),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedYearId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: selectedSemesterId,
                      decoration: const InputDecoration(labelText: "Semester *"),
                      items: semesters.map((s) {
                        return DropdownMenuItem<int>(
                          value: s["id"],
                          child: Text(s["semesterNo"] != null ? "Semester ${s["semesterNo"]}" : ""),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSemesterId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: selectedGenderId,
                      decoration: const InputDecoration(labelText: "Gender *"),
                      items: genders.map((g) {
                        return DropdownMenuItem<int>(
                          value: g["id"],
                          child: Text(g["genderName"] ?? ""),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGenderId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int?>(
                      value: selectedSectionId,
                      decoration: const InputDecoration(labelText: "Section (Optional)"),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("No Section Selected (Optional)"),
                        ),
                        ...filteredSections.map((sec) {
                          return DropdownMenuItem<int?>(
                            value: sec["id"],
                            child: Text(sec["sectionName"] ?? ""),
                          );
                        })
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSectionId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int?>(
                      value: selectedGroupId,
                      decoration: const InputDecoration(labelText: "Group (Optional)"),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("No Group Selected (Optional)"),
                        ),
                        ...groups.map((grp) {
                          return DropdownMenuItem<int?>(
                            value: grp["id"],
                            child: Text(grp["name"] ?? ""),
                          );
                        })
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGroupId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    _addSingleStudent(
                      departmentId: selectedDeptId,
                      academicYearId: selectedAcademicYearId,
                      yearId: selectedYearId,
                      semesterId: selectedSemesterId,
                      genderId: selectedGenderId,
                      sectionId: selectedSectionId,
                      groupId: selectedGroupId,
                      address: addressController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF11998e)),
                  child: const Text("Register", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showManageGroupsDialog() {
    final TextEditingController groupNameController = TextEditingController();
    final TextEditingController groupSizeController = TextEditingController();
    final TextEditingController captainIdController = TextEditingController();
    final TextEditingController membersController = TextEditingController();
    List<dynamic> localGroups = [];
    bool isGroupsLoading = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void loadGroups() async {
              try {
                final response = await http.get(
                  Uri.parse("http://10.0.2.2:8080/api/v1/groups"),
                  headers: {"Authorization": "Bearer ${widget.token}"},
                );
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  if (data["success"] == true) {
                    setDialogState(() {
                      localGroups = data["data"] ?? [];
                      isGroupsLoading = false;
                    });
                  }
                }
              } catch (e) {
                setDialogState(() {
                  isGroupsLoading = false;
                });
              }
            }

            if (isGroupsLoading) {
              loadGroups();
            }

            return DefaultTabController(
              length: 2,
              child: AlertDialog(
                title: const Text("Group Management (CC)", style: TextStyle(fontWeight: FontWeight.bold)),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 450,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Color(0xFF11998e),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFF11998e),
                        tabs: [
                          Tab(text: "Create Group"),
                          Tab(text: "View Groups"),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  TextField(
                                    controller: groupNameController,
                                    decoration: const InputDecoration(labelText: "Group Name *"),
                                  ),
                                  TextField(
                                    controller: groupSizeController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: "Group Size Limit * (e.g. 5)"),
                                  ),
                                  TextField(
                                    controller: captainIdController,
                                    decoration: const InputDecoration(labelText: "Captain Student ID *"),
                                  ),
                                  TextField(
                                    controller: membersController,
                                    decoration: const InputDecoration(
                                      labelText: "Member Student IDs (Comma separated)",
                                      hintText: "e.g. CSE002, CSE003, CSE004",
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final String gName = groupNameController.text.trim();
                                      final String gSizeStr = groupSizeController.text.trim();
                                      final String captId = captainIdController.text.trim();
                                      final String memsStr = membersController.text.trim();

                                      if (gName.isEmpty || gSizeStr.isEmpty || captId.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Please fill in all required fields.")),
                                        );
                                        return;
                                      }

                                      final int size = int.tryParse(gSizeStr) ?? 0;
                                      if (size <= 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Size must be a valid positive integer.")),
                                        );
                                        return;
                                      }

                                      final List<String> memberIds = memsStr.isNotEmpty
                                          ? memsStr.split(",").map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
                                          : [];

                                      final int total = 1 + memberIds.length;
                                      if (total > size) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Member count ($total including captain) cannot exceed size limit ($size).")),
                                        );
                                        return;
                                      }

                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        final response = await http.post(
                                          Uri.parse("http://10.0.2.2:8080/api/v1/groups"),
                                          headers: {
                                            "Content-Type": "application/json",
                                            "Authorization": "Bearer ${widget.token}",
                                          },
                                          body: jsonEncode({
                                            "name": gName,
                                            "size": size,
                                            "captainStudentId": captId,
                                            "memberStudentIds": memberIds
                                          }),
                                        );

                                        final data = jsonDecode(response.body);
                                        if (response.statusCode == 201 || (response.statusCode == 200 && data["success"] == true)) {
                                          messenger.showSnackBar(
                                            const SnackBar(content: Text("Group created successfully!"), backgroundColor: Colors.green),
                                          );
                                          groupNameController.clear();
                                          groupSizeController.clear();
                                          captainIdController.clear();
                                          membersController.clear();
                                          setDialogState(() {
                                            isGroupsLoading = true;
                                          });
                                          _fetchStudents();
                                        } else {
                                          messenger.showSnackBar(
                                            SnackBar(content: Text(data["message"] ?? "Failed to create group")),
                                          );
                                        }
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          const SnackBar(content: Text("Network error creating group")),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF11998e)),
                                    child: const Text("Create Group", style: TextStyle(color: Colors.white)),
                                  )
                                ],
                              ),
                            ),
                            isGroupsLoading
                                ? const Center(child: CircularProgressIndicator())
                                : localGroups.isEmpty
                                    ? const Center(child: Text("No groups created yet."))
                                    : ListView.builder(
                                        itemCount: localGroups.length,
                                        itemBuilder: (context, index) {
                                          final g = localGroups[index];
                                          final List<dynamic> mems = g["members"] ?? [];
                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(g["name"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                  const SizedBox(height: 4),
                                                  Text("Captain: ${g["captainName"] ?? ""} (${g["captainStudentId"] ?? ""})", style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                                                  Text("Size Limit: ${g["size"] ?? 0} | Current Members: ${1 + mems.length}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                  const SizedBox(height: 6),
                                                  const Text("Members List:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                  Text("• ${g["captainName"] ?? ""} (${g["captainStudentId"] ?? ""}) - Captain", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                  ...mems.map((m) => Text("• ${m["fullName"]} (${m["studentId"]})", style: const TextStyle(fontSize: 12))),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReportMonitorDialog() {
    final TextEditingController studentIdController = TextEditingController();
    List<dynamic> logs = [];
    bool isSearching = false;
    String? searchError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Discipline Report Monitor", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: studentIdController,
                            decoration: const InputDecoration(
                              labelText: "Enter Student Registration No",
                              hintText: "e.g. CSE001",
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final String sId = studentIdController.text.trim();
                            if (sId.isEmpty) return;

                            setDialogState(() {
                              isSearching = true;
                              searchError = null;
                              logs = [];
                            });

                            try {
                              final studentResponse = await http.get(
                                Uri.parse("http://10.0.2.2:8080/api/v1/students/search?keyword=$sId"),
                                headers: {"Authorization": "Bearer ${widget.token}"},
                              );
                              final studentData = jsonDecode(studentResponse.body);
                              if (studentResponse.statusCode == 200 && studentData["success"] == true) {
                                final List<dynamic> students = studentData["data"]["content"] ?? [];
                                final match = students.firstWhere((element) => element["studentId"].toString().toLowerCase() == sId.toLowerCase(), orElse: () => null);
                                if (match != null) {
                                  final int dbId = match["id"];
                                  final logsResponse = await http.get(
                                    Uri.parse("http://10.0.2.2:8080/api/v1/students/$dbId/discipline-logs"),
                                    headers: {"Authorization": "Bearer ${widget.token}"},
                                  );
                                  final logsData = jsonDecode(logsResponse.body);
                                  if (logsResponse.statusCode == 200) {
                                    setDialogState(() {
                                      logs = logsData["data"] ?? [];
                                      isSearching = false;
                                      if (logs.isEmpty) {
                                        searchError = "No discipline entries recorded for this student.";
                                      }
                                    });
                                    return;
                                  }
                                }
                              }
                              setDialogState(() {
                                isSearching = false;
                                searchError = "Student ID not found in records.";
                              });
                            } catch (e) {
                              setDialogState(() {
                                isSearching = false;
                                searchError = "Network error fetching logs.";
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                          child: const Text("Search", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : searchError != null
                              ? Center(child: Text(searchError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)))
                              : logs.isEmpty
                                  ? const Center(child: Text("Search for a student to monitor discipline logs history."))
                                  : ListView.builder(
                                      itemCount: logs.length,
                                      itemBuilder: (context, index) {
                                        final log = logs[index];
                                        final int pts = log["points"] ?? 0;
                                        final String reason = log["reason"] ?? "No reason given";
                                        final String recordedBy = log["recordedByName"] ?? "Faculty";
                                        final String actName = log["subgroupName"] ?? "General";
                                        final String dtStr = log["createdAt"] != null 
                                            ? log["createdAt"].toString().replaceAll("T", " ").substring(0, 16) 
                                            : "";

                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            dense: true,
                                            leading: CircleAvatar(
                                              radius: 18,
                                              backgroundColor: pts >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                              child: Icon(
                                                pts >= 0 ? Icons.add_circle : Icons.remove_circle,
                                                color: pts >= 0 ? Colors.green : Colors.red,
                                                size: 20,
                                              ),
                                            ),
                                            title: Text(reason, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text("By: $recordedBy • Act: $actName\nDate: $dtStr"),
                                            trailing: Text(
                                              pts >= 0 ? "+$pts" : "$pts",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: pts >= 0 ? Colors.green : Colors.red,
                                                fontSize: 14
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                )
              ],
            );
          },
        );
      },
    );
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
        const SnackBar(content: Text("Name and Email are required.")),
      );
      return;
    }

    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:8080/api/v1/students/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "fullName": fullName,
          "email": email,
          "phone": phone,
          "genderId": genderId,
          "departmentId": departmentId,
          "academicYearId": academicYearId,
          "yearId": yearId,
          "semesterId": semesterId,
          "sectionId": sectionId,
          "groupId": groupId,
          "sprNo": sprNo,
          "dob": dob != null ? "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}" : null,
          "address": address,
          "active": active,
          "password": password.isEmpty ? null : password,
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student details updated successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
        setState(() => isLoading = true);
        _fetchStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to update student"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network/Server error updating student details."), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _deleteStudent(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("http://10.0.2.2:8080/api/v1/students/$id"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student deleted successfully"), backgroundColor: Colors.green),
        );
        setState(() => isLoading = true);
        _fetchStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Delete failed on server"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error deleting student"), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    final TextEditingController nameCtrl = TextEditingController(text: student["fullName"] ?? '');
    final TextEditingController emailCtrl = TextEditingController(text: student["email"] ?? '');
    final TextEditingController phoneCtrl = TextEditingController(text: student["phone"] ?? '');
    final TextEditingController sprCtrl = TextEditingController(text: student["sprNo"] ?? '');
    final TextEditingController addressCtrl = TextEditingController(text: student["address"] ?? '');
    final TextEditingController passwordCtrl = TextEditingController();

    DateTime? editDob;
    if (student["dateOfBirth"] != null) {
      try {
        editDob = DateTime.parse(student["dateOfBirth"]);
      } catch (_) {}
    }

    int? selectedDeptId = student["departmentId"];
    if (selectedDeptId == null && student["departmentName"] != null) {
      final match = departments.firstWhere((d) => d["name"] == student["departmentName"], orElse: () => null);
      if (match != null) selectedDeptId = match["id"];
    }
    if (selectedDeptId == null && departments.isNotEmpty) {
      selectedDeptId = departments.first["id"];
    }

    int? selectedAcademicYearId = student["academicYearId"];
    if (selectedAcademicYearId == null && student["academicYear"] != null) {
      final match = academicYears.firstWhere((ay) => ay["academicYear"] == student["academicYear"], orElse: () => null);
      if (match != null) selectedAcademicYearId = match["id"];
    }
    if (selectedAcademicYearId == null && academicYears.isNotEmpty) {
      selectedAcademicYearId = academicYears.first["id"];
    }

    int? selectedYearId = student["yearId"];
    if (selectedYearId == null && student["year"] != null) {
      final match = years.firstWhere((y) => y["yearNo"]?.toString() == student["year"], orElse: () => null);
      if (match != null) selectedYearId = match["id"];
    }
    if (selectedYearId == null && years.isNotEmpty) {
      selectedYearId = years.first["id"];
    }

    int? selectedSemesterId = student["semesterId"];
    if (selectedSemesterId == null && student["semester"] != null) {
      final match = semesters.firstWhere((s) => s["semesterNo"]?.toString() == student["semester"], orElse: () => null);
      if (match != null) selectedSemesterId = match["id"];
    }
    if (selectedSemesterId == null && semesters.isNotEmpty) {
      selectedSemesterId = semesters.first["id"];
    }

    int? selectedGenderId = student["genderId"];
    if (selectedGenderId == null && student["gender"] != null) {
      final match = genders.firstWhere((g) => g["genderName"]?.toString().toUpperCase() == student["gender"].toString().toUpperCase(), orElse: () => null);
      if (match != null) selectedGenderId = match["id"];
    }
    if (selectedGenderId == null && genders.isNotEmpty) {
      selectedGenderId = genders.first["id"];
    }

    int? selectedSectionId = student["sectionId"];
    int? selectedGroupId = student["groupId"];
    bool active = student["active"] ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredSections = sections.where((sec) => sec["departmentId"] == selectedDeptId).toList();
            if (selectedSectionId != null && !filteredSections.any((sec) => sec["id"] == selectedSectionId)) {
              selectedSectionId = null;
            }

            return AlertDialog(
              title: Text("Edit Student: ${student["studentId"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name *")),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email *")),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: "Phone",
                        counterText: "",
                      ),
                    ),
                    TextField(controller: sprCtrl, decoration: const InputDecoration(labelText: "SPR No")),
                    TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Address")),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Change Password (leave empty to keep current)"),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          editDob == null
                              ? "Select Date of Birth *"
                              : "DOB: ${editDob!.year}-${editDob!.month.toString().padLeft(2, '0')}-${editDob!.day.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: editDob ?? DateTime(2004),
                              firstDate: DateTime(1995),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                editDob = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text("Select"),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: departments.any((d) => d["id"] == selectedDeptId) ? selectedDeptId : null,
                      decoration: const InputDecoration(labelText: "Department *"),
                      items: departments.map((d) {
                        return DropdownMenuItem<int>(
                          value: d["id"],
                          child: Text(d["code"] ?? d["name"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDeptId = value;
                          selectedSectionId = null;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: academicYears.any((ay) => ay["id"] == selectedAcademicYearId) ? selectedAcademicYearId : null,
                      decoration: const InputDecoration(labelText: "Academic Year *"),
                      items: academicYears.map((ay) {
                        return DropdownMenuItem<int>(
                          value: ay["id"],
                          child: Text(ay["academicYear"] ?? ""),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAcademicYearId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: years.any((y) => y["id"] == selectedYearId) ? selectedYearId : null,
                      decoration: const InputDecoration(labelText: "Year *"),
                      items: years.map((y) {
                        return DropdownMenuItem<int>(
                          value: y["id"],
                          child: Text(y["yearNo"] != null ? "Year ${y["yearNo"]}" : ""),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedYearId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: semesters.any((s) => s["id"] == selectedSemesterId) ? selectedSemesterId : null,
                      decoration: const InputDecoration(labelText: "Semester *"),
                      items: semesters.map((s) {
                        return DropdownMenuItem<int>(
                          value: s["id"],
                          child: Text(s["semesterNo"] != null ? "Semester ${s["semesterNo"]}" : ""),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSemesterId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: genders.any((g) => g["id"] == selectedGenderId) ? selectedGenderId : null,
                      decoration: const InputDecoration(labelText: "Gender *"),
                      items: genders.map((g) {
                        return DropdownMenuItem<int>(
                          value: g["id"],
                          child: Text(g["genderName"] ?? ""),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGenderId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int?>(
                      value: filteredSections.any((sec) => sec["id"] == selectedSectionId) ? selectedSectionId : null,
                      decoration: const InputDecoration(labelText: "Section (Optional)"),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("No Section Selected (Optional)"),
                        ),
                        ...filteredSections.map((sec) {
                          return DropdownMenuItem<int?>(
                            value: sec["id"],
                            child: Text(sec["sectionName"] ?? ""),
                          );
                        })
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSectionId = value;
                        });
                      },
                    ),
                    DropdownButtonFormField<int?>(
                      value: groups.any((grp) => grp["id"] == selectedGroupId) ? selectedGroupId : null,
                      decoration: const InputDecoration(labelText: "Group (Optional)"),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("No Group Selected (Optional)"),
                        ),
                        ...groups.map((grp) {
                          return DropdownMenuItem<int?>(
                            value: grp["id"],
                            child: Text(grp["name"] ?? ""),
                          );
                        })
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGroupId = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Active"),
                      value: active,
                      onChanged: (value) {
                        setDialogState(() {
                          active = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    _editStudent(
                      id: student["id"],
                      fullName: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      genderId: selectedGenderId,
                      departmentId: selectedDeptId,
                      academicYearId: selectedAcademicYearId,
                      yearId: selectedYearId,
                      semesterId: selectedSemesterId,
                      sectionId: selectedSectionId,
                      groupId: selectedGroupId,
                      sprNo: sprCtrl.text.trim(),
                      dob: editDob,
                      address: addressCtrl.text.trim(),
                      active: active,
                      password: passwordCtrl.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF11998e)),
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Students Directory", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          if (widget.subRoles.contains("CC")) ...[
            IconButton(
              icon: const Icon(Icons.group_add_outlined, color: Colors.white),
              tooltip: "Manage Groups",
              onPressed: _showManageGroupsDialog,
            ),
            IconButton(
              icon: const Icon(Icons.insights_outlined, color: Colors.white),
              tooltip: "Report Monitor",
              onPressed: _showReportMonitorDialog,
            ),
          ],
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
                  if (widget.subRoles.contains("HOD")) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: const Color(0xFF1E293B).withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Filter Students (HOD)",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: filterYear,
                                    decoration: const InputDecoration(
                                      labelText: "Select Year *",
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: "I", child: Text("I Year")),
                                      DropdownMenuItem(value: "II", child: Text("II Year")),
                                      DropdownMenuItem(value: "III", child: Text("III Year")),
                                      DropdownMenuItem(value: "IV", child: Text("IV Year")),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        filterYear = value;
                                        isLoading = true;
                                      });
                                      _fetchStudents();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: filterSectionController,
                                    decoration: const InputDecoration(
                                      labelText: "Section (Optional)",
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    onChanged: (value) {
                                      setState(() => isLoading = true);
                                      _fetchStudents();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by student name or reg no...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _fetchStudents();
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (value) {
                      _searchStudents(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: studentsList.length,
                      itemBuilder: (context, index) {
                        final s = studentsList[index];
                        final String sId = s["studentId"] ?? '';
                        final String name = s["fullName"] ?? '';
                        final String deptName = s["departmentName"] ?? 'No Department';
                        final String spr = s["sprNo"] ?? 'N/A';

                        if (searchQuery.isNotEmpty &&
                            !sId.toLowerCase().contains(searchQuery) &&
                            !name.toLowerCase().contains(searchQuery)) {
                          return const SizedBox.shrink();
                        }

                        final int score = s["score"] ?? 0;

                        final String yearStr = s["year"] != null && s["year"].toString().isNotEmpty ? " • Year: ${s["year"]}" : "";
                        final String sectionStr = s["section"] != null && s["section"].toString().isNotEmpty ? " • Section: ${s["section"]}" : "";

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF11998e).withOpacity(0.1),
                              child: const Icon(Icons.person, color: Color(0xFF11998e)),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Reg No: $sId • SPR: $spr$yearStr$sectionStr\nDept: $deptName"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "$score pts",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                                  ),
                                ),
                                if (widget.subRoles.contains("CC")) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () => _showEditStudentDialog(s),
                                    tooltip: "Edit student",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Delete Student"),
                                          content: Text("Are you sure you want to delete student $name?"),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteStudent(s["id"]);
                                              },
                                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    tooltip: "Delete student",
                                  ),
                                ],
                              ],
                            ),
                            onTap: () {
                              final mappedStudent = {
                                "id": s["id"],
                                "name": name,
                                "regNo": sId,
                                "dept": deptName,
                                "score": score,
                                "isCaptain": s["isCaptain"] ?? s["captain"] ?? false,
                              };
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeacherStudentDetail(student: mappedStudent, token: widget.token),
                                ),
                              ).then((_) {
                                if (_searchController.text.trim().isNotEmpty) {
                                  _searchStudents(_searchController.text.trim());
                                } else {
                                  _fetchStudents();
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: widget.subRoles.contains("CC")
          ? FloatingActionButton.extended(
              onPressed: _showAddStudentOptions,
              backgroundColor: const Color(0xFF11998e),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Students", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}

class BulkVerificationScreen extends StatefulWidget {
  final List<dynamic> parsedStudents;
  final String token;
  final List<dynamic> departments;

  const BulkVerificationScreen({
    super.key,
    required this.parsedStudents,
    required this.token,
    required this.departments,
  });

  @override
  State<BulkVerificationScreen> createState() => _BulkVerificationScreenState();
}

class _BulkVerificationScreenState extends State<BulkVerificationScreen> {
  late List<Map<String, dynamic>> _students;
  late List<bool> _checkedStates;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _students = List<Map<String, dynamic>>.from(
      widget.parsedStudents.map((item) => Map<String, dynamic>.from(item)),
    );
    _checkedStates = List<bool>.filled(_students.length, true);
  }

  void _toggleCheckAll(bool val) {
    setState(() {
      for (int i = 0; i < _checkedStates.length; i++) {
        _checkedStates[i] = val;
      }
    });
  }

  Future<void> _editStudent(int index) async {
    final updatedStudent = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditStudentDialog(student: _students[index]),
    );

    if (updatedStudent != null) {
      setState(() {
        _students[index] = updatedStudent;
      });
    }
  }

  void _removeStudent(int index) {
    setState(() {
      _students.removeAt(index);
      _checkedStates.removeAt(index);
    });
  }

  Future<void> _proceedImport() async {
    final selectedStudents = <Map<String, dynamic>>[];
    for (int i = 0; i < _students.length; i++) {
      if (_checkedStates[i]) {
        selectedStudents.add(_students[i]);
      }
    }

    if (selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please check at least one student to import."), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isImporting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/students/bulk-import"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(selectedStudents),
      );

      final data = jsonDecode(response.body);

      setState(() => _isImporting = false);

      if (response.statusCode == 200 && data["success"] == true) {
        messenger.showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Import complete!"), backgroundColor: Colors.green),
        );
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to save students list."), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      setState(() => _isImporting = false);
      messenger.showSnackBar(
        SnackBar(content: Text("Network/Server error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allChecked = _checkedStates.isNotEmpty && _checkedStates.every((e) => e);
    final anyChecked = _checkedStates.any((e) => e);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Spreadsheet Data", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
      body: _isImporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF11998e)),
                  SizedBox(height: 16),
                  Text("Saving selected students into database...", style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11998e).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: allChecked,
                          tristate: anyChecked && !allChecked,
                          onChanged: (val) => _toggleCheckAll(val ?? true),
                          activeColor: const Color(0xFF11998e),
                        ),
                        Text(
                          allChecked ? "Uncheck All" : "Check All",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const Spacer(),
                        Text(
                          "${_checkedStates.where((c) => c).length} selected",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF11998e)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final s = _students[index];
                        final name = s["fullName"] ?? "";
                        final regNo = s["studentId"] ?? "";
                        final sprNo = s["sprNo"] ?? "";
                        final email = s["email"] ?? "";
                        final dob = s["dateOfBirth"] ?? "N/A";
                        final dept = s["departmentName"] ?? "";
                        final academicYear = s["academicYear"] ?? "";

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: _checkedStates[index]
                                  ? const Color(0xFF11998e).withOpacity(0.4)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          elevation: _checkedStates[index] ? 3 : 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _checkedStates[index],
                                  onChanged: (val) {
                                    setState(() {
                                      _checkedStates[index] = val ?? false;
                                    });
                                  },
                                  activeColor: const Color(0xFF11998e),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: _checkedStates[index] ? Colors.black87 : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("Reg: $regNo • SPR: $sprNo"),
                                      Text("Dept: $dept • Acad Year: $academicYear • DOB: $dob"),
                                      Text("Email: $email"),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                      onPressed: () => _editStudent(index),
                                      tooltip: "Edit details",
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _removeStudent(index),
                                      tooltip: "Delete record",
                                    ),
                                  ],
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
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isImporting ? null : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Cancel"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isImporting ? null : _proceedImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11998e),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Proceed Import",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditStudentDialog extends StatefulWidget {
  final Map<String, dynamic> student;
  const EditStudentDialog({super.key, required this.student});

  @override
  State<EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<EditStudentDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController regCtrl;
  late final TextEditingController sprCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController deptCtrl;
  late final TextEditingController academicYearCtrl;
  DateTime? dob;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.student["fullName"] ?? "");
    regCtrl = TextEditingController(text: widget.student["studentId"] ?? "");
    sprCtrl = TextEditingController(text: widget.student["sprNo"] ?? "");
    emailCtrl = TextEditingController(text: widget.student["email"] ?? "");
    phoneCtrl = TextEditingController(text: widget.student["phone"] ?? "");
    deptCtrl = TextEditingController(text: widget.student["departmentName"] ?? "");
    academicYearCtrl = TextEditingController(text: widget.student["academicYear"] ?? "");
    if (widget.student["dateOfBirth"] != null) {
      try {
        dob = DateTime.parse(widget.student["dateOfBirth"]);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    regCtrl.dispose();
    sprCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    deptCtrl.dispose();
    academicYearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Student Details", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name")),
            TextField(controller: regCtrl, decoration: const InputDecoration(labelText: "Register No (reg_no)")),
            TextField(controller: sprCtrl, decoration: const InputDecoration(labelText: "SPR No (spr_no)")),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Phone",
                counterText: "",
              ),
            ),
            TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: "Department")),
            TextField(controller: academicYearCtrl, decoration: const InputDecoration(labelText: "Academic Year (e.g. 2024-2025)")),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dob == null
                      ? "No DOB Selected"
                      : "DOB: ${dob!.year}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dob ?? DateTime(2004),
                      firstDate: DateTime(1995),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        dob = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text("Select"),
                )
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            final updatedStudent = Map<String, dynamic>.from(widget.student);
            updatedStudent["fullName"] = nameCtrl.text.trim();
            updatedStudent["studentId"] = regCtrl.text.trim();
            updatedStudent["sprNo"] = sprCtrl.text.trim();
            updatedStudent["email"] = emailCtrl.text.trim();
            updatedStudent["phone"] = phoneCtrl.text.trim();
            updatedStudent["departmentName"] = deptCtrl.text.trim();
            updatedStudent["academicYear"] = academicYearCtrl.text.trim();
            if (dob != null) {
              updatedStudent["dateOfBirth"] = "${dob!.year}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}";
            }
            Navigator.pop(context, updatedStudent);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF11998e)),
          child: const Text("Apply", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
