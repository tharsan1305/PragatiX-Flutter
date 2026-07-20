
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spdms_app/features/activity/utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity module – HTTP layer.
// Raw API calls only. No business logic. No model mapping.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityService {
  final String token;

  ActivityService(this.token);

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $token',
      };

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<dynamic>> fetchActivities(int subgroupId) async {
    final response = await http.get(
      Uri.parse(
          '${ActivityConstants.baseUrl}/subgroups/$subgroupId/activities'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception(
        'Failed to fetch activities (status ${response.statusCode})');
  }

  Future<List<dynamic>> fetchDepartments() async {
    final response = await http.get(
      Uri.parse('${ActivityConstants.baseUrl}/departments'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception('Failed to fetch departments (status ${response.statusCode})');
  }

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(
      Uri.parse('${ActivityConstants.baseUrl}/users'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception('Failed to fetch users (status ${response.statusCode})');
  }

  Future<List<dynamic>> fetchClassCoordinators() async {
    final response = await http.get(
      Uri.parse('${ActivityConstants.baseUrl}/departments/class-coordinators'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception('Failed to fetch class coordinators (status ${response.statusCode})');
  }

  Future<List<dynamic>> fetchCustomFrequencies() async {
    final response = await http.get(
      Uri.parse('${ActivityConstants.baseUrl}/frequencies/custom'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception('Failed to fetch custom frequencies (status ${response.statusCode})');
  }

  Future<Map<String, dynamic>> createCustomFrequency(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ActivityConstants.baseUrl}/frequencies/custom'),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      }
      throw Exception(data['message'] ?? 'Failed to create custom frequency');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(data['message'] ?? 'Failed to create custom frequency (status ${response.statusCode})');
  }

  Future<Map<String, dynamic>> createActivity(
      int subgroupId, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(
          '${ActivityConstants.baseUrl}/subgroups/$subgroupId/activities'),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(data['message'] ?? 'Failed to create activity');
  }

  Future<Map<String, dynamic>> updateActivity(
      int activityId, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${ActivityConstants.baseUrl}/activities/$activityId'),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(data['message'] ?? 'Failed to update activity');
  }

  Future<void> deleteActivity(int activityId) async {
    final response = await http.delete(
      Uri.parse('${ActivityConstants.baseUrl}/activities/$activityId'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to delete activity (status ${response.statusCode})');
    }
  }

  Future<List<dynamic>> fetchSections() async {
    final response = await http.get(
      Uri.parse('${ActivityConstants.baseUrl}/sections'),
      headers: _authHeaders,
    );
    debugPrint('DEBUG_LOG: fetchSections API Response status: ${response.statusCode}');
    debugPrint('DEBUG_LOG: fetchSections API Response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception('Failed to fetch sections (status ${response.statusCode})');
  }

  Future<Map<String, dynamic>> assignActivity(
      int activityId, int? sectionId, int teacherId) async {
    final response = await http.post(
      Uri.parse('${ActivityConstants.baseUrl}/activities/$activityId/assign'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'sectionId': sectionId,
        'teacherId': teacherId,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(data['message'] ?? 'Failed to assign activity');
  }

  Future<void> saveAssignments(
      int activityId, bool globalEnabled, List<Map<String, dynamic>> assignments, {bool ccEnabled = false}) async {
    final response = await http.post(
      Uri.parse('${ActivityConstants.baseUrl}/activities/$activityId/assign'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'globalEnabled': globalEnabled,
        'ccEnabled': ccEnabled,
        'assignments': assignments,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to save assignments');
    }
  }

  Future<List<dynamic>> fetchMyActivities() async {
    final response = await http.get(
      Uri.parse('${ActivityConstants.baseUrl}/my-activities'),
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['data'] as List?) ?? [];
      }
    }
    throw Exception('Failed to fetch my activities (status ${response.statusCode})');
  }

  Future<Map<String, dynamic>> fetchExecutionStudents(int activityId, {String? year, int? departmentId, int? sectionId}) async {
    final rootUrl = ActivityConstants.baseUrl.replaceAll('/admin', '');
    
    // Build query parameters
    final Map<String, String> queryParams = {};
    if (year != null && year.isNotEmpty) queryParams['year'] = year;
    if (departmentId != null) queryParams['departmentId'] = departmentId.toString();
    if (sectionId != null) queryParams['sectionId'] = sectionId.toString();
    
    final uri = Uri.parse('$rootUrl/my-activities/$activityId/students').replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: _authHeaders,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['message'] ?? 'Failed to load execution students');
  }

  Future<void> awardXp({
    required int regNo,
    required int activityId,
    required int assignmentId,
    required int xp,
    required String remarks,
    String result = 'PASS',
  }) async {
    final rootUrl = ActivityConstants.baseUrl.replaceAll('/admin', '');
    final response = await http.post(
      Uri.parse('$rootUrl/student-xp/award'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'regNo': regNo,
        'activityId': activityId,
        'assignmentId': assignmentId,
        'xp': xp,
        'remarks': remarks,
        'result': result,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }
    throw Exception(data['message'] ?? 'Failed to award XP');
  }
}
