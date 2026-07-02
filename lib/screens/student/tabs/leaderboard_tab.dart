import 'package:flutter/material.dart';

class LeaderboardTab extends StatefulWidget {
  final String token;
  const LeaderboardTab({super.key, required this.token});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  bool isLoading = true;

  // Currently logged-in student registry details
  final String currentStudentId = "24CS036";
  final String currentStudentName = "Sharugesh";

  // Comprehensive mockup database representing all years, depts, and sections
  final List<Map<String, dynamic>> allStudentsData = [
    {"studentId": "24CS036", "fullName": "Sharugesh", "departmentName": "CSE", "year": "III", "section": "A", "score": 95},
    {"studentId": "25CS010", "fullName": "Priya K", "departmentName": "CSE", "year": "I", "section": "A", "score": 92},
    {"studentId": "24CS002", "fullName": "Venkat", "departmentName": "CSE", "year": "III", "section": "A", "score": 90},
    {"studentId": "24IT089", "fullName": "Jagadheesh", "departmentName": "IT", "year": "III", "section": "B", "score": 88},
    {"studentId": "22CS045", "fullName": "Rahul Kumar", "departmentName": "CSE", "year": "IV", "section": "A", "score": 85},
    {"studentId": "25IT004", "fullName": "Sanjay M", "departmentName": "IT", "year": "I", "section": "B", "score": 84},
    {"studentId": "24EE015", "fullName": "Divya T", "departmentName": "EEE", "year": "III", "section": "B", "score": 81},
    {"studentId": "23EE012", "fullName": "Kavya S", "departmentName": "EEE", "year": "II", "section": "A", "score": 80},
    {"studentId": "22ME022", "fullName": "Arjun P", "departmentName": "MECH", "year": "IV", "section": "C", "score": 79},
    {"studentId": "23ME033", "fullName": "Vijay R", "departmentName": "MECH", "year": "II", "section": "B", "score": 75},
  ];

  // Active filter state variables
  String selectedYear = "All";
  String selectedDept = "All";
  String selectedSection = "All";

  // Filtered leaderboard dataset
  List<Map<String, dynamic>> filteredList = [];

