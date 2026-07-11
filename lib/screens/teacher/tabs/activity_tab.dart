import 'package:spdms_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../admin/activity/pages/activity_list_page.dart';

class ActivityTab extends StatefulWidget {
  final String token;
  const ActivityTab({super.key, required this.token});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  List<dynamic> stagesList = [];
  bool isLoading = true;
  bool isCc = false;

  @override
  void initState() {
    super.initState();
    _fetchStages();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/auth/me"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final d = data["data"];
          final subs = d["subRoles"] as List<dynamic>? ?? [];
          setState(() {
            isCc = subs.map((e) => e.toString().toLowerCase()).contains('cc');
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchStages() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/admin/stages"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            stagesList = data["data"] ?? [];
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Catch
    }

    setState(() {
      stagesList = [
        {
          "id": 1,
          "name": "Stage 1",
          "description": "Initial threshold limits",
          "subgroups": [
            {"id": 1, "name": "must (individual)", "threshold": 30},
            {"id": 2, "name": "individual", "threshold": 20},
            {"id": 3, "name": "groups", "threshold": 50}
          ]
        }
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Department Activities",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "System Stages configured by Admin",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: stagesList.length,
                itemBuilder: (context, index) {
                  final stage = stagesList[index];
                  final String name = stage["name"] ?? '';
                  final String desc = stage["description"] ?? 'No description';
                  final List<dynamic> subgroups = stage["subgroups"] ?? [];

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const Divider(height: 24),
                          if (subgroups.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0),
                              child: Text(
                                "No subgroups configured for this stage.",
                                style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade500),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: subgroups.length,
                              itemBuilder: (context, subIndex) {
                                final sub = subgroups[subIndex];
                                final String subName = sub["name"] ?? '';
                                final int threshold = sub["threshold"] ?? 0;

                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ActivityListPage(
                                          token: widget.token,
                                          subgroupId: sub["id"] as int,
                                          subgroupName: subName,
                                          subgroupCategory: name,
                                          teachersList: const [],
                                          isCc: true,
                                          isMyActivitiesOnly: false,
                                          showAppBar: true,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 12),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(subName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14)),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "Threshold: $threshold pts",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF11998e)),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.chevron_right,
                                                size: 18, color: Colors.grey),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
    );
  }
}
