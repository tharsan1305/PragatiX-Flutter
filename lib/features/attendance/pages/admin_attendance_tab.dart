import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:spdms_app/core/utils/api_client.dart' as http;
import 'package:spdms_app/core/config/api_config.dart';
import 'package:spdms_app/core/di/service_locator.dart';
import 'package:spdms_app/features/auth/providers/auth_provider.dart';
import '../models/admin_attendance_summary.dart';
import '../services/attendance_service.dart';

class AdminAttendanceTab extends StatefulWidget {
  const AdminAttendanceTab({Key? key}) : super(key: key);

  @override
  State<AdminAttendanceTab> createState() => _AdminAttendanceTabState();
}

class _AdminAttendanceTabState extends State<AdminAttendanceTab> with SingleTickerProviderStateMixin {
  final AttendanceService _service = AttendanceService();
  
  DateTime _selectedDate = DateTime.now();
  int _selectedPeriod = 1;
  int? _yearId;
  int? _departmentId;
  int? _sectionId;
  
  List<dynamic> _years = [];
  List<dynamic> _departments = [];
  List<dynamic> _sections = [];
  
  AdminAttendanceSummary? _summary;
  bool _isLoading = false;
  bool _isLoadingLookups = true;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final token = getIt<AuthProvider>().token ?? '';
      final headers = {'Authorization': 'Bearer $token'};
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/years'), headers: headers),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/departments'), headers: headers),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/sections'), headers: headers),
      ]);

      if (!mounted) return;

      setState(() {
        _years = jsonDecode(results[0].body)['data'] ?? [];
        _departments = jsonDecode(results[1].body)['data'] ?? [];
        _sections = jsonDecode(results[2].body)['data'] ?? [];
        
        if (_years.isNotEmpty) _yearId = _years.first['id'];
        if (_departments.isNotEmpty) _departmentId = _departments.first['id'];
        
        _isLoadingLookups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLookups = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading filters: $e')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    if (_yearId == null || _departmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Year and Department')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final summary = await _service.getAdminSummary(
          dateStr, _selectedPeriod, _yearId!, _departmentId!, sectionId: _sectionId);
      setState(() {
        _summary = summary;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading summary: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Attendance Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoadingLookups 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                const Divider(),
                if (_isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (_summary != null)
                  Expanded(child: _buildDashboardContent())
                else
                  const Expanded(child: Center(child: Text('Select filters and load dashboard'))),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    final filteredSections = _sections.where((s) => s['departmentId'] == _departmentId || s['department']?['id'] == _departmentId).toList();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: (_yearId != null && _years.any((y) => y['id'] == _yearId)) ? _yearId : null,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items: _years.where((y) => y['id'] != null).map<DropdownMenuItem<int>>((y) {
                    return DropdownMenuItem<int>(
                      value: y['id'] as int,
                      child: Text(y['yearName']?.toString() ?? y['yearNo']?.toString() ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _yearId = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: (_departmentId != null && _departments.any((d) => d['id'] == _departmentId)) ? _departmentId : null,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: _departments.where((d) => d['id'] != null).map<DropdownMenuItem<int>>((d) {
                    return DropdownMenuItem<int>(
                      value: d['id'] as int,
                      child: Text(d['name']?.toString() ?? d['deptName']?.toString() ?? d['code']?.toString() ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _departmentId = v;
                      final deptSections = _sections.where((s) => s['departmentId'] == _departmentId || s['department']?['id'] == _departmentId).toList();
                      if (deptSections.length == 1) {
                         _sectionId = deptSections.first['id'];
                      } else {
                         _sectionId = null;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredSections.isNotEmpty)
            DropdownButtonFormField<int?>(
              value: (_sectionId != null && filteredSections.any((s) => s['id'] == _sectionId)) ? _sectionId : null,
              decoration: const InputDecoration(labelText: 'Section (Optional)'),
              items: [
                if (filteredSections.length > 1)
                  const DropdownMenuItem<int?>(value: null, child: Text('All Sections')),
                ...filteredSections.where((s) => s['id'] != null).map<DropdownMenuItem<int>>((s) {
                  return DropdownMenuItem<int>(
                    value: s['id'] as int,
                    child: Text(s['sectionName']?.toString() ?? 'Unknown'),
                  );
                }).toList(),
              ],
              onChanged: (v) => setState(() => _sectionId = v),
            )
          else if (_departmentId != null)
             const Align(
               alignment: Alignment.centerLeft, 
               child: Text('All Students', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
             ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context, 
                      initialDate: _selectedDate, 
                      firstDate: DateTime(2020), 
                      lastDate: DateTime.now()
                    );
                    if (d != null) setState(() => _selectedDate = d);
                  },
                ),
              ),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(labelText: 'Period'),
                  items: List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('Period ${i + 1}'))),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPeriod = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _fetchSummary,
            child: const Text('Load Dashboard'),
          )
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Total Students', _summary!.totalStudents.toString(), Colors.blue),
              _buildStatCard('Present', _summary!.totalPresent.toString(), Colors.green),
              _buildStatCard('Absent', _summary!.totalAbsent.toString(), Colors.red),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E293B),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Present Students'),
            Tab(text: 'Absent Students'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStudentList(_summary!.presentStudents, Colors.green),
              _buildStudentList(_summary!.absentStudents, Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList(List<dynamic> students, Color statusColor) {
    if (students.isEmpty) {
      return const Center(child: Text('No students in this category.'));
    }
    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.2),
            child: Icon(Icons.person, color: statusColor),
          ),
          title: Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(s.registerNumber),
        );
      },
    );
  }
}
