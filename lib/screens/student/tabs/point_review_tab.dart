import 'package:spdms_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spdms_app/providers/xp_provider.dart';

class PointReviewTab extends StatefulWidget {
  final String token;
  const PointReviewTab({super.key, required this.token});

  @override
  State<PointReviewTab> createState() => _PointReviewTabState();
}

class _PointReviewTabState extends State<PointReviewTab> {
  bool isLoading = true;
  String studentId = "24IT077";
  int currentStage = 1;

  // Category Configuration
  final Map<String, Map<String, dynamic>> categoryConfig = {
    "ACADEMIC": {"color": Colors.blue, "priority": "HIGH", "decay": "Streak decays if broken ↺"},
    "SKILL": {"color": Colors.purple, "priority": "HIGH", "decay": "Permanent ✓"},
    "COMMUNICATION": {"color": Colors.indigo, "priority": "HIGH", "decay": "Permanent ✓"},
    "LEADERSHIP": {"color": Colors.amber, "priority": "MEDIUM-HIGH", "decay": "Permanent ✓"},
    "INNOVATION": {"color": Colors.orange, "priority": "HIGH", "decay": "Permanent ✓"},
    "PLACEMENT": {"color": Colors.green, "priority": "HIGH", "decay": "Permanent ✓"},
    "DISCIPLINE": {"color": Colors.red, "priority": "MEDIUM", "decay": "Resets if streak broken ↺"},
    "COMMUNITY": {"color": Colors.teal, "priority": "MEDIUM", "decay": "Resets per semester ↺"},
    "SPORTS": {"color": Colors.pink, "priority": "MEDIUM", "decay": "Permanent ✓"},
    "CULTURAL": {"color": Colors.cyan, "priority": "MEDIUM", "decay": "Permanent ✓"},
  };

  // Activity Master List
  final List<Map<String, dynamic>> activityMaster = [
    // Stage 1
    {"name": "95% Attendance", "xp": 30, "category": "ACADEMIC", "stage": 1, "cap": "cap 120/mo"},
    {"name": "Assignment On Time", "xp": 10, "category": "ACADEMIC", "stage": 1, "cap": "no cap"},
    {"name": "MS Word 5 pages", "xp": 50, "category": "SKILL", "stage": 1, "cap": "once"},
    {"name": "MS Excel 1 sheet", "xp": 50, "category": "SKILL", "stage": 1, "cap": "once"},
    {"name": "MS PowerPoint 10 slides", "xp": 50, "category": "SKILL", "stage": 1, "cap": "once"},
    {"name": "Oral Presentation 2min", "xp": 40, "category": "PLACEMENT", "stage": 1, "cap": "cap 120/mo"},
    {"name": "Resume First Draft", "xp": 50, "category": "PLACEMENT", "stage": 1, "cap": "once"},
    {"name": "Keyboard Typing 20 WPM", "xp": 20, "category": "SKILL", "stage": 1, "cap": "once"},
    {"name": "Duolingo 3-day Streak", "xp": 15, "category": "PLACEMENT", "stage": 1, "cap": "cap 45/mo"},
    {"name": "Newspaper Word of Day", "xp": 5, "category": "ACADEMIC", "stage": 1, "cap": "cap 25/wk"},
    {"name": "Domain Activity Report", "xp": 50, "category": "SKILL", "stage": 1, "cap": "cap 150/mo"},
    {"name": "Certificate Course", "xp": 100, "category": "SKILL", "stage": 1, "cap": "cap 200/sem"},

    // Stage 2
    {"name": "Join/Initiate Club", "xp": 100, "category": "LEADERSHIP", "stage": 2, "cap": "cap 100"},
    {"name": "Club Meeting Attended", "xp": 15, "category": "LEADERSHIP", "stage": 2, "cap": "cap 60/wk"},
    {"name": "Non-Tech Event Inside", "xp": 40, "category": "COMMUNITY", "stage": 2, "cap": "cap 80/mo"},
    {"name": "Non-Tech Event Outside", "xp": 80, "category": "COMMUNITY", "stage": 2, "cap": "cap 160/mo"},
    {"name": "NPTEL Week 1 Complete", "xp": 75, "category": "SKILL", "stage": 2, "cap": "cap 150/mo"},
    {"name": "Technical Workshop", "xp": 50, "category": "SKILL", "stage": 2, "cap": "cap 100/mo"},
    {"name": "Mock Interview", "xp": 80, "category": "PLACEMENT", "stage": 2, "cap": "cap 160 bi-wk"},
    {"name": "Peer Teaching 30min", "xp": 40, "category": "LEADERSHIP", "stage": 2, "cap": "cap 80 bi-wk"},
    {"name": "CoE Project Idea Group", "xp": 100, "category": "INNOVATION", "stage": 2, "cap": "cap 100/mo"},
    {"name": "Hackathon Registration Group", "xp": 60, "category": "INNOVATION", "stage": 2, "cap": "cap 60/mo"},
    {"name": "Mini Event Organised", "xp": 80, "category": "LEADERSHIP", "stage": 2, "cap": "cap 80/mo"},
    {"name": "NPTEL/Cert Course Enrolled", "xp": 150, "category": "SKILL", "stage": 2, "cap": "cap 150/sem"},

    // Stage 3
    {"name": "Mini Project Proposal", "xp": 100, "category": "INNOVATION", "stage": 3, "cap": "once"},
    {"name": "Mini Project Demo Group", "xp": 300, "category": "INNOVATION", "stage": 3, "cap": "end Month 3"},
    {"name": "Mini Project Individual", "xp": 150, "category": "INNOVATION", "stage": 3, "cap": "mid Month 3"},
    {"name": "External Technical Event", "xp": 150, "category": "INNOVATION", "stage": 3, "cap": "cap 300/mo"},
    {"name": "Hackathon Participation Group", "xp": 200, "category": "INNOVATION", "stage": 3, "cap": "cap 200/mo"},
    {"name": "Hackathon Winning Group", "xp": 400, "category": "INNOVATION", "stage": 3, "cap": "no cap"},
    {"name": "Research Paper Draft", "xp": 300, "category": "INNOVATION", "stage": 3, "cap": "end Month 3"},
    {"name": "Industry/Consultancy", "xp": 200, "category": "PLACEMENT", "stage": 3, "cap": "cap 200/grp"},
    {"name": "Resume Final Version", "xp": 100, "category": "PLACEMENT", "stage": 3, "cap": "once"},
    {"name": "Internship Application", "xp": 80, "category": "PLACEMENT", "stage": 3, "cap": "cap 160/mo"},
    {"name": "Final Oral Presentation", "xp": 100, "category": "PLACEMENT", "stage": 3, "cap": "once"},
    {"name": "All Streaks Maintained Bonus", "xp": 100, "category": "DISCIPLINE", "stage": 3, "cap": "end Month 3"},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileAndData();
  }

