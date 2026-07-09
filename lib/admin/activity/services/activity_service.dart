import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

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

  Future<Map<String, dynamic>> fetchExecutionStudents(int activityId) async {
    final rootUrl = ActivityConstants.baseUrl.replaceAll('/admin', '');
    final response = await http.get(
      Uri.parse('$rootUrl/my-activities/$activityId/students'),
      headers: _authHeaders,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['message'] ?? 'Failed to load execution students');
  }

  Future<void> awardXp({
    required int studentId,
    required int activityId,
    required int assignmentId,
    required int xp,
    required String remarks,
  }) async {
    final rootUrl = ActivityConstants.baseUrl.replaceAll('/admin', '');
    final response = await http.post(
      Uri.parse('$rootUrl/student-xp/award'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'studentId': studentId,
        'activityId': activityId,
        'assignmentId': assignmentId,
        'xp': xp,
        'remarks': remarks,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }
    throw Exception(data['message'] ?? 'Failed to award XP');
  }
}
