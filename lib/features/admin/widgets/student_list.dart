import 'package:flutter/material.dart';
import '../dialogs/delete_student_dialog.dart';

class StudentList extends StatelessWidget {
  final List<dynamic> studentsList;
  final String searchQuery;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(int) onDelete;

  const StudentList({
    super.key,
    required this.studentsList,
    required this.searchQuery,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: studentsList.length,
      itemBuilder: (context, index) {
        final s = studentsList[index];
        final String sId = s['regNo'] ?? '';
        final String name = s['fullName'] ?? '';
        final String deptName = s['departmentName'] ?? 'No Department';

        if (searchQuery.isNotEmpty &&
            !sId.toLowerCase().contains(searchQuery) &&
            !name.toLowerCase().contains(searchQuery)) {
          return const SizedBox.shrink();
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEA4335).withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: Color(0xFFEA4335)),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "$sId • $deptName\nSem: ${s["semester"] ?? '1'}${s["year"] != null && s["year"].toString().isNotEmpty ? ' • Year: ${s["year"]}' : ''}${s["section"] != null && s["section"].toString().isNotEmpty ? ' • Section: ${s["section"]}' : ''}",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => onEdit(s),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => DeleteStudentDialog(
                        studentName: name,
                        onConfirmDelete: () => onDelete(s['id']),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
