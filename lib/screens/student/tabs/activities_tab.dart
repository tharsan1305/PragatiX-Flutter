import 'package:flutter/material.dart';

class ActivitiesTab extends StatefulWidget {
  final String token;
  const ActivitiesTab({super.key, required this.token});

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ProfileTabState {} // dummy placeholder for standard analysis

class _ActivitiesTabState extends State<ActivitiesTab> {
  // Deep visual indigo/violet/slate theme colors
  final primaryColor = const Color(0xFF4F46E5);
  final darkColor = const Color(0xFF1E293B);

  // Simulation mode toggled via developer action
  bool isSimulationActive = false;

  // In-memory interactive stages dataset
  late List<Map<String, dynamic>> stages;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    stages = [
      {
        "id": 1,
        "name": "Stage 1: Foundational Discipline",
        "description": "Establish basic discipline requirements and code of conduct.",
        "isUnlocked": true,
        "substages": [
          {
            "name": "MUST",
            "threshold": 30,
            "activities": [
              {"name": "Regular Attendance", "description": "Maintain above 90% attendance across all subjects.", "points": 20, "isDone": true},
              {"name": "Identity Card Verification", "description": "Always wear the college ID card while on campus.", "points": 10, "isDone": true},
            ]
          },
          {
            "name": "INDIVIDUAL",
            "threshold": 20,
            "activities": [
              {"name": "Dress Code Compliance", "description": "Follow the official college uniform/dress code policy.", "points": 15, "isDone": true},
              {"name": "Punctual Submission", "description": "Submit all laboratory and theory assignments on schedule.", "points": 15, "isDone": false},
            ]
          },
          {
            "name": "GROUP",
            "threshold": 20,
            "activities": [
              {"name": "Team Classroom Support", "description": "Contribute to class team cleanups and daily room organization.", "points": 10, "isDone": false},
              {"name": "Group Presentation Active Role", "description": "Contribute to and participate in group assignments and presentations.", "points": 15, "isDone": false},
            ]
          }
        ]
      },
      {
        "id": 2,
        "name": "Stage 2: Advanced Participation",
        "description": "Participate actively in academic forums and college workshops.",
        "isUnlocked": false,
        "substages": [
          {
            "name": "MUST",
            "threshold": 25,
            "activities": [
              {"name": "Lab Safety Procedures", "description": "Strictly follow standard laboratory safety guidelines and protocols.", "points": 25, "isDone": false},
            ]
          },
          {
            "name": "INDIVIDUAL",
            "threshold": 20,
            "activities": [
              {"name": "Library Discipline", "description": "Maintain silence and proper conduct in reading rooms.", "points": 10, "isDone": false},
              {"name": "Timely Class Entry", "description": "Ensure arrival in the classroom before class commencement.", "points": 10, "isDone": false},
            ]
          },
          {
            "name": "GROUP",
            "threshold": 30,
            "activities": [
              {"name": "Symposium Cooperation", "description": "Work actively with department peers to coordinate symposiums.", "points": 20, "isDone": false},
              {"name": "NPTEL Team Study Group", "description": "Participate in study groups for collaborative courses.", "points": 15, "isDone": false},
            ]
          }
        ]
      },
      {
        "id": 3,
        "name": "Stage 3: Professional Excellence",
        "description": "Represent the institution in state/national events and outreach camps.",
        "isUnlocked": false,
        "substages": [
          {
            "name": "MUST",
            "threshold": 50,
            "activities": [
              {"name": "Exam Hall Integrity", "description": "Adhere strictly to examination rules without code infractions.", "points": 50, "isDone": false},
            ]
          },
          {
            "name": "INDIVIDUAL",
            "threshold": 40,
            "activities": [
              {"name": "Technical Certification", "description": "Complete a certified technical course or certification program.", "points": 30, "isDone": false},
              {"name": "Junior Mentorship Support", "description": "Conduct peer mentoring sessions to assist junior students.", "points": 20, "isDone": false},
            ]
          },
          {
            "name": "GROUP",
            "threshold": 50,
            "activities": [
              {"name": "NSS Outreach Camp", "description": "Represent the department at community services outreach camps.", "points": 30, "isDone": false},
              {"name": "Project Exhibition Team", "description": "Participate as a group to showcase innovations at state level.", "points": 25, "isDone": false},
            ]
          }
        ]
      }
    ];
  }

  // Calculate current accumulated score of a substage
  int _getSubstageScore(Map<String, dynamic> substage) {
    int score = 0;
    final List<dynamic> activities = substage["activities"] ?? [];
    for (var act in activities) {
      if (act["isDone"] == true) {
        score += act["points"] as int;
      }
    }
    return score;
  }

  // Check if a substage passes the threshold
  bool _isSubstagePassed(Map<String, dynamic> substage) {
    final int score = _getSubstageScore(substage);
    final int threshold = substage["threshold"] ?? 0;
    return score >= threshold;
  }

  // Check if all substages of a stage pass thresholds
  bool _isStageFullyPassed(Map<String, dynamic> stage) {
    final List<dynamic> substages = stage["substages"] ?? [];
    for (var sub in substages) {
      if (!_isSubstagePassed(sub)) {
        return false;
      }
    }
    return true;
  }

  // Toggles the activity completion status and checks if stage unlocking is triggered
  void _toggleActivity(int stageIndex, int substageIndex, int activityIndex, bool? value) {
    setState(() {
      stages[stageIndex]["substages"][substageIndex]["activities"][activityIndex]["isDone"] = value ?? false;
      _checkAndUnlockNextStages();
    });
  }

  void _checkAndUnlockNextStages() {
    bool stage1Passed = _isStageFullyPassed(stages[0]);
    bool stage2Passed = _isStageFullyPassed(stages[1]);

    // Unlock/Lock Stage 2
    if (stage1Passed && !stages[1]["isUnlocked"]) {
      stages[1]["isUnlocked"] = true;
      _showUnlockDialog("Stage 2: Advanced Participation");
    } else if (!stage1Passed && stages[1]["isUnlocked"]) {
      stages[1]["isUnlocked"] = false;
      // Also lock stage 3 if stage 2 is locked
      stages[2]["isUnlocked"] = false;
    }

    // Unlock/Lock Stage 3
    if (stage1Passed && stage2Passed && !stages[2]["isUnlocked"]) {
      stages[2]["isUnlocked"] = true;
      _showUnlockDialog("Stage 3: Professional Excellence");
    } else if (!stage2Passed && stages[2]["isUnlocked"]) {
      stages[2]["isUnlocked"] = false;
    }
  }

  void _showUnlockDialog(String stageName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            const Text("New Stage Unlocked!"),
          ],
        ),
        content: Text(
          "Great job! All sub-stages (MUST, INDIVIDUAL, GROUP) have met their points threshold.\n\n\"$stageName\" is now unlocked.",
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Awesome", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  final bool isUnlocked = stage["isUnlocked"] ?? false;

                  // Count passed substages
                  int passedCount = 0;
                  final List<dynamic> subList = stage["substages"];
                  for (var sub in subList) {
                    if (_isSubstagePassed(sub)) passedCount++;
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
                          final int score = _getSubstageScore(substage);
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
                                  final bool isDone = activity["isDone"];

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
