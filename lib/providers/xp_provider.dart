import 'package:spdms_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class XpProvider extends ChangeNotifier {
  Map<String, int> _xpByCategory = {};
  List<dynamic> _history = [];
  List<dynamic> _streaks = [];
  List<Map<String, dynamic>> _stages = [];
  bool _isLoading = false;

  Map<String, int> get xpByCategory => _xpByCategory;
  List<dynamic> get history => _history;
  List<dynamic> get streaks => _streaks;
  List<Map<String, dynamic>> get stages => _stages;
  bool get isLoading => _isLoading;

  int get totalXp => _xpByCategory.values.fold(0, (sum, val) => sum + val);

  Future<void> fetchSummary(String studentId, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/xp/$studentId/summary"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] != null) {
          final Map<String, dynamic> rawMap = data["data"];
          _xpByCategory = rawMap.map((key, val) => MapEntry(key, val as int));
        } else {
          _xpByCategory = {};
        }
      } else {
        _xpByCategory = {};
      }
    } catch (e) {
      _xpByCategory = {};
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchHistory(String studentId, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/xp/$studentId/history?page=0&size=50"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] != null) {
          _history = data["data"]["content"] ?? [];
        } else {
          _history = [];
        }
      } else {
        _history = [];
      }
    } catch (e) {
      _history = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchStreaks(String studentId, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/xp/$studentId/streaks"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] != null) {
          _streaks = data["data"] ?? [];
        } else {
          _streaks = [];
        }
      } else {
        _streaks = [];
      }
    } catch (e) {
      _streaks = [];
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
        Uri.parse("${ApiConfig.baseUrl}/api/v1/xp/submit"),
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
        bool success = data["success"] == true;
        if (success) {
           await fetchHistory("", token); // Reload history
           await fetchSummary("", token); // Reload summary
        }
        return success;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<void> fetchStages(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/students/stages"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final List<dynamic> fetchedStages = data["data"] ?? [];
          final List<Map<String, dynamic>> mapped = [];

          for (var st in fetchedStages) {
            final List<dynamic> fetchedSubgroups = st["subgroups"] ?? [];
            final List<Map<String, dynamic>> substages = [];

            bool allSubgroupsCompleted = true;
            String? stageCompletedDate;

            for (var sub in fetchedSubgroups) {
              final int threshold = sub["threshold"] ?? 0;
              final List<dynamic> activitiesList = sub["activities"] ?? [];
              
              int earnedXP = 0;
              int completedCount = 0;

              for (var act in activitiesList) {
                earnedXP += (act["earnedXP"] as num?)?.toInt() ?? 0;
                
                if (act["status"] == "COMPLETED") {
                  completedCount++;
                  
                  if (act["completedDate"] != null) {
                     if (stageCompletedDate == null || (act["completedDate"] as String).compareTo(stageCompletedDate) > 0) {
                        stageCompletedDate = act["completedDate"];
                     }
                  }
                }
              }

              if (earnedXP < threshold && threshold > 0) {
                allSubgroupsCompleted = false;
              }

              substages.add({
                "name": sub["name"],
                "threshold": threshold,
                "earnedXP": earnedXP,
                "completedCount": completedCount,
                "totalCount": activitiesList.length,
                "activities": activitiesList,
              });
            }
            
            if (substages.isEmpty) allSubgroupsCompleted = false;

            mapped.add({
              "id": st["id"],
              "name": st["name"],
              "description": st["description"] ?? "",
              "displayOrder": st["displayOrder"] ?? 0,
              "stageStatus": st["stageStatus"] ?? "LOCKED_BEFORE_START",
              "startDateTime": st["startDateTime"],
              "isStageCompleted": allSubgroupsCompleted,
              "stageCompletedDate": stageCompletedDate,
              "substages": substages,
            });
          }

          mapped.sort((a, b) {
            final num aOrder = num.tryParse(a["displayOrder"]?.toString() ?? "0") ?? 0;
            final num bOrder = num.tryParse(b["displayOrder"]?.toString() ?? "0") ?? 0;
            return aOrder.compareTo(bOrder);
          });

          _stages = mapped;
        } else {
          _stages = [];
        }
      } else {
        _stages = [];
      }
    } catch (e) {
      debugPrint("Error fetching stages: $e");
      _stages = [];
    }
    _isLoading = false;
    notifyListeners();
  }
}
