import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class XpProvider extends ChangeNotifier {
  Map<String, int> _xpByCategory = {
    "ACADEMIC": 0,
    "SKILL": 0,
    "LEADERSHIP": 0,
    "CAREER": 0,
    "INNOVATION": 0,
    "COMMUNITY": 0,
    "DISCIPLINE": 0,
  };
  List<dynamic> _history = [];
  List<dynamic> _streaks = [];
  bool _isLoading = false;

  Map<String, int> get xpByCategory => _xpByCategory;
  List<dynamic> get history => _history;
  List<dynamic> get streaks => _streaks;
  bool get isLoading => _isLoading;

  int get totalXp => _xpByCategory.values.fold(0, (sum, val) => sum + val);

  Future<void> fetchSummary(String studentId, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/xp/$studentId/summary"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] != null) {
          final Map<String, dynamic> rawMap = data["data"];
          _xpByCategory = rawMap.map((key, val) => MapEntry(key, val as int));
        }
      }
    } catch (e) {
      // Keep fallbacks
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchHistory(String studentId, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/xp/$studentId/history?page=0&size=50"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] != null) {
          _history = data["data"]["content"] ?? [];
        }
      }
    } catch (e) {
      // Fallback local mock history if backend is unreachable
      _history = [
        {
          "id": 1,
          "category": "SKILL",
          "activityName": "C Coding 5 problems",
          "xpPoints": 50,
          "submittedAt": DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          "status": "APPROVED"
        },
        {
          "id": 2,
          "category": "DISCIPLINE",
          "activityName": "Late entry to class",
          "xpPoints": -10,
          "submittedAt": DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          "status": "APPROVED"
        },
        {
          "id": 3,
          "category": "ACADEMIC",
          "activityName": "95% Attendance",
          "xpPoints": 30,
          "submittedAt": DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          "status": "APPROVED"
        }
      ];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchStreaks(String studentId, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/xp/$studentId/streaks"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] != null) {
          _streaks = data["data"] ?? [];
        }
      }
    } catch (e) {
      // Fallback local mock streaks
      _streaks = [
        {"streakType": "C_CODING", "currentStreak": 12, "isBroken": false},
        {"streakType": "MONDAY_JOURNAL", "currentStreak": 4, "isBroken": false},
        {"streakType": "LIBRARY", "currentStreak": 0, "isBroken": true},
      ];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitXpClaim(
    String token,
    String category,
    String activityName,
    int xpPoints,
    String evidenceUrl,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/xp/submit"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "category": category,
          "activityName": activityName,
          "xpPoints": xpPoints,
          "evidenceUrl": evidenceUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["success"] == true;
      }
    } catch (e) {
      // In offline/mock mode, simulate success
      return true;
    }
    return false;
  }
}
