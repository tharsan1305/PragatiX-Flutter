import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spdms_app/core/config/api_config.dart';
import '../models/activity_model.dart';

// Color Palette Constants
const Color _primary = Color(0xFFEA4335);
const Color _dark = Color(0xFF1E293B);
const Color _bg = Color(0xFFF8FAFC);

// Helper function to build year matching aliases
List<String> _getYearAliases(dynamic selectedYear) {
  final yearName = selectedYear['yearName']?.toString()?.trim()?.toLowerCase() ?? '';
  final yearNo = (selectedYear['yearNo'] as num?)?.toInt() ?? -1;

  final List<String> aliases = [];
  if (yearName.isNotEmpty) {
    aliases.add(yearName);
  }
  if (yearNo != -1) {
    aliases.add(yearNo.toString());
    if (yearNo == 1) {
      aliases.addAll(["i", "first", "1st", "1"]);
    } else if (yearNo == 2) {
      aliases.addAll(["ii", "second", "2nd", "2"]);
    } else if (yearNo == 3) {
      aliases.addAll(["iii", "third", "3rd", "3"]);
    } else if (yearNo == 4) {
      aliases.addAll(["iv", "fourth", "4th", "4"]);
    }
  }
  return aliases.map((e) => e.trim().toLowerCase()).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 1: Year Selection Page (Entry Point)
// ─────────────────────────────────────────────────────────────────────────────
class AdminActivityDetailPage extends StatefulWidget {
  final String token;
  final ActivityModel activity;
  final int subgroupId;

  const AdminActivityDetailPage({
    super.key,
    required this.token,
    required this.activity,
    required this.subgroupId,
  });

  @override
  State<AdminActivityDetailPage> createState() => _AdminActivityDetailPageState();
}

class _AdminActivityDetailPageState extends State<AdminActivityDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> allYears = [];
  List<dynamic> allDepts = [];
  List<dynamic> allStudents = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final headers = {"Authorization": "Bearer ${widget.token}"};
      
      final results = await Future.wait([
        http.get(Uri.parse("${ApiConfig.baseUrl}/api/v1/admin/years"), headers: headers),
        http.get(Uri.parse("${ApiConfig.baseUrl}/api/v1/admin/departments"), headers: headers),
        http.get(Uri.parse("${ApiConfig.baseUrl}/api/v1/students?page=0&size=2000&sortBy=fullName"), headers: headers),
      ]);

      if (results[0].statusCode != 200 || results[1].statusCode != 200 || results[2].statusCode != 200) {
        throw Exception("Failed to load metadata from backend.");
      }

      final yearsData = jsonDecode(results[0].body);
      final deptsData = jsonDecode(results[1].body);
      final studentsData = jsonDecode(results[2].body);

      if (yearsData["success"] == true && deptsData["success"] == true && studentsData["success"] == true) {
        setState(() {
          allYears = yearsData["data"] ?? [];
          allDepts = deptsData["data"] ?? [];
          allStudents = studentsData["data"]["content"] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception("Backend returned success=false for lookup queries.");
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          widget.activity.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActivityHeaderCard(widget.activity),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          "Select Year",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _dark),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: allYears.length,
                        itemBuilder: (ctx, index) {
                          final year = allYears[index];
                          final yearName = year['yearName'] ?? 'Unknown Year';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminActivityDeptSelectionPage(
                                      token: widget.token,
                                      activity: widget.activity,
                                      subgroupId: widget.subgroupId,
                                      selectedYear: year,
                                      allYears: allYears,
                                      allDepts: allDepts,
                                      allStudents: allStudents,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _primary.withValues(alpha: 0.1),
                                      child: const Icon(Icons.calendar_today, color: _primary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        yearName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _dark),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _dark),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAllData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2: Department Selection Page
// ─────────────────────────────────────────────────────────────────────────────
class AdminActivityDeptSelectionPage extends StatelessWidget {
  final String token;
  final ActivityModel activity;
  final int subgroupId;
  final dynamic selectedYear;
  final List<dynamic> allYears;
  final List<dynamic> allDepts;
  final List<dynamic> allStudents;

  const AdminActivityDeptSelectionPage({
    super.key,
    required this.token,
    required this.activity,
    required this.subgroupId,
    required this.selectedYear,
    required this.allYears,
    required this.allDepts,
    required this.allStudents,
  });

  @override
  Widget build(BuildContext context) {
    final yearName = selectedYear['yearName'] ?? '';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          activity.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _dark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumbHeader(yearName),
            _buildActivityHeaderCard(activity),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "Select Department",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _dark),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allDepts.length,
              itemBuilder: (ctx, index) {
                final dept = allDepts[index];
                final deptName = dept['name'] ?? 'Unknown Department';
                final deptCode = dept['code'] ?? '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _handleDeptSelection(context, dept),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            child: const Icon(Icons.account_balance, color: Colors.blue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deptName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _dark),
                                ),
                                if (deptCode.toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    deptCode.toString(),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeptSelection(BuildContext context, dynamic dept) {
    final deptName = dept['name']?.toString()?.trim()?.toLowerCase() ?? '';
    final yearAliases = _getYearAliases(selectedYear);

    // Filter students by Year & Department to check for sections
    final filtered = allStudents.where((s) {
      final sYear = s['year']?.toString()?.trim()?.toLowerCase() ?? '';
      final sDept = s['departmentName']?.toString()?.trim()?.toLowerCase() ?? '';
      return yearAliases.contains(sYear) && sDept == deptName;
    }).toList();

    final uniqueSections = filtered
        .map((s) => s['section']?.toString()?.trim() ?? '')
        .where((sec) => sec.isNotEmpty)
        .toSet()
        .toList();

    if (uniqueSections.isNotEmpty) {
      // Navigate to Section Selection Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminActivitySectionSelectionPage(
            token: token,
            activity: activity,
            subgroupId: subgroupId,
            selectedYear: selectedYear,
            selectedDept: dept,
            sectionsList: uniqueSections,
            allStudents: allStudents,
          ),
        ),
      );
    } else {
      // No sections exist, directly route to Student Points allocation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminActivityStudentPointsPage(
            token: token,
            activity: activity,
            subgroupId: subgroupId,
            selectedYear: selectedYear,
            selectedDept: dept,
            selectedSection: null,
            allStudents: allStudents,
          ),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 3: Section Selection Page
// ─────────────────────────────────────────────────────────────────────────────
class AdminActivitySectionSelectionPage extends StatelessWidget {
  final String token;
  final ActivityModel activity;
  final int subgroupId;
  final dynamic selectedYear;
  final dynamic selectedDept;
  final List<String> sectionsList;
  final List<dynamic> allStudents;

  const AdminActivitySectionSelectionPage({
    super.key,
    required this.token,
    required this.activity,
    required this.subgroupId,
    required this.selectedYear,
    required this.selectedDept,
    required this.sectionsList,
    required this.allStudents,
  });

  @override
  Widget build(BuildContext context) {
    final yearName = selectedYear['yearName'] ?? '';
    final deptName = selectedDept['name'] ?? '';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          activity.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _dark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumbHeader("$yearName  >  $deptName"),
            _buildActivityHeaderCard(activity),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "Select Section",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _dark),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sectionsList.length,
              itemBuilder: (ctx, index) {
                final section = sectionsList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminActivityStudentPointsPage(
                            token: token,
                            activity: activity,
                            subgroupId: subgroupId,
                            selectedYear: selectedYear,
                            selectedDept: selectedDept,
                            selectedSection: section,
                            allStudents: allStudents,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.teal.withValues(alpha: 0.1),
                            child: const Icon(Icons.group_work, color: Colors.teal),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Section $section",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _dark),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 4: Student Points Allocation Page
// ─────────────────────────────────────────────────────────────────────────────
class AdminActivityStudentPointsPage extends StatefulWidget {
  final String token;
  final ActivityModel activity;
  final int subgroupId;
  final dynamic selectedYear;
  final dynamic selectedDept;
  final String? selectedSection;
  final List<dynamic> allStudents;

  const AdminActivityStudentPointsPage({
    super.key,
    required this.token,
    required this.activity,
    required this.subgroupId,
    required this.selectedYear,
    required this.selectedDept,
    this.selectedSection,
    required this.allStudents,
  });

  @override
  State<AdminActivityStudentPointsPage> createState() => _AdminActivityStudentPointsPageState();
}

class _AdminActivityStudentPointsPageState extends State<AdminActivityStudentPointsPage> {
  String _searchQuery = '';
  final Set<int> _awardedStudentIds = {};
  late List<dynamic> localStudentsList;

  @override
  void initState() {
    super.initState();
    localStudentsList = List.from(widget.allStudents);
  }

  List<dynamic> getFilteredStudents() {
    final deptName = widget.selectedDept['name']?.toString()?.trim()?.toLowerCase() ?? '';
    final yearAliases = _getYearAliases(widget.selectedYear);

    final filtered = localStudentsList.where((s) {
      final sYear = s['year']?.toString()?.trim()?.toLowerCase() ?? '';
      final sDept = s['departmentName']?.toString()?.trim()?.toLowerCase() ?? '';

      final matchesYear = yearAliases.contains(sYear);
      final matchesDept = sDept == deptName;

      if (!matchesYear || !matchesDept) return false;

      if (widget.selectedSection != null) {
        final sSection = s['section']?.toString()?.trim() ?? '';
        return sSection.toLowerCase() == widget.selectedSection!.toLowerCase();
      }

      return true;
    }).toList();

    if (_searchQuery.isEmpty) return filtered;
    final q = _searchQuery.toLowerCase();
    return filtered.where((s) {
      final name = (s['fullName'] ?? '').toString().toLowerCase();
      final regNo = (s['regNo'] ?? '').toString().toLowerCase();
      final rollNo = (s['studentId'] ?? '').toString().toLowerCase();
      return name.contains(q) || regNo.contains(q) || rollNo.contains(q);
    }).toList();
  }

  Future<void> _submitAward(dynamic student, int xp, String remarks) async {
    final studentDbId = student['id'];
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/students/$studentDbId/adjust-points"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "points": xp,
          "reason": widget.activity.name,
          "subgroupId": widget.subgroupId
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          _awardedStudentIds.add(studentDbId);
          // Update local list points
          final idx = localStudentsList.indexWhere((s) => s['id'] == studentDbId);
          if (idx != -1) {
            localStudentsList[idx]['score'] = (localStudentsList[idx]['score'] ?? 0) + xp;
            localStudentsList[idx]['totalXp'] = (localStudentsList[idx]['totalXp'] ?? 0) + xp;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Awarded $xp XP to ${student['fullName']} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(data["message"] ?? "Failed to adjust points.");
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Award Failed'),
            ],
          ),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _openAwardDialog(dynamic student) {
    final defaultXp = int.tryParse(widget.activity.xp) ?? 0;
    final formKey = GlobalKey<FormState>();
    final xpController = TextEditingController(text: defaultXp.toString());
    final remarksController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Award XP Points',
          style: TextStyle(fontWeight: FontWeight.bold, color: _dark),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student: ${student['fullName']}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Activity: ${widget.activity.name}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: xpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'XP Points to Award',
                    border: OutlineInputBorder(),
                    hintText: 'Enter numerical value',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter XP';
                    }
                    final parsed = int.tryParse(val);
                    if (parsed == null) {
                      return 'Must be a valid integer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: remarksController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Remarks / Comments',
                    border: OutlineInputBorder(),
                    hintText: 'Optional notes...',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(ctx);
                _submitAward(
                  student,
                  int.parse(xpController.text),
                  remarksController.text,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yearName = widget.selectedYear['yearName'] ?? '';
    final deptName = widget.selectedDept['name'] ?? '';
    final secName = widget.selectedSection;

    String breadcrumb = "$yearName  >  $deptName";
    if (secName != null) {
      breadcrumb += "  >  Section $secName";
    }

    final filteredStudents = getFilteredStudents();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          widget.activity.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _dark,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBreadcrumbHeader(breadcrumb),
                      _buildActivityHeaderCard(widget.activity),
                      _buildSearchSection(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: Text(
                          "Students (${filteredStudents.length})",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _dark),
                        ),
                      ),
                    ],
                  ),
                ),
                if (filteredStudents.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, index) {
                          final student = filteredStudents[index];
                          final studentDbId = student['id'] as int;
                          final isAwarded = _awardedStudentIds.contains(studentDbId);

                          final rollNo = student['studentId'] ?? '';
                          final regNo = student['regNo']?.toString() ?? '';
                          final deptCode = student['departmentName'] ?? '';
                          final sSec = student['section']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isAwarded ? Colors.green.shade100 : Colors.red.shade100,
                                    radius: 22,
                                    child: Icon(
                                      Icons.person,
                                      color: isAwarded ? Colors.green : _primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student['fullName'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _dark),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Reg: $regNo | Roll: $rollNo',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          'Dept: $deptCode ${sSec.isNotEmpty ? "($sSec)" : ""}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${student['score'] ?? 0} Points',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                                      ),
                                      const SizedBox(height: 6),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isAwarded ? Colors.green : _primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                          minimumSize: const Size(60, 32),
                                        ),
                                        onPressed: () => _openAwardDialog(student),
                                        child: Text(isAwarded ? 'Re-Award' : 'Award XP', style: const TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: filteredStudents.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search student name, reg no or roll number...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No students found.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Reusable Card & Header Builders
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildBreadcrumbHeader(String path) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    color: _dark.withValues(alpha: 0.04),
    child: Row(
      children: [
        const Icon(Icons.home_outlined, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            path,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildActivityHeaderCard(ActivityModel act) {
  return Card(
    margin: const EdgeInsets.all(16),
    elevation: 1.5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  act.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _dark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  act.type,
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (act.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              act.description,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(Icons.star, 'XP: ${act.xp}'),
              _buildBadge(Icons.category, 'Category: ${act.xpCategory.isNotEmpty ? act.xpCategory : "Academic"}'),
              _buildBadge(Icons.timer, 'Freq: ${act.frequency}'),
              _buildBadge(Icons.security, 'Cap: ${act.cap}'),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildBadge(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}
