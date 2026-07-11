import 'package:spdms_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PerformanceActivitiesTab extends StatefulWidget {
  final String token;
  final List<String> subRoles;
  const PerformanceActivitiesTab({super.key, required this.token, required this.subRoles});

  @override
  State<PerformanceActivitiesTab> createState() => _PerformanceActivitiesTabState();
}

class _PerformanceActivitiesTabState extends State<PerformanceActivitiesTab> {
  // Navigation Flow State
  // 0: Category Grid Selection
  // 1: Event List (filtered by category)
  // 2: Student Selection List & Award Screen
  int _currentFlowStep = 0;

  String? _selectedCategory;
  List<dynamic> _myActivities = [];
  bool _isLoadingActivities = false;

  dynamic _selectedEvent; // Activity representation
  List<dynamic> _eligibleStudents = [];
  bool _isLoadingStudents = false;
  int? _assignmentId;
  
  // Selection State
  final Set<int> _selectedStudentIds = {};
  bool _selectAll = false;
  final TextEditingController _remarksController = TextEditingController();
  bool _isAwarding = false;

  final Map<String, Map<String, dynamic>> _categoryStyles = {
    "ACADEMIC": {"color": Colors.blue, "icon": Icons.school_rounded, "label": "Academic"},
    "COMMUNICATION": {"color": Colors.indigo, "icon": Icons.chat_bubble_rounded, "label": "Communication"},
    "LEADERSHIP": {"color": Colors.amber, "icon": Icons.gavel_rounded, "label": "Leadership"},
    "INNOVATION": {"color": Colors.orange, "icon": Icons.lightbulb_rounded, "label": "Innovation"},
    "PLACEMENT": {"color": Colors.green, "icon": Icons.work_rounded, "label": "Placement"},
    "DISCIPLINE": {"color": Colors.red, "icon": Icons.verified_user_rounded, "label": "Discipline"},
    "SPORTS": {"color": Colors.pink, "icon": Icons.sports_soccer_rounded, "label": "Sports"},
    "COMMUNITY": {"color": Colors.teal, "icon": Icons.people_rounded, "label": "Community"},
    "SKILL": {"color": Colors.purple, "icon": Icons.psychology_rounded, "label": "Skill"},
    "CULTURAL": {"color": Colors.cyan, "icon": Icons.music_note_rounded, "label": "Cultural"},
  };