  // Filter options lists
  final List<String> yearOptions = ["All", "I", "II", "III", "IV"];
  final List<String> deptOptions = ["All", "CSE", "IT", "EEE", "MECH"];
  final List<String> sectionOptions = ["All", "A", "B", "C"];

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      isLoading = true;
    });

    // Simulate short loader
    Future.delayed(const Duration(milliseconds: 300), () {
      List<Map<String, dynamic>> temp = List.from(allStudentsData);

      // 1. Filter by Year
      if (selectedYear != "All") {
        temp = temp.where((s) => s["year"] == selectedYear).toList();
      }

      // 2. Filter by Department
      if (selectedDept != "All") {
        temp = temp.where((s) => s["departmentName"] == selectedDept).toList();
      }

      // 3. Filter by Section
      if (selectedSection != "All") {
        temp = temp.where((s) => s["section"] == selectedSection).toList();
      }

      // Sort remaining by score descending
      temp.sort((a, b) => (b["score"] as int).compareTo(a["score"] as int));

      setState(() {
        filteredList = temp;
        isLoading = false;
      });
    });
  }

  // Returns the current student's rank index (+1) in the current filtered view
  int _getCurrentUserRank() {
    for (int i = 0; i < filteredList.length; i++) {
      if (filteredList[i]["studentId"] == currentStudentId) {
        return i + 1;
      }
    }
    return -1; // Not in active filters
  }

  @override
  Widget build(BuildContext context) {
    final int userRank = _getCurrentUserRank();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Leaderboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Row Block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Year Filter
                Expanded(
                  child: _buildFilterDropdown(
                    label: "Year",
                    value: selectedYear,
                    items: yearOptions,
                    onChanged: (val) {
                      if (val != null) {
                        selectedYear = val;
                        _applyFilters();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Dept Filter
                Expanded(
                  child: _buildFilterDropdown(
                    label: "Dept",
                    value: selectedDept,
                    items: deptOptions,
                    onChanged: (val) {
                      if (val != null) {
                        selectedDept = val;
                        _applyFilters();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Section Filter
                Expanded(
                  child: _buildFilterDropdown(
                    label: "Sec",
                    value: selectedSection,
                    items: sectionOptions,
                    onChanged: (val) {
                      if (val != null) {
                        selectedSection = val;
                        _applyFilters();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Content View
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                    ),
                  )
                : filteredList.isEmpty
                    ? _buildEmptyState()
                    : _buildLeaderboardContent(userRank),
          ),

          // Sticky Bottom Card for Current User Position
          _buildStickyBottomCard(userRank),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item == "All" ? "All $label" : item),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "No student records match selected filters.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent(int userRank) {
    // Determine Podium and Remaining lists
    final topThree = filteredList.take(3).toList();
    final remaining = filteredList.skip(3).toList();

    return Column(
      children: [
        // Top 3 Podium
        if (topThree.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Rank 2 Podium
                if (topThree.length > 1)
                  _buildPodiumCell(
                    student: topThree[1],
                    rank: 2,
                    height: 80,
                    avatarRadius: 26,
                    crownIcon: Icons.workspace_premium_rounded,
                    color: Colors.grey.shade400,
                  ),

                // Rank 1 Podium
                _buildPodiumCell(
                  student: topThree[0],
                  rank: 1,
                  height: 110,
                  avatarRadius: 34,
                  crownIcon: Icons.emoji_events_rounded,
                  color: Colors.amber,
                ),

                // Rank 3 Podium
                if (topThree.length > 2)
                  _buildPodiumCell(
                    student: topThree[2],
                    rank: 3,
                    height: 70,
                    avatarRadius: 24,
                    crownIcon: Icons.workspace_premium_outlined,
                    color: Colors.orange.shade400,
                  ),
              ],
            ),
          ),

        // List Scroll
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: remaining.length,
            itemBuilder: (context, index) {
              final s = remaining[index];
              final String name = s["fullName"] ?? '';
              final String regNo = s["studentId"] ?? '';
              final String dept = s["departmentName"] ?? '';
              final String yr = s["year"] ?? '';
              final String sec = s["section"] ?? '';
              final int score = s["score"] ?? 0;
              final rank = index + 4;
              final isCurrentUser = regNo == currentStudentId;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isCurrentUser ? const Color(0xFFEEF2FF) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrentUser ? const Color(0xFFC7D2FE) : Colors.grey.shade100,
                    width: isCurrentUser ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "#$rank",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? const Color(0xFF312E81) : const Color(0xFF1E293B),
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "$regNo • $dept • Year $yr - $sec",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  trailing: Text(
                    "$score pts",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumCell({
    required dynamic student,
    required int rank,
    required double height,
    required double avatarRadius,
    required IconData crownIcon,
    required Color color,
  }) {
    final String name = student["fullName"] ?? '';
    final String regNo = student["studentId"] ?? '';
    final int score = student["score"] ?? 0;
    final String dept = student["departmentName"] ?? '';
    final isCurrentUser = regNo == currentStudentId;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(crownIcon, color: color, size: rank == 1 ? 26 : 20),
        const SizedBox(height: 4),

        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: Colors.white24,
          child: CircleAvatar(
            radius: avatarRadius - 2.5,
            backgroundColor: isCurrentUser ? const Color(0xFF4F46E5) : const Color(0xFF334155),
            child: Text(
              name.isNotEmpty ? name[0] : 'S',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          width: 80,
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          "$dept • $score pts",
          style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),

        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: color.withOpacity(0.3), width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(
            "#$rank",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildStickyBottomCard(int userRank) {
    if (isLoading || filteredList.isEmpty) return const SizedBox.shrink();

    final isPresent = userRank != -1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isPresent ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(
              isPresent ? Icons.stars_rounded : Icons.info_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPresent ? "Your Standing in this View" : "Filtered View Standing",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPresent
                        ? "Rank #$userRank | $currentStudentName (${allStudentsData.firstWhere((s) => s["studentId"] == currentStudentId)["score"]} pts)"
                        : "You are not present in the current filtered standing.",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
