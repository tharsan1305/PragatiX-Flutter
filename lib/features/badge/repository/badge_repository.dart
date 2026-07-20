import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spdms_app/core/config/api_config.dart';
import 'package:flutter/foundation.dart';

class BadgeRepository {
  Future<Map<String, dynamic>> fetchMyBadges(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/badges/student/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'data': data['data'] ?? []};
        }
        return {'success': false, 'message': data['message'] ?? 'Failed to load badges'};
      }
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchAllBadges(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/badges'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'data': data['data'] ?? []};
        }
        return {'success': false, 'message': data['message'] ?? 'Failed to load badges'};
      }
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitBadgeClaim(String token, String badgeName, String evidenceUrl) async {
    try {
      debugPrint('BadgeRepository: POST URL: ${ApiConfig.baseUrl}/api/v1/badges/submit');
      final bodyStr = jsonEncode({'badgeName': badgeName, 'evidenceUrl': evidenceUrl});
      debugPrint('BadgeRepository: Request Body: $bodyStr');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/badges/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: bodyStr,
      );
      
      debugPrint('BadgeRepository: Response Code: ${response.statusCode}');
      debugPrint('BadgeRepository: Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': 'Badge claim submitted successfully!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to claim badge'};
    } catch (e) {
      debugPrint('BadgeRepository: JSON Parsing/Network error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchTeacherPendingClaims(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/badges/pending'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'success': true, 'data': data['data'] ?? []};
        }
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch claims'};
      }
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> approveClaim(String token, int claimId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/badges/$claimId/approve'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': 'Badge claim approved successfully!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to approve claim'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectClaim(String token, int claimId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/badges/$claimId/reject'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': 'Badge claim rejected successfully!'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to reject claim'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
