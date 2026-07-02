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
}
