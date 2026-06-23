import 'package:flutter/material.dart';
import 'teacher_student_detail.dart'; // Will create this next

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const StudentsTab(),
    const LeaderboardTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.black87,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ===================== STUDENTS TAB =====================
class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});
  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // Demo Students Data
  final List<Map<String, dynamic>> students = [
    {"id": 1, "name": "Sharugesh", "regNo": "22CS001", "dept": "CSE", "score": 85},
    {"id": 2, "name": "Priya Sharma", "regNo": "22CS002", "dept": "CSE", "score": 45},
    {"id": 3, "name": "Rahul Kumar", "regNo": "22IT045", "dept": "IT", "score": 120},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Students", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add new student functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Add Student feature coming soon")),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Student"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or reg no',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  if (searchQuery.isNotEmpty &&
                      !student['name'].toLowerCase().contains(searchQuery) &&
                      !student['regNo'].toLowerCase().contains(searchQuery)) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(student['name']),
                      subtitle: Text("${student['regNo']} • ${student['dept']}"),
                      trailing: Text(
                        "${student['score']} pts",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherStudentDetail(student: student),
                          ),
                        );
                      },
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

// ===================== LEADERBOARD TAB =====================
class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Leaderboard Coming Soon", style: TextStyle(fontSize: 20)));
  }
}

// ===================== PROFILE TAB =====================
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 100, color: Colors.black87),
          SizedBox(height: 20),
          Text(
            "Mr. Ramesh Kumar",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Department: Computer Science",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            "Teacher ID: TCH001",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}