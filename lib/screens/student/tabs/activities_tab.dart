import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:spdms_app/providers/xp_provider.dart';

class ActivitiesTab extends StatefulWidget {
  final String token;
  const ActivitiesTab({super.key, required this.token});

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  // Deep visual indigo/violet/slate theme colors
  final primaryColor = const Color(0xFF4F46E5);
  final darkColor = const Color(0xFF1E293B);

  // Simulation mode toggled via developer action
  bool isSimulationActive = false;

  // In-memory interactive stages dataset (Aligned to JJCET Master list)
  late List<Map<String, dynamic>> stages;
  bool isLoading = true;
  String studentId = "24IT077";

  @override
  void initState() {
    super.initState();
    _initializeData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileAndHistory();
    });
  }

  Future<void> _loadProfileAndHistory() async {
    setState(() => isLoading = true);
    try {
      // 1. Fetch profile to get studentId
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/auth/me"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            studentId = data["data"]["username"] ?? "24IT077";
          });
        }
      }
    } catch (e) {
      // ignore
    }

    try {
      // 2. Fetch history using XpProvider
      final xpProv = Provider.of<XpProvider>(context, listen: false);
      await xpProv.fetchHistory(studentId, widget.token);
    } catch (e) {
      // ignore
    }
    setState(() => isLoading = false);
  }

  void _initializeData() {
    stages = [
      {
        "id": 1,
        "name": "Stage 1: Foundational Discipline",
        "description": "Establish basic discipline requirements and code of conduct.",
        "substages": [
          {
            "name": "MUST",
            "threshold": 40,
            "activities": [
              {"name": "95% Attendance", "description": "Maintain above 95% attendance for a full calendar month.", "points": 30, "isDone": false},
              {"name": "Assignment On Time", "description": "Submit all laboratory and theory assignments on schedule.", "points": 10, "isDone": false},
            ]
          },
          {
            "name": "INDIVIDUAL",
            "threshold": 100,
            "activities": [
              {"name": "MS Word 5 pages", "description": "Complete MS Word document draft formatting.", "points": 50, "isDone": false},
              {"name": "MS Excel 1 sheet", "description": "Complete MS Excel datasheet formula task.", "points": 50, "isDone": false},
              {"name": "MS PowerPoint 10 slides", "description": "Complete MS PowerPoint 10-slide domain topic presentation.", "points": 50, "isDone": false},
              {"name": "Keyboard Typing 20 WPM", "description": "Achieve typing speed of 20 WPM.", "points": 20, "isDone": false},
            ]
          },
          {
            "name": "GROUP",
            "threshold": 90,
            "activities": [
              {"name": "Oral Presentation 2min", "description": "Deliver a 2-minute oral presentation in a group setting.", "points": 40, "isDone": false},
              {"name": "Resume First Draft", "description": "Draft the first version of your professional resume.", "points": 50, "isDone": false},
            ]
          }
        ]
      },
      {
        "id": 2,
        "name": "Stage 2: Advanced Participation",
        "description": "Participate actively in academic forums and college workshops.",
        "substages": [
          {
            "name": "MUST",
            "threshold": 175,
            "activities": [
              {"name": "Join/Initiate Club", "description": "Register or start a department/college club.", "points": 100, "isDone": false},
              {"name": "NPTEL Week 1 Complete", "description": "Complete the first week of NPTEL courses.", "points": 75, "isDone": false},
            ]
          },
          {
            "name": "INDIVIDUAL",
            "threshold": 130,
            "activities": [
              {"name": "Technical Workshop", "description": "Participate in a technical workshop.", "points": 50, "isDone": false},
              {"name": "Mock Interview", "description": "Attend the department placement mock interview.", "points": 80, "isDone": false},
            ]
          },
          {
            "name": "GROUP",
            "threshold": 120,
            "activities": [
              {"name": "Peer Teaching 30min", "description": "Conduct a 30-minute peer teaching session.", "points": 40, "isDone": false},
              {"name": "Mini Event Organised", "description": "Organize a department mini-event.", "points": 80, "isDone": false},
            ]
          }
        ]
      },
      {
        "id": 3,
        "name": "Stage 3: Professional Excellence",
        "description": "Represent the institution in state/national events and outreach camps.",
        "substages": [
          {
            "name": "MUST",
            "threshold": 400,
            "activities": [
              {"name": "Mini Project Demo Group", "description": "Successfully demonstrate your group mini-project.", "points": 300, "isDone": false},
              {"name": "Resume Final Version", "description": "Finalize your resume with project credentials.", "points": 100, "isDone": false},
            ]
          },
          {
            "name": "INDIVIDUAL",
            "threshold": 230,
            "activities": [
              {"name": "Mini Project Individual", "description": "Complete your individual project component.", "points": 150, "isDone": false},
              {"name": "Internship Application", "description": "Submit applications for corporate internships.", "points": 80, "isDone": false},
            ]
          },
          {
            "name": "GROUP",
            "threshold": 300,
            "activities": [
              {"name": "Hackathon Participation Group", "description": "Participate in an external hackathon event.", "points": 200, "isDone": false},
              {"name": "Final Oral Presentation", "description": "Complete the final placement oral presentation.", "points": 100, "isDone": false},
            ]
          }
        ]
      }
    ];
  }

  // Calculate current status of activity dynamically
  bool _isActivityDone(Map<String, dynamic> act, List<dynamic> history) {
    if (isSimulationActive) {
      return act["isDone"] == true;
    }
    final name = act["name"].toString().trim().toLowerCase();
    return history.any((tx) =>
        tx["status"] == "APPROVED" &&
        tx["activityName"].toString().trim().toLowerCase() == name);
  }

  // Calculate current accumulated score of a substage
  int _getSubstageScore(Map<String, dynamic> substage, List<dynamic> history) {
    int score = 0;
    final List<dynamic> activities = substage["activities"] ?? [];
    for (var act in activities) {
      if (_isActivityDone(act, history)) {
        score += act["points"] as int;
      }
    }
    return score;
  }

  // Check if a substage passes the threshold
  bool _isSubstagePassed(Map<String, dynamic> substage, List<dynamic> history) {
    final int score = _getSubstageScore(substage, history);
    final int threshold = substage["threshold"] ?? 0;
    return score >= threshold;
  }

  // Check if all substages of a stage pass thresholds
  bool _isStageFullyPassed(Map<String, dynamic> stage, List<dynamic> history) {
    final List<dynamic> substages = stage["substages"] ?? [];
    for (var sub in substages) {
      if (!_isSubstagePassed(sub, history)) {
        return false;
      }
    }
    return true;
  }

  // Toggles the activity completion status in simulation mode
  void _toggleActivity(int stageIndex, int substageIndex, int activityIndex, bool? value) {
    setState(() {
      stages[stageIndex]["substages"][substageIndex]["activities"][activityIndex]["isDone"] = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final xpProvider = Provider.of<XpProvider>(context);
    final history = xpProvider.history;

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Activities & Stages",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: darkColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Toggle Simulator Mode",
            icon: Icon(
              isSimulationActive ? Icons.lock_open_outlined : Icons.lock_outlined,
              color: isSimulationActive ? Colors.greenAccent : Colors.white,
            ),
            onPressed: () {
              setState(() {
                isSimulationActive = !isSimulationActive;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isSimulationActive 
                    ? "Teacher Simulation Mode Active! You can now check off activities." 
                    : "Student Read-Only Mode Restored."),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSimulationActive)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Teacher Simulation Active (Tap to approve marks)",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C2D12)),
                      ),
                    ),
                  ],
                ),
              ),

            Text(
              "Action Items & Thresholds",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You must meet the separate thresholds for MUST, INDIVIDUAL, and GROUP sections to unlock the next stage.",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: stages.length,
                itemBuilder: (context, stageIndex) {
                  final stage = stages[stageIndex];
                  
                  // Dynamically determine lock/unlock status of stages
                  bool isUnlocked = false;
                  if (stageIndex == 0) {
                    isUnlocked = true;
                  } else {
                    isUnlocked = _isStageFullyPassed(stages[stageIndex - 1], history);
                  }

                  // Count passed substages
                  int passedCount = 0;
                  final List<dynamic> subList = stage["substages"];
                  for (var sub in subList) {
                    if (_isSubstagePassed(sub, history)) passedCount++;
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isUnlocked ? Colors.grey.shade200 : Colors.grey.shade200.withOpacity(0.5),
                        width: isUnlocked ? 1.0 : 0.8,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    color: isUnlocked ? Colors.white : Colors.grey.shade50.withOpacity(0.8),
                    child: ExpansionTile(
                      enabled: isUnlocked,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUnlocked ? primaryColor.withOpacity(0.1) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                          color: isUnlocked ? primaryColor : Colors.grey.shade500,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        stage["name"],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? darkColor : Colors.grey.shade500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          isUnlocked 
                            ? "Substages Passed: $passedCount / ${subList.length}" 
                            : "Stage Locked",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: passedCount == subList.length ? Colors.green : (isUnlocked ? Colors.orange.shade700 : Colors.grey),
                          ),
                        ),
                      ),
                      childrenPadding: const EdgeInsets.all(16),
                      expandedAlignment: Alignment.topLeft,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage["description"],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),

                        // Render Substages (MUST, INDIVIDUAL, GROUP)
                        ...List.generate(stage["substages"].length, (subIndex) {
                          final substage = stage["substages"][subIndex];
                          final List<dynamic> activities = substage["activities"];
                          final int threshold = substage["threshold"] ?? 0;
                          final int score = _getSubstageScore(substage, history);
                          final bool isPassed = score >= threshold;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Substage Header with threshold/progress and badge
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      substage["name"],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: darkColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isPassed ? Colors.green.shade200 : Colors.red.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isPassed ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
                                            size: 14,
                                            color: isPassed ? Colors.green.shade700 : Colors.red.shade700,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "$score / $threshold pts",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isPassed ? Colors.green.shade800 : Colors.red.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              if (activities.isEmpty)
                                const Text("No activities allocated under this section.")
                              else
                                ...List.generate(activities.length, (actIndex) {
                                  final activity = activities[actIndex];
                                  final bool isDone = _isActivityDone(activity, history);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: isDone ? Colors.green.withOpacity(0.02) : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDone ? Colors.green.withOpacity(0.2) : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                                      child: Row(
                                        children: [
                                          // Status Icon or Interactive Checkbox (Simulation Mode)
                                          if (isSimulationActive)
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: isDone,
                                                onChanged: (val) => _toggleActivity(stageIndex, subIndex, actIndex, val),
                                                activeColor: Colors.green,
                                              ),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: isDone ? Colors.green.shade50 : Colors.amber.shade50,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isDone ? Icons.check_rounded : Icons.lock_clock,
                                                color: isDone ? Colors.green : Colors.amber.shade800,
                                                size: 16,
                                              ),
                                            ),
                                          const SizedBox(width: 14),

                                          // Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  activity["name"],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: isDone ? Colors.grey.shade500 : darkColor,
                                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  activity["description"],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDone ? Colors.grey.shade400 : Colors.grey.shade600,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          // Points badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDone ? Colors.grey.shade200 : primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "${activity["points"]} pts",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isDone ? Colors.grey.shade600 : primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          );
                        }),
                      ],
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
