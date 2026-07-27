import 'package:flutter/material.dart';
import 'package:spdms_app/features/admin/repository/admin_repository.dart';
import 'package:spdms_app/core/di/service_locator.dart';

class SuperAdminManagementTab extends StatefulWidget {
  const SuperAdminManagementTab({super.key});

  @override
  State<SuperAdminManagementTab> createState() => _SuperAdminManagementTabState();
}

class _SuperAdminManagementTabState extends State<SuperAdminManagementTab> {
  final AdminRepository _repository = getIt<AdminRepository>();
  List<dynamic> _yearAdmins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchYearAdmins();
  }

  Future<void> _fetchYearAdmins() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final admins = await _repository.getYearAdmins();
      setState(() {
        _yearAdmins = admins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteYearAdmin(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to remove this Year Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repository.deleteYearAdmin(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Year Admin deleted successfully')));
      _fetchYearAdmins();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAdminDialog({Map<String, dynamic>? admin}) {
    final isEditing = admin != null;
    final usernameCtrl = TextEditingController(text: admin?['username'] ?? '');
    final fullNameCtrl = TextEditingController(text: admin?['fullName'] ?? '');
    final emailCtrl = TextEditingController(text: admin?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: admin?['phone'] ?? '');
    final passwordCtrl = TextEditingController();
    String? selectedYear = admin?['assignedAcademicYear'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? 'Edit Year Admin' : 'New Year Admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                decoration: InputDecoration(
                  labelText: isEditing ? 'Password (leave blank to keep current)' : 'Password',
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedYear,
                decoration: const InputDecoration(labelText: 'Assigned Year', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Not Assigned')),
                  DropdownMenuItem(value: 'FIRST_YEAR', child: Text('First Year')),
                  DropdownMenuItem(value: 'SECOND_YEAR', child: Text('Second Year')),
                  DropdownMenuItem(value: 'THIRD_YEAR', child: Text('Third Year')),
                  DropdownMenuItem(value: 'FOURTH_YEAR', child: Text('Fourth Year')),
                ],
                onChanged: (val) {
                  selectedYear = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
            onPressed: () async {
              if (usernameCtrl.text.trim().isEmpty || fullNameCtrl.text.trim().isEmpty) return;
              if (!isEditing && passwordCtrl.text.isEmpty) return;

              final data = <String, dynamic>{
                'fullName': fullNameCtrl.text.trim(),
                'username': usernameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'active': true,
              };
              if (selectedYear != null) {
                data['assignedAcademicYear'] = selectedYear;
              } else {
                data['assignedAcademicYear'] = null; // Send null explicitly if unassigned
              }
              if (passwordCtrl.text.isNotEmpty) {
                data['password'] = passwordCtrl.text;
              }

              if (selectedYear != null && data['active'] == true) {
                final existingAdmin = _yearAdmins.firstWhere(
                  (a) => a['assignedAcademicYear'] == selectedYear && a['id'] != admin?['id'] && a['active'] == true,
                  orElse: () => null,
                );
                if (existingAdmin != null) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Replace Assignment?'),
                      content: Text('${existingAdmin['username']} is already assigned to this year. Do you want to replace them?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Replace')),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                }
              }

              Navigator.pop(context);
              try {
                if (isEditing) {
                  await _repository.updateYearAdmin(admin!['id'], data);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Year Admin updated')));
                } else {
                  await _repository.addYearAdmin(data);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Year Admin created')));
                }
                _fetchYearAdmins();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchYearAdmins,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdminDialog(),
        backgroundColor: const Color(0xFF1E293B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Admin', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E293B), Color(0xFFF1F5F9)],
            stops: [0.3, 0.3],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _yearAdmins.length,
                    itemBuilder: (context, index) {
                      final admin = _yearAdmins[index];
                      String cleanYear;
                      if (admin['assignedAcademicYear'] == null) {
                        cleanYear = 'Not Assigned';
                      } else {
                        String yearStr = admin['assignedAcademicYear'];
                        cleanYear = yearStr.replaceAll('_', ' ').toLowerCase();
                        cleanYear = cleanYear.split(' ').map((str) => str[0].toUpperCase() + str.substring(1)).join(' ');
                      }

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            child: const Icon(Icons.admin_panel_settings, color: Color(0xFF4F46E5)),
                          ),
                          title: Text(
                            admin['username'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text(
                            'Year: $cleanYear',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (admin['assignedAcademicYear'] == null)
                                TextButton(
                                  onPressed: () => _showAdminDialog(admin: admin),
                                  child: const Text('Assign Year'),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showAdminDialog(admin: admin),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteYearAdmin(admin['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
