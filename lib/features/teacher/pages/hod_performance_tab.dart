import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/teacher/services/teacher_proxy_service.dart';
import 'package:pragatix/core/di/service_locator.dart';

class HodPerformanceTab extends StatefulWidget {
  const HodPerformanceTab({super.key});

  @override
  State<HodPerformanceTab> createState() => _HodPerformanceTabState();
}

class _HodPerformanceTabState extends State<HodPerformanceTab> {
  Map<String, dynamic> performanceData = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPerformance();
  }

  Future<void> _fetchPerformance() async {
    try {
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/students/department-performance',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          performanceData = data['data'] ?? {};
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = data['message'] ?? 'Failed to load metrics';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error connecting to server';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator()));
    }
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'HOD Performance Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E293B),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    final String deptName = performanceData['departmentName'] ?? 'Department';
    final double overallAvg =
        (performanceData['overallAverage'] as num?)?.toDouble() ?? 100.0;
    final int totalStudents =
        (performanceData['totalStudents'] as num?)?.toInt() ?? 0;
    final Map<String, dynamic> yearAvg =
        performanceData['yearWiseAverage'] ?? {};

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '$deptName HOD Dashboard',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchPerformance();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Department Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 36,
                            color: Color(0xFF11998e),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Total Students',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalStudents',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.stars,
                            size: 36,
                            color: Colors.amber,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Overall Avg Score',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            overallAvg.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Year-wise Average Discipline Score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            if (yearAvg.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No student records found in this department.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              ...yearAvg.entries.map((entry) {
                final double score = (entry.value as num).toDouble();
                Color barColor = const Color(0xFF11998e);
                if (score < 50) {
                  barColor = Colors.redAccent;
                } else if (score < 80) {
                  barColor = Colors.orangeAccent;
                }

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${score.toStringAsFixed(1)} / 100',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: score / 100.0,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
