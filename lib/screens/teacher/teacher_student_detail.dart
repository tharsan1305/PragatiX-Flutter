import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TeacherStudentDetail extends StatefulWidget {
  final Map<String, dynamic> student;
  final String token;

  const TeacherStudentDetail({super.key, required this.student, required this.token});

  @override
  State<TeacherStudentDetail> createState() => _TeacherStudentDetailState();
}

class _TeacherStudentDetailState extends State<TeacherStudentDetail> {
  int currentScore = 0;
  List<dynamic> historyLogs = [];
  List<dynamic> stagesList = [];
  bool isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    currentScore = widget.student['score'] ?? 100;
    _fetchHistoryLogs();
    _fetchStages();
  }

  Future<void> _fetchHistoryLogs() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/students/${widget.student['id']}/discipline-logs"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            historyLogs = data["data"] ?? [];
            isLoadingHistory = false;
          });
          return;
        }
      }
    } catch (e) {
      // Catch
    }
    setState(() {
      isLoadingHistory = false;
    });
  }

  Future<void> _fetchStages() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/admin/stages"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            stagesList = data["data"] ?? [];
          });
        }
      }
    } catch (e) {
      // Catch
    }
  }

  Future<void> _changeScore(int points, String reason, int? subgroupId) async {
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/students/${widget.student['id']}/adjust-points"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "points": points,
          "reason": reason,
          "subgroupId": subgroupId
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          currentScore = data["data"]["score"] ?? currentScore;
          isLoadingHistory = true;
        });
        _fetchHistoryLogs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${points > 0 ? "Added" : "Deducted"} $points points successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? 'Failed to adjust points'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error adjusting points'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showAddPointsSheet() {
    _showPointsBottomSheet(true);
  }

  void _showDeductPointsSheet() {
    _showPointsBottomSheet(false);
  }

  void _showPointsBottomSheet(bool isAdding) {
    final reasons = isAdding
        ? [
            "Attendance Above 95% (+10)",
            "Placement Training (+15)",
            "Internship Completion (+20)",
            "Hackathon Winner (+25)",
            "Academic Topper (+30)",
            "Faculty Appreciation (+10)"
          ]
        : [
            "Late Arrival (-3)",
            "Missing ID Card (-2)",
            "Mobile Usage (-5)",
            "Misbehavior (-10)",
            "Proxy Attendance (-15)",
            "Ragging (-50)",
            "Severe Misconduct (-100)"
          ];

    int? selectedSubgroupId;
    String? selectedReason = reasons.first;
    final TextEditingController customReasonController = TextEditingController();

    // Flatten all subgroups across stages for the dropdown
    List<Map<String, dynamic>> allSubgroups = [];
    for (var stage in stagesList) {
      final List<dynamic> subs = stage["subgroups"] ?? [];
      for (var sub in subs) {
        allSubgroups.add({
          "id": sub["id"],
          "name": "${stage["name"]} - ${sub["name"]}",
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20.0,
            left: 20.0,
            right: 20.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAdding ? "Add Points" : "Deduct Points",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Activity Assignment Dropdown
              DropdownButtonFormField<int?>(
                value: selectedSubgroupId,
                decoration: const InputDecoration(
                  labelText: "Activity / Stage Assignment",
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text("General (No Activity Group)"),
                  ),
                  ...allSubgroups.map((sub) {
                    return DropdownMenuItem<int?>(
                      value: sub["id"],
                      child: Text(sub["name"]),
                    );
                  })
                ],
                onChanged: (val) {
                  selectedSubgroupId = val;
                },
              ),
              const SizedBox(height: 16),
              
              const Text("Select Reason & Value:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // Reasons List
              SizedBox(
                height: 150,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reasons.length,
                  itemBuilder: (context, index) {
                    final r = reasons[index];
                    return RadioListTile<String>(
                      title: Text(r),
                      value: r,
                      groupValue: selectedReason,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          selectedReason = val;
                        });
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              TextField(
                controller: customReasonController,
                decoration: const InputDecoration(
                  labelText: "Custom Reason (Overrides selected reason description)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final finalReason = customReasonController.text.trim().isNotEmpty
                        ? customReasonController.text.trim()
                        : selectedReason!;
                    
                    // Parse points value from selectedReason
                    final int val = int.parse(
                      selectedReason!.split(RegExp(r'[()]'))[1].replaceAll('+', '').replaceAll('-', '').trim(),
                    );
                    final points = val * (isAdding ? 1 : -1);

                    _changeScore(points, finalReason, selectedSubgroupId);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAdding ? Colors.green : Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isAdding ? "Add Points" : "Deduct Points",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 60),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.student['name'] ?? '',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("Reg No: ${widget.student['regNo'] ?? ''}"),
                      Text("Department: ${widget.student['dept'] ?? ''}"),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: Column(
                children: [
                  const Text("Current Discipline Score", 
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    "$currentScore",
                    style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold),
                  ),
                  const Text("Points", style: TextStyle(fontSize: 18)),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddPointsSheet,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Points"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 207, 212, 207),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDeductPointsSheet,
                    icon: const Icon(Icons.remove),
                    label: const Text("Deduct Points"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 211, 206, 206),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text("Score History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : historyLogs.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No discipline history logged for this student yet."),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: historyLogs.length,
                        itemBuilder: (context, index) {
                          final log = historyLogs[index];
                          final int pts = log["points"] ?? 0;
                          final String reason = log["reason"] ?? "No reason given";
                          final String recordedBy = log["recordedByName"] ?? "Faculty";
                          final String actName = log["subgroupName"] ?? "General";
                          final String dtStr = log["createdAt"] != null 
                              ? log["createdAt"].toString().replaceAll("T", " ").substring(0, 16) 
                              : "";

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: pts >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                child: Icon(
                                  pts >= 0 ? Icons.add_circle : Icons.remove_circle,
                                  color: pts >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(reason, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("By: $recordedBy • Act: $actName\nDate: $dtStr"),
                              trailing: Text(
                                pts >= 0 ? "+$pts" : "$pts",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: pts >= 0 ? Colors.green : Colors.red,
                                  fontSize: 16
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}