import 'package:spdms_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spdms_app/providers/xp_provider.dart';
import '../../captain/tabs/captain_group_tab.dart';

class DashboardTab extends StatefulWidget {
  final String token;
  const DashboardTab({super.key, required this.token});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool isLoading = true;
  String studentName = "sivaganesh";
  String studentId = "24IT077";
  String department = "Information Technology";
  String section = "A";
  String year = "III";
  int score = 95; // Discipline points
  int rank = 1;
  int currentStage = 1;
  bool isCaptain = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final xpProv = Provider.of<XpProvider>(context, listen: false);
      xpProv.fetchSummary(studentId, widget.token);
      xpProv.fetchHistory(studentId, widget.token);
      xpProv.fetchStreaks(studentId, widget.token);
    });
  }

  Future<void> _fetchProfileData() async {
    if (widget.token == "debug_token") {
      setState(() {
        isLoading = false;
      });
      return;
    }
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/auth/me"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final resData = data["data"];
          setState(() {
            studentName = resData["fullName"] ?? "sivaganesh";
            studentId = resData["username"] ?? "24IT077";
            section = resData["section"] ?? "A";
            year = resData["year"] ?? "III";
            department = resData["department"] ?? "Information Technology";
            score = resData["score"] ?? 95;
            currentStage = resData["stage"] ?? 1;
            isCaptain = resData["isCaptain"] ?? false;
            isLoading = false;
          });

          // Refresh provider queries with corrected student ID
          final xpProv = Provider.of<XpProvider>(context, listen: false);
          xpProv.fetchSummary(studentId, widget.token);
          xpProv.fetchHistory(studentId, widget.token);
          xpProv.fetchStreaks(studentId, widget.token);
          return;
        }
      }
    } catch (e) {
      // Keep fallback
    }

    setState(() {
      isLoading = false;
    });
  }

  // Calculate current level and thresholds from XP
  Map<String, dynamic> _getLevelInfo(int totalXp) {
    if (totalXp <= 100) {
      return {"level": 1, "title": "Explorer", "min": 0, "max": 100};
    } else if (totalXp <= 500) {
      return {"level": 2, "title": "Builder", "min": 101, "max": 500};
    } else if (totalXp <= 1500) {
      return {"level": 3, "title": "Innovator", "min": 501, "max": 1500};
    } else if (totalXp <= 3000) {
      return {"level": 4, "title": "Specialist", "min": 1501, "max": 3000};
    } else if (totalXp <= 5000) {
      return {"level": 5, "title": "Leader", "min": 3001, "max": 5000};
    } else if (totalXp <= 7000) {
      return {"level": 6, "title": "Mentor", "min": 5001, "max": 7000};
    } else if (totalXp <= 10000) {
      return {"level": 7, "title": "Architect", "min": 7001, "max": 10000};
    } else {
      return {"level": 8, "title": "Industry Ready", "min": 10001, "max": 99999};
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpProvider = Provider.of<XpProvider>(context);

    if (isLoading || xpProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
          ),
        ),
      );
    }

    final totalXp = xpProvider.totalXp;
    final levelInfo = _getLevelInfo(totalXp);
    final int levelNum = levelInfo["level"];
    final String levelTitle = levelInfo["title"];
    final int minXp = levelInfo["min"];
    final int maxXp = levelInfo["max"];
    final double levelProgress = (totalXp - minXp) / (maxXp - minXp);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Student Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_rounded, color: Colors.white),
            tooltip: 'My Group',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CaptainGroupTab(token: widget.token),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Text
              Text(
                "Welcome back,",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (isCaptain) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            "CAPTAIN",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Discipline Score card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Discipline Score",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "$score Points",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Department",
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              department,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Section & Year",
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$year Year - Sec $section",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Widget 3: Level Progress Card
              _buildLevelProgressCard(levelNum, levelTitle, totalXp, maxXp, levelProgress),

              const SizedBox(height: 20),

              // Widget 4: Stage Progress Banner
              _buildStageProgressBanner(currentStage, totalXp),

              const SizedBox(height: 24),

              // Metric Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.emoji_events_rounded,
                      iconColor: Colors.amber.shade600,
                      bgColor: Colors.amber.shade50,
                      title: "Leaderboard Rank",
                      value: "#$rank",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.shield_rounded,
                      iconColor: Colors.teal.shade600,
                      bgColor: Colors.teal.shade50,
                      title: "Active Stage",
                      value: "Stage $currentStage",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Widget 2: Streak Cards Row
              const Text(
                "Active Streaks",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              _buildStreaksRow(xpProvider.streaks),

              const SizedBox(height: 24),
              _buildXpSummaryGrid(xpProvider.xpByCategory, totalXp),
              const SizedBox(height: 24),

              // Widget 1: XP Category Mini Bar Chart
              const Text(
                "XP by Category",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              _buildCategoryBarChart(xpProvider.xpByCategory),

              const SizedBox(height: 24),

              // Widget 6: Group Card
              _buildGroupCard(),

              const SizedBox(height: 28),

              // Widget 5: Recent Activity Feed
              const Text(
                "Recent Point Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              _buildActivityFeed(xpProvider.history),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBarChart(Map<String, int> categories) {
    final double acadXp = (categories["ACADEMIC"] ?? 0).toDouble();
    final double skillXp = (categories["SKILL"] ?? 0).toDouble();
    final double commXp = (categories["COMMUNICATION"] ?? 0).toDouble();
    final double leadXp = (categories["LEADERSHIP"] ?? 0).toDouble();
    final double innoXp = (categories["INNOVATION"] ?? 0).toDouble();
    final double placXp = (categories["PLACEMENT"] ?? 0).toDouble();
    final double discXp = (categories["DISCIPLINE"] ?? 0).toDouble();
    final double commuXp = (categories["COMMUNITY"] ?? 0).toDouble();
    final double sporXp = (categories["SPORTS"] ?? 0).toDouble();
    final double cultXp = (categories["CULTURAL"] ?? 0).toDouble();

    double maxVal = [acadXp, skillXp, commXp, leadXp, innoXp, placXp, discXp, commuXp, sporXp, cultXp]
        .reduce((curr, next) => curr > next ? curr : next);
    if (maxVal < 10) maxVal = 100;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.15,
          barTouchData: BarTouchData(
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              if (event is FlTapUpEvent && barTouchResponse != null && barTouchResponse.spot != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Redirecting to XP Tracker filtered view...")),
                );
              }
            },
            enabled: true,
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 8);
                  switch (value.toInt()) {
                    case 0: return const Text('Acad', style: style);
                    case 1: return const Text('Skill', style: style);
                    case 2: return const Text('Comm', style: style);
                    case 3: return const Text('Lead', style: style);
                    case 4: return const Text('Inno', style: style);
                    case 5: return const Text('Plac', style: style);
                    case 6: return const Text('Disc', style: style);
                    case 7: return const Text('Commu', style: style);
                    case 8: return const Text('Sport', style: style);
                    case 9: return const Text('Cult', style: style);
                    default: return const Text('', style: style);
                  }
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _makeBarGroup(0, acadXp, Colors.blue),
            _makeBarGroup(1, skillXp, Colors.purple),
            _makeBarGroup(2, commXp, Colors.indigo),
            _makeBarGroup(3, leadXp, Colors.amber),
            _makeBarGroup(4, innoXp, Colors.orange),
            _makeBarGroup(5, placXp, Colors.green),
            _makeBarGroup(6, discXp, Colors.red),
            _makeBarGroup(7, commuXp, Colors.teal),
            _makeBarGroup(8, sporXp, Colors.pink),
            _makeBarGroup(9, cultXp, Colors.cyan),
          ],
        ),
      ),
    );
  }

  Widget _buildXpSummaryGrid(Map<String, int> categories, int totalXp) {
    final list = [
      {"label": "Academic XP", "value": categories["ACADEMIC"] ?? 0, "color": Colors.blue},
      {"label": "Skill XP", "value": categories["SKILL"] ?? 0, "color": Colors.purple},
      {"label": "Communication XP", "value": categories["COMMUNICATION"] ?? 0, "color": Colors.indigo},
      {"label": "Leadership XP", "value": categories["LEADERSHIP"] ?? 0, "color": Colors.amber},
      {"label": "Innovation XP", "value": categories["INNOVATION"] ?? 0, "color": Colors.orange},
      {"label": "Placement XP", "value": categories["PLACEMENT"] ?? 0, "color": Colors.green},
      {"label": "Discipline XP", "value": categories["DISCIPLINE"] ?? 0, "color": Colors.red},
      {"label": "Community XP", "value": categories["COMMUNITY"] ?? 0, "color": Colors.teal},
      {"label": "Sports XP", "value": categories["SPORTS"] ?? 0, "color": Colors.pink},
      {"label": "Cultural XP", "value": categories["CULTURAL"] ?? 0, "color": Colors.cyan},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.summarize_rounded, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                "XP Summary",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final label = item["label"] as String;
              final val = item["value"] as int;
              final color = item["color"] as Color;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$val XP",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total XP",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                "$totalXp XP",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ],
          )
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        )
      ],
    );
  }

  // Widget 2: Horizontal Streaks List
  Widget _buildStreaksRow(List<dynamic> streaks) {
    if (streaks.isEmpty) {
      return const Text("No active streaks recorded.");
    }
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: streaks.length,
        itemBuilder: (context, index) {
          final streak = streaks[index];
          final String name = streak["streakType"].toString().replaceFirst("_", " ");
          final int count = streak["currentStreak"] ?? 0;
          final bool isBroken = streak["isBroken"] ?? false;

          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isBroken ? Colors.red.shade200 : Colors.green.shade200,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(isBroken ? "❄️" : "🔥", style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isBroken ? "Broken" : "$count Days",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isBroken ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget 3: Level Progress Card
  Widget _buildLevelProgressCard(int levelNum, String levelTitle, int totalXp, int maxXp, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Level $levelNum — $levelTitle",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
              ),
              const Icon(Icons.stars_rounded, color: Colors.indigo, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$totalXp / $maxXp XP to next level",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  // Widget 4: Stage Progress Banner
  Widget _buildStageProgressBanner(int currentStage, int totalXp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Row(
            children: List.generate(3, (index) {
              final stageIdx = index + 1;
              final isCurrent = stageIdx == currentStage;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? const Color(0xFF4F46E5) : Colors.grey.shade300,
                ),
              );
            }),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Stage $currentStage — ${currentStage == 1 ? 'Roots' : currentStage == 2 ? 'Branches' : 'Fruits'} | $totalXp / ${currentStage == 1 ? 500 : 1200} XP",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  // Widget 5: Recent Activity Feed
  Widget _buildActivityFeed(List<dynamic> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            "No recent activities recorded.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length > 5 ? 5 : history.length,
      itemBuilder: (context, index) {
        final log = history[index];
        final int points = log["xpPoints"] ?? 0;
        final bool isPositive = points > 0;
        final String status = log["status"] ?? "APPROVED";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: isPositive ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(
                isPositive ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              log["activityName"] ?? "",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13),
            ),
            subtitle: Row(
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
                        ? Colors.green.withOpacity(0.1)
                        : "REJECTED".equalsIgnoreCase(status)
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 8,
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
            trailing: Text(
              isPositive ? "+$points XP" : "$points XP",
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget 6: Group Card
  Widget _buildGroupCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Group: IT Innovators",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "ADVANCED",
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Captain: Sivaganesh",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Text(
                "Group XP: 3820 XP",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  bool equalsIgnoreCase(String other) {
    return toLowerCase() == other.toLowerCase();
  }
}
