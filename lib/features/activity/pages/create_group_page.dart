import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';

class CreateGroupPage extends StatefulWidget {
  final String token;
  final int assignmentId;
  final String? preselectedYear;
  final String? preselectedDept;
  final String? preselectedSection;

  const CreateGroupPage({
    super.key,
    required this.token,
    required this.assignmentId,
    this.preselectedYear,
    this.preselectedDept,
    this.preselectedSection,
  });

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController(text: '5');
  
  // Captain Search
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  dynamic _selectedCaptain;
  final _searchController = TextEditingController();

  // Theme constants
  static const Color _primary = Color(0xFF1E3A8A); // Deep blue
  static const Color _dark = Color(0xFF0F172A);
  static const Color _bg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
  }

  Future<void> _searchStudents(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/students/search?keyword=${Uri.encodeComponent(query.trim())}&page=0&size=50"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data']?['content'] ?? []) as List<dynamic>;
        
        // Filter by pre-selected department and section (if they exist)
        final filteredList = list.where((s) {
          final sDept = s['departmentName'] ?? '';
          final sSec = s['sectionName'] ?? '';
          
          bool matchesDept = widget.preselectedDept == null || widget.preselectedDept == "N/A" || sDept == widget.preselectedDept;
          bool matchesSec = widget.preselectedSection == null || widget.preselectedSection == "N/A" || sSec == widget.preselectedSection;
          
          return matchesDept && matchesSec;
        }).toList();
        
        setState(() {
          _searchResults = filteredList;
        });
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCaptain == null) {
      _showErrorDialog("Please select a captain.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/teams"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": _nameController.text.trim(),
          "size": int.parse(_sizeController.text.trim()),
          "captainStudentId": _selectedCaptain['studentId'],
          "assignmentId": widget.assignmentId,
        }),
      );
      
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonResponse['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // return true to refresh
        } else {
          _showErrorDialog(jsonResponse['message']);
        }
      } else {
        _showErrorDialog(jsonResponse['message'] ?? 'Failed to create group');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Academic Scope", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _dark)),
              const SizedBox(height: 16),
              
              _buildReadOnlyField("Academic Year", widget.preselectedYear ?? "Global"),
              const SizedBox(height: 12),
              _buildReadOnlyField("Department", widget.preselectedDept ?? "Global"),
              const SizedBox(height: 12),
              if (widget.preselectedSection != null && widget.preselectedSection != "N/A")
                _buildReadOnlyField("Section", widget.preselectedSection!),
              
              const SizedBox(height: 24),
              const Text("Group Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _dark)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum Size *',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (int.tryParse(val) == null || int.parse(val) <= 0) return 'Invalid number';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              const Text("Captain", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _dark)),
              const SizedBox(height: 16),
              
              if (_selectedCaptain != null)
                Card(
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade200)),
                  elevation: 0,
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(_selectedCaptain['fullName'] ?? ''),
                    subtitle: Text(_selectedCaptain['studentId'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedCaptain = null;
                          _searchController.clear();
                        });
                      },
                    ),
                  ),
                )
              else ...[
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Captain by Name / ID',
                    hintText: 'Type to search...',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: _isSearching 
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                  ),
                  onChanged: (val) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == val) {
                        _searchSearchWrapper(val);
                      }
                    });
                  },
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (ctx, idx) {
                        final s = _searchResults[idx];
                        return ListTile(
                          title: Text(s['fullName'] ?? ''),
                          subtitle: Text('${s['studentId']} | ${s['departmentName']} ${s['sectionName']}'),
                          onTap: () {
                            setState(() {
                              _selectedCaptain = s;
                              _searchResults = [];
                              _searchController.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                  child: const Text("Save Group", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        labelStyle: TextStyle(color: Colors.grey.shade700),
      ),
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
    );
  }

  void _searchSearchWrapper(String val) {
    if (mounted) {
      _searchStudents(val);
    }
  }
}
