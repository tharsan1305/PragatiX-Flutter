import 'package:spdms_app/features/auth/providers/auth_provider.dart';
import 'package:spdms_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:spdms_app/features/student/services/student_proxy_service.dart';
import 'package:provider/provider.dart';
import 'package:spdms_app/features/xp/providers/xp_provider.dart';
import 'package:spdms_app/core/di/service_locator.dart';
import 'package:spdms_app/features/attendance/providers/attendance_provider.dart';
import 'package:spdms_app/features/attendance/widgets/fire_streak_icon.dart';

class ActivitiesTab extends StatefulWidget {
  const ActivitiesTab({super.key, });

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
  String regNo = '24IT077';

  @override
  void initState() {
    super.initState();
    stages = [];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeData();
      await _loadProfileAndHistory();
    });
  }

  Future<void> _loadProfileAndHistory() async {
    setState(() => isLoading = true);
    try {
      // 1. Fetch profile to get regNo
      final response = await getIt<StudentProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'),
        headers: {'Authorization': 'Bearer ${context.read<AuthProvider>().token!}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            regNo = data['data']['username'] ?? '24IT077';
          });
        }
      }
    } catch (e) {
      // ignore
    }

    try {
      // 2. Fetch history using XpProvider
      if (!mounted) return;
      final xpProv = Provider.of<XpProvider>(context, listen: false);
      if (!mounted) return;
      await xpProv.fetchHistory(regNo, context.read<AuthProvider>().token!);
    } catch (e) {
      // ignore
    }
    setState(() => isLoading = false);
  }

  Future<void> _initializeData() async {
    try {
      final response = await getIt<StudentProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/stages'),
        headers: {'Authorization': 'Bearer ${context.read<AuthProvider>().token!}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> fetchedStages = data['data'] ?? [];
          final List<Map<String, dynamic>> mapped = [];

          for (var st in fetchedStages) {
            final List<dynamic> fetchedSubgroups = st['subgroups'] ?? [];
            final List<Map<String, dynamic>> substages = [];

            for (var sub in fetchedSubgroups) {
              final List<dynamic> activitiesList = sub['activities'] ?? [];

              substages.add({
                'name': sub['name'],
                'threshold': sub['threshold'] ?? 0,
                'activities': activitiesList,
              });
            }

            mapped.add({
              'id': st['id'],
              'name': st['name'],
              'description': st['description'] ?? '',
              'substages': substages,
              
              // Dynamic progress fields from backend
              'mustThreshold': st['mustThreshold'] ?? 0,
              'individualThreshold': st['individualThreshold'] ?? 0,
              'groupThreshold': st['groupThreshold'] ?? 0,
              'studentMustXp': st['studentMustXp'] ?? 0,
              'studentIndividualXp': st['studentIndividualXp'] ?? 0,
              'studentGroupXp': st['studentGroupXp'] ?? 0,
              'mustCompleted': st['mustCompleted'] ?? false,
              'individualCompleted': st['individualCompleted'] ?? false,
              'groupCompleted': st['groupCompleted'] ?? false,
              'mustRemaining': st['mustRemaining'] ?? 0,
              'individualRemaining': st['individualRemaining'] ?? 0,
              'groupRemaining': st['groupRemaining'] ?? 0,
              'overallCompletedSubgroups': st['overallCompletedSubgroups'] ?? 0,
              'overallTotalSubgroups': st['overallTotalSubgroups'] ?? 0,
              'overallPercentage': st['overallPercentage'] ?? 0.0,
            });
          }

          // Sort stages by id to guarantee sequential progression
          mapped.sort((a, b) => (a['id'] as num).compareTo(b['id'] as num));

          setState(() {
            stages = mapped;
          });
        }
      }
    } catch (e) {
      debugPrint('Error in _initializeData: $e');
    }
  }

  // Calculate current status of activity dynamically

  int _getSubstageScore(Map<String, dynamic> substage, List<dynamic> history) {
    if (isSimulationActive) {
      int score = 0;
      final List<dynamic> activities = substage['activities'] ?? [];
      for (var act in activities) {
        if (act['status'] == 'COMPLETED' || act['completed'] == true) {
          score += (act['rewardXp'] as num?)?.toInt() ?? 0;
        }
      }
      return score;
    }

    int score = 0;
    final List<dynamic> activities = substage['activities'] ?? [];
    
    for (var act in activities) {
        score += (act['awardedXp'] as num?)?.toInt() ?? 0;
    }
    return score;
  }

  // Check if a substage passes the threshold
  bool _isSubstagePassed(Map<String, dynamic> substage, List<dynamic> history) {
    final int score = _getSubstageScore(substage, history);
    final int threshold = substage['threshold'] ?? 0;
    return score >= threshold;
  }

  // Check if all substages of a stage pass thresholds
  bool _isStageFullyPassed(Map<String, dynamic> stage, List<dynamic> history) {
    final List<dynamic> substages = stage['substages'] ?? [];
    for (var sub in substages) {
      if (!_isSubstagePassed(sub, history)) {
        return false;
      }
    }
    return true;
  }

  // Toggles the activity completion status in simulation mode

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
          'Activities & Stages',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: darkColor,
        elevation: 0,
        actions: [
          Consumer<AttendanceProvider>(
            builder: (context, provider, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FireStreakIcon(streakCount: provider.currentStreak),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Toggle Simulator Mode',
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
                    ? 'Teacher Simulation Mode Active! You can now check off activities.' 
                    : 'Student Read-Only Mode Restored.'),
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
                        'Teacher Simulation Active (Tap to approve marks)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C2D12)),
                      ),
                    ),
                  ],
                ),
              ),

            Text(
              'Action Items & Thresholds',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You must meet the separate thresholds for MUST, INDIVIDUAL, and GROUP sections to unlock the next stage.',
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
                  final List<dynamic> subList = stage['substages'];
                  for (var sub in subList) {
                    if (_isSubstagePassed(sub, history)) passedCount++;
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isUnlocked ? Colors.grey.shade200 : Colors.grey.shade200.withValues(alpha: 0.5),
                        width: isUnlocked ? 1.0 : 0.8,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    color: isUnlocked ? Colors.white : Colors.grey.shade50.withValues(alpha: 0.8),
                    child: ExpansionTile(
                      enabled: isUnlocked,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUnlocked ? primaryColor.withValues(alpha: 0.1) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                          color: isUnlocked ? primaryColor : Colors.grey.shade500,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        stage['name'],
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
                            ? 'Substages Passed: $passedCount / ${subList.length}' 
                            : 'Stage Locked',
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
                          stage['description'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),

                        // Stage Progress Summary (MUST, INDIVIDUAL, GROUP)
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Stage Progress',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: darkColor,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: stage['overallCompletedSubgroups'] == stage['overallTotalSubgroups'] && stage['overallTotalSubgroups'] > 0
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      stage['overallTotalSubgroups'] > 0 
                                          ? 'Stage Completion: ${stage['overallCompletedSubgroups']} / ${stage['overallTotalSubgroups']} Completed'
                                          : 'No Thresholds',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: stage['overallCompletedSubgroups'] == stage['overallTotalSubgroups'] && stage['overallTotalSubgroups'] > 0
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              if (stage['mustThreshold'] > 0) ...[
                                _buildProgressRow(
                                  'MUST', 
                                  stage['studentMustXp'] ?? 0, 
                                  stage['mustThreshold'] ?? 0, 
                                  stage['mustRemaining'] ?? 0,
                                  stage['mustCompleted'] == true,
                                ),
                                const SizedBox(height: 12),
                              ],
                              
                              if (stage['individualThreshold'] > 0) ...[
                                _buildProgressRow(
                                  'INDIVIDUAL', 
                                  stage['studentIndividualXp'] ?? 0, 
                                  stage['individualThreshold'] ?? 0, 
                                  stage['individualRemaining'] ?? 0,
                                  stage['individualCompleted'] == true,
                                ),
                                const SizedBox(height: 12),
                              ],
                              
                              if (stage['groupThreshold'] > 0) ...[
                                _buildProgressRow(
                                  'GROUP', 
                                  stage['studentGroupXp'] ?? 0, 
                                  stage['groupThreshold'] ?? 0, 
                                  stage['groupRemaining'] ?? 0,
                                  stage['groupCompleted'] == true,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Render Substages (MUST, INDIVIDUAL, GROUP)
                        ...List.generate(stage['substages'].length, (subIndex) {
                          final substage = stage['substages'][subIndex];
                          final List<dynamic> activities = substage['activities'] ?? [];
                          final int threshold = substage['threshold'] ?? 0;
                          final int score = _getSubstageScore(substage, history);
                          final bool isPassed = score >= threshold;
                          
                          int completedCount = 0;
                          for(var act in activities){
                              if(act['status'] == 'COMPLETED'){
                                  completedCount++;
                              }
                          }

                          final double progress = threshold > 0 ? (score / threshold).clamp(0.0, 1.0) : 0.0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Substage Header with threshold/progress and badge
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          substage['name']?.toString() ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: darkColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          'Completed: $completedCount / ${activities.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 8,
                                              backgroundColor: Colors.grey.shade200,
                                              valueColor: AlwaysStoppedAnimation<Color>(isPassed ? Colors.green : Colors.amber.shade600),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          '$score / $threshold XP',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isPassed ? Colors.green.shade700 : Colors.amber.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              if (activities.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text('No activities allocated under this section.'),
                                )
                              else
                                ...List.generate(activities.length, (actIndex) {
                                  final activity = activities[actIndex];
                                  final bool isDone = activity['status'] == 'COMPLETED';
                                  final String statusStr = (activity['status']?.toString() ?? 'NOT STARTED').replaceAll('_', ' ');
                                  
                                  Color statusColor = Colors.grey.shade600;
                                  if (statusStr == 'COMPLETED') statusColor = Colors.green;
                                  if (statusStr == 'IN PROGRESS') statusColor = Colors.amber.shade700;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: isDone ? Colors.green.withValues(alpha: 0.03) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDone ? Colors.green.withValues(alpha: 0.3) : Colors.grey.shade300,
                                      ),
                                      boxShadow: [
                                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0,2))
                                      ]
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Top row: Name & Status
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  activity['activityName']?.toString() ?? '',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: darkColor,
                                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  statusStr,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: statusColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            activity['description']?.toString() ?? '',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                                          const SizedBox(height: 12),
                                          
                                          // Grid of Details
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                  child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                          _buildDetailRow(Icons.stars, 'Reward', "+${activity["rewardXp"] ?? 0} XP", Colors.amber.shade800),
                                                          const SizedBox(height: 6),
                                                          _buildDetailRow(Icons.person, 'Faculty', activity['facultyName']?.toString() ?? '', Colors.blue.shade700),
                                                          const SizedBox(height: 6),
                                                          _buildDetailRow(Icons.upload_file, 'Evidence', activity['evidence']?.toString() ?? '', Colors.grey.shade700),
                                                      ],
                                                  ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                          _buildDetailRow(Icons.military_tech, 'Awarded', "${activity["awardedXp"] ?? 0} / ${activity["requiredXp"] ?? activity["rewardXp"] ?? 0} XP", Colors.green.shade700),
                                                          const SizedBox(height: 6),
                                                          _buildDetailRow(Icons.calendar_month, 'Frequency', activity['frequency']?.toString() ?? '', Colors.deepPurple.shade400),
                                                      ],
                                                  ),
                                              ),
                                            ],
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

  Widget _buildProgressRow(String label, int current, int threshold, int remaining, bool isCompleted) {
    final double progress = threshold > 0 ? (current / threshold).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
            ),
            Text(
              isCompleted ? 'Completed' : 'Remaining: $remaining XP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : Colors.amber.shade600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 70,
              child: Text(
                '$current / $threshold XP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green.shade700 : Colors.amber.shade800,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