  @override
  void initState() {
    super.initState();
    _fetchMyActivities();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyActivities() async {
    setState(() {
      _isLoadingActivities = true;
    });
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/admin/my-activities"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            _myActivities = data["data"] ?? [];
          });
        }
      }
    } catch (_) {}
    setState(() {
      _isLoadingActivities = false;
    });
  }

  Future<void> _fetchStudentsForEvent(dynamic event) async {
    setState(() {
      _isLoadingStudents = true;
      _eligibleStudents = [];
      _selectedStudentIds.clear();
      _selectAll = false;
      _assignmentId = null;
    });
    try {
      final activityId = event["activityId"];
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/my-activities/$activityId/students"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            _eligibleStudents = data["data"]["students"] ?? [];
            final assignData = data["data"]["assignment"];
            _assignmentId = assignData != null ? (assignData["id"] as num?)?.toInt() : null;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data["message"] ?? "Failed to load students"),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error ${response.statusCode}: Failed to load students"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading students: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
      }
    }
  }

  Future<void> _submitAward() async {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one student"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isAwarding = true;
    });

    try {
      final body = {
        "studentIds": _selectedStudentIds.toList(),
        "activityId": _selectedEvent["activityId"],
        "assignmentId": _assignmentId ?? _selectedEvent["activityId"], 
        "remarks": _remarksController.text.trim(),
      };

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/student-xp/award/batch"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data["message"] ?? "XP Awarded successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          _remarksController.clear();
          setState(() {
            _currentFlowStep = 1;
            _selectedStudentIds.clear();
          });
          return;
        }
      }
      
      if (!mounted) return;
      final errorData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorData["message"] ?? "Failed to award XP"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error submitting batch award"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAwarding = false;
        });
      }
    }
  }

  void _onCategorySelected(String categoryKey) {
    setState(() {
      _selectedCategory = categoryKey;
      _currentFlowStep = 1;
    });
  }

  void _onEventSelected(dynamic event) {
    setState(() {
      _selectedEvent = event;
      _currentFlowStep = 2;
    });
    _fetchStudentsForEvent(event);
  }

  List<dynamic> get _filteredEvents {
    if (_selectedCategory == null) return [];
    return _myActivities.where((a) {
      final cat = a["xpCategory"]?.toString()?.toUpperCase() ?? "";
      return cat == _selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentFlowStep > 0) {
          setState(() {
            _currentFlowStep--;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentFlowStep == 0
                ? "Performance Activities"
                : (_currentFlowStep == 1
                    ? "${_categoryStyles[_selectedCategory]?['label']} Events"
                    : "${_selectedEvent?['name']}"),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: _currentFlowStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    setState(() {
                      _currentFlowStep--;
                    });
                  },
                )
              : null,
        ),
        body: _buildAwardXpTabBody(),
      ),
    );
  }

  Widget _buildAwardXpTabBody() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentFlowStep) {
      case 0:
        return _buildCategoryGrid();
      case 1:
        return _buildEventList();
      case 2:
        return _buildStudentListAndAward();
      default:
        return _buildCategoryGrid();
    }
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select XP Category to view predefined Events",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: _categoryStyles.keys.length,
              itemBuilder: (context, index) {
                final key = _categoryStyles.keys.elementAt(index);
                final style = _categoryStyles[key]!;
                final color = style["color"] as Color;
                final icon = style["icon"] as IconData;
                final label = style["label"] as String;

                final count = _myActivities.where((a) => (a["xpCategory"]?.toString()?.toUpperCase() ?? "") == key).length;

                return InkWell(
                  onTap: () => _onCategorySelected(key),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const Spacer(),
                        Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$count configured events",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final list = _filteredEvents;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              "No Events assigned under this category",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Predefined Event (${list.length} available)",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                final String name = item["name"] ?? "";
                final String desc = item["description"] ?? "No description";
                final String xp = item["xp"] ?? "0";

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        desc,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11998e).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$xp XP",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF11998e), fontSize: 13),
                      ),
                    ),
                    onTap: () => _onEventSelected(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentListAndAward() {
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_eligibleStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              "No students assigned to this section/department",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final String xpValue = _selectedEvent?["xp"] ?? "0";

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Students",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      "Award: $xpValue XP",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 13),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "Select All Students",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                value: _selectAll,
                activeColor: const Color(0xFF11998e),
                onChanged: (val) {
                  setState(() {
                    _selectAll = val ?? false;
                    if (_selectAll) {
                      _selectedStudentIds.addAll(_eligibleStudents.map((s) => s["id"] as int));
                    } else {
                      _selectedStudentIds.clear();
                    }
                  });
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _eligibleStudents.length,
            itemBuilder: (context, index) {
              final student = _eligibleStudents[index];
              final int studentId = student["id"] as int;
              final String name = student["fullName"] ?? "";
              final String studentIdStr = student["studentId"] ?? "";
              final isChecked = _selectedStudentIds.contains(studentId);

              return CheckboxListTile(
                value: isChecked,
                activeColor: const Color(0xFF11998e),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                subtitle: Text(
                  studentIdStr,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedStudentIds.add(studentId);
                    } else {
                      _selectedStudentIds.remove(studentId);
                      _selectAll = false;
                    }
                  });
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _remarksController,
                decoration: InputDecoration(
                  hintText: "Add optional description/remarks…",
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF11998e),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isAwarding ? null : _submitAward,
                  child: _isAwarding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          "Award XP to ${_selectedStudentIds.length} Students",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
