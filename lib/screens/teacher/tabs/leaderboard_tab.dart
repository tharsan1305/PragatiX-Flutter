import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LeaderboardTab extends StatefulWidget {
  final String token;
  const LeaderboardTab({super.key, required this.token});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  List<dynamic> leaderboardList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/students?page=0&size=100&sortBy=fullName"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final List<dynamic> list = data["data"]["content"] ?? [];
          list.sort((a, b) => (b["score"] ?? 0).compareTo(a["score"] ?? 0));
          setState(() {
            leaderboardList = list;
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Catch
    }

    setState(() {
      leaderboardList = [
        {"studentId": "24CS036", "fullName": "Sharugesh", "departmentName": "CSE", "score": 85},
        {"studentId": "22IT045", "fullName": "Rahul Kumar", "departmentName": "IT", "score": 45}
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Leaderboard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Student Standings (Sorted by Discipline Score)",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: leaderboardList.length,
                      itemBuilder: (context, index) {
                        final s = leaderboardList[index];
                        final String name = s["fullName"] ?? '';
                        final String regNo = s["studentId"] ?? '';
                        final String dept = s["departmentName"] ?? '';
                        final int score = s["score"] ?? 0;
                        final rank = index + 1;

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: rank == 1
                                    ? Colors.amber.withOpacity(0.15)
                                    : (rank == 2 ? Colors.blueGrey.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "#$rank",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: rank == 1 ? Colors.amber.shade800 : Colors.black87,
                                ),
                              ),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("$regNo • $dept"),
                            trailing: Text(
                              "$score pts",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF11998e)),
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