  Future<void> _loadProfileAndData() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/auth/me"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final resData = data["data"];
          setState(() {
            studentId = resData["username"] ?? "24IT077";
            currentStage = resData["stage"] ?? 1;
          });
        }
      }
    } catch (e) {
      // Fallback
    }

    final xpProv = Provider.of<XpProvider>(context, listen: false);
    await xpProv.fetchSummary(studentId, widget.token);
    await xpProv.fetchHistory(studentId, widget.token);
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final xpProvider = Provider.of<XpProvider>(context);

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
          ),
        ),
      );
    }

    // Check if streak bonuses are active (e.g. coding streak > 7)
    final codingStreak = xpProvider.streaks.firstWhere(
      (s) => s["streakType"] == "C_CODING",
      orElse: () => null,
    );
    final hasCodingBonus = codingStreak != null && (codingStreak["currentStreak"] ?? 0) >= 7 && !(codingStreak["isBroken"] ?? false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "XP Tracker",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section B: Active Streak Bonuses Banner
          if (hasCodingBonus)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.indigo.shade600,
              child: const Row(
                children: [
                  Text("🔥 ", style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      "7-Day Coding Streak Active — 2x XP all coding this week!",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Section A: Category Cards Row
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "XP Category Summary",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(height: 10),
          _buildCategoryCards(xpProvider.xpByCategory),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "XP Submission History",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(height: 8),

          // Section D: XP History List
          Expanded(
            child: _buildHistoryList(xpProvider.history),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEvidenceSubmitSheet(xpProvider),
        backgroundColor: const Color(0xFF4F46E5),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // Section A: Category Summary Cards Grid
  Widget _buildCategoryCards(Map<String, int> categories) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        children: categories.entries.map((entry) {
          final String cat = entry.key;
          final int val = entry.value;
          final config = categoryConfig[cat] ?? {"color": Colors.grey, "priority": "MEDIUM", "decay": "Permanent"};
          final Color color = config["color"];
          final String priority = config["priority"];
          final String decay = config["decay"];

          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cat,
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text(
                  "$val XP",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  decay,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 8, fontStyle: FontStyle.italic),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Section D: History List View
  Widget _buildHistoryList(List<dynamic> history) {
    if (history.isEmpty) {
      return const Center(
        child: Text("No XP logs found. Submit your first activity claim!"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final log = history[index];
        final String cat = log["category"] ?? "SKILL";
        final int points = log["xpPoints"] ?? 0;
        final bool isPositive = points > 0;
        final config = categoryConfig[cat.toUpperCase()] ?? {"color": Colors.grey};
        final Color catColor = config["color"];
        final String status = log["status"] ?? "APPROVED";

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Color Dot representing Category
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: catColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log["activityName"] ?? "",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            log["submittedAt"] != null ? log["submittedAt"].toString().split("T")[0] : "",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: "APPROVED".equalsIgnoreCase(status)
                                  ? Colors.green.withOpacity(0.12)
                                  : "REJECTED".equalsIgnoreCase(status)
                                      ? Colors.red.withOpacity(0.12)
                                      : Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: "APPROVED".equalsIgnoreCase(status)
                                    ? Colors.green
                                    : "REJECTED".equalsIgnoreCase(status)
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isPositive ? "+$points XP" : "$points XP",
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration: "REJECTED".equalsIgnoreCase(status) ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Section C: FAB Evidence submission modal
  void _showEvidenceSubmitSheet(XpProvider xpProvider) {
    String? selectedCategory;
    Map<String, dynamic>? selectedActivity;
    final evidenceDescController = TextEditingController();
    String? selectedFileName;
    int currentStep = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Filter activities based on the selected category and student stage
            final filteredActivities = activityMaster.where((act) {
              final catMatch = selectedCategory == null || act["category"] == selectedCategory;
              final stageMatch = act["stage"] <= currentStage;
              return catMatch && stageMatch;
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Submit Activity Evidence",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          "Step $currentStep of 4",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // STEP 1: Select Category
                    if (currentStep == 1) ...[
                      const Text("Select Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: selectedCategory,
                        hint: const Text("Choose a category"),
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: categoryConfig.keys.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedCategory = val;
                            selectedActivity = null; // Reset activity
                          });
                        },
                      ),
                    ],

                    // STEP 2: Select Activity
                    if (currentStep == 2) ...[
                      const Text("Select Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        dropdownColor: Colors.white,
                        value: selectedActivity,
                        hint: const Text("Choose an activity"),
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: filteredActivities.map((act) {
                          final String details = "${act['name']} (+${act['xp']} XP | ${act['cap']})";
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: act,
                            child: Text(details, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedActivity = val;
                          });
                        },
                      ),
                    ],

                    // STEP 3: Submit Evidence Description & File
                    if (currentStep == 3) ...[
                      const Text("Evidence Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: evidenceDescController,
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Enter evidence links or verification notes...",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Upload File Document", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'jpg', 'png', 'doc'],
                          );
                          if (result != null && result.files.single.name.isNotEmpty) {
                            setModalState(() {
                              selectedFileName = result.files.single.name;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.grey.shade800,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: Text(selectedFileName ?? "Select PDF/Photo Document"),
                      ),
                    ],

                    // STEP 4: Review and Submit
                    if (currentStep == 4) ...[
                      const Text("Claim Preview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Activity: ${selectedActivity?['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Category: $selectedCategory"),
                            const SizedBox(height: 4),
                            Text("Points to Earn: +${selectedActivity?['xp']} XP", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Evidence: ${evidenceDescController.text}"),
                            if (selectedFileName != null) ...[
                              const SizedBox(height: 4),
                              Text("Attachment: $selectedFileName", style: const TextStyle(color: Colors.indigo)),
                            ]
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    // Navigation Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (currentStep > 1)
                          TextButton(
                            onPressed: () => setModalState(() => currentStep--),
                            child: const Text("Back", style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        else
                          const SizedBox(),
                        ElevatedButton(
                          onPressed: () async {
                            if (currentStep == 1 && selectedCategory == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a category.")));
                              return;
                            }
                            if (currentStep == 2 && selectedActivity == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an activity.")));
                              return;
                            }
                            if (currentStep == 3 && evidenceDescController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please describe your evidence.")));
                              return;
                            }

                            if (currentStep < 4) {
                              setModalState(() => currentStep++);
                            } else {
                              // Submit
                              Navigator.pop(context);
                              final url = evidenceDescController.text.trim();
                              final success = await xpProvider.submitXpClaim(
                                widget.token,
                                selectedCategory!,
                                selectedActivity!["name"],
                                selectedActivity!["xp"],
                                url.isNotEmpty ? url : "Link uploaded",
                              );

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("XP claim submitted for approval!"), backgroundColor: Colors.green),
                                );
                                // Reload data
                                await xpProvider.fetchSummary(studentId, widget.token);
                                await xpProvider.fetchHistory(studentId, widget.token);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Failed to submit claim. try again."), backgroundColor: Colors.redAccent),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(currentStep == 4 ? "Submit for Approval" : "Next"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

extension StringExtension on String {
  bool equalsIgnoreCase(String other) {
    return toLowerCase() == other.toLowerCase();
  }
}
