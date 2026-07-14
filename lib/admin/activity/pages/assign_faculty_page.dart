import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../providers/activity_provider.dart';
import '../widgets/sticky_bottom_buttons.dart';

class AssignFacultyPage extends StatefulWidget {
  final ActivityProvider provider;
  final ActivityModel activity;

  const AssignFacultyPage({
    super.key,
    required this.provider,
    required this.activity,
  });

  @override
  State<AssignFacultyPage> createState() => _AssignFacultyPageState();
}

class _AssignFacultyPageState extends State<AssignFacultyPage> {
  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  bool _globalEnabled = false;
  bool _ccEnabled = false;
  bool _isLoading = false;

  // Stores configuration state for each department
  // Key: departmentId (int)
  // Value: Map containing configuration options
  // {
  //   'isSectionWise': bool (if dept has sections),
  //   'sectionsSelection': Map<sectionId, teacherId> (where teacherId = 0 means "Any Faculty", null means "Not Assigned"),
  //   'noSectionSelection': int? (teacherId, 0 = Any Faculty, null = Not Assigned)
  // }
  final Map<int, Map<String, dynamic>> _deptConfigs = {};

  @override
  void initState() {
    super.initState();
    _initializeStateFromActivity();
  }

  void _initializeStateFromActivity() {
    // Determine if currently assigned globally
    final summary = widget.activity.assignmentSummary;
    final hasGlobal = summary.any((e) => e['scope'] == 'GLOBAL');
    final hasCc = summary.any((e) => e['scope'] == 'CLASS_COORDINATOR') ||
        widget.activity.assignmentMode == 'CLASS_COORDINATOR';
    if (hasCc) {
      _ccEnabled = true;
      return;
    }
    if (hasGlobal) {
      _globalEnabled = true;
      return;
    }

    // Populate department configs based on current assignments
    for (final assign in summary) {
      final deptId = assign['departmentId'] as int?;
      if (deptId == null) continue;

      final sectionId = assign['sectionId'] as int?;
      final teacherId = assign['teacherId'] as int?;

      if (!_deptConfigs.containsKey(deptId)) {
        _deptConfigs[deptId] = {
          'isSectionWise': false,
          'sameFacultyForAll': false,
          'sectionsSelection': <int, int?>{},
          'noSectionSelection': null,
        };
      }

      final config = _deptConfigs[deptId]!;

      if (sectionId != null) {
        config['isSectionWise'] = true;
        (config['sectionsSelection'] as Map<int, int?>)[sectionId] = teacherId ?? 0;
      } else {
        config['noSectionSelection'] = teacherId ?? 0;
      }
    }

    _deptConfigs.forEach((deptId, config) {
      final sectionSels = config['sectionsSelection'] as Map<int, int?>;
      if (sectionSels.isNotEmpty) {
        final values = sectionSels.values.toSet();
        if (values.length == 1) {
          config['sameFacultyForAll'] = true;
        }
      }
    });
  }

  List<dynamic> _getTeachersForDepartment(int deptId, String deptName) {
    final nameLower = deptName.toLowerCase();
    return widget.provider.allTeachers.where((t) {
      final tid = t['departmentId'];
      final tname = (t['departmentName'] as String? ?? '').toLowerCase();
      return tid == deptId || tname == nameLower;
    }).toList();
  }

  List<dynamic> _getSectionsForDepartment(int deptId) {
    return widget.provider.sections.where((s) {
      final sDeptId = s['department'] != null ? s['department']['id'] : null;
      return sDeptId == deptId;
    }).toList();
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);

    try {
      final List<Map<String, dynamic>> assignments = [];

      if (_ccEnabled) {
        // CC mode: no manual assignments, backend resolves CCs
        await widget.provider.saveAssignments(
          widget.activity.id,
          false,
          [],
          ccEnabled: true,
        );
      } else if (!_globalEnabled) {
        for (final dept in widget.provider.departments) {
          final deptId = dept['id'] as int;
          final deptName = dept['name'] as String;
          final sections = dept['sections'] as List<dynamic>? ?? [];
          final config = _deptConfigs[deptId];
          if (config == null) continue;

          if (sections.isNotEmpty) {
            final sectionSels = config['sectionsSelection'] as Map<int, int?>;
            sectionSels.forEach((secId, teacherId) {
              if (teacherId != null) {
                assignments.add({
                  'departmentId': deptId,
                  'sectionId': secId,
                  'facultyId': teacherId == 0 ? null : teacherId,
                  'scope': teacherId == 0 ? 'SECTION' : 'SPECIFIC_FACULTY',
                });
              }
            });
          } else {
            // No sections
            final teacherId = config['noSectionSelection'] as int?;
            if (teacherId != null) {
              assignments.add({
                'departmentId': deptId,
                'sectionId': null,
                'facultyId': teacherId == 0 ? null : teacherId,
                'scope': teacherId == 0 ? 'DEPARTMENT' : 'SPECIFIC_FACULTY',
              });
            }
          }
        }
        await widget.provider.saveAssignments(
          widget.activity.id,
          false,
          assignments,
        );
      } else {
        await widget.provider.saveAssignments(
          widget.activity.id,
          true,
          [],
        );
      }
      
      await widget.provider.updateActivity(widget.activity.id, {}); // Trigger list updates

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignments saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save assignments: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Assign Faculty',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.provider.isLoadingDependencies
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity details banner card
                  _buildActivityBanner(),
                  const SizedBox(height: 16),

                  // Global Assignment Switch Card
                  _buildGlobalToggleCard(),
                  const SizedBox(height: 12),

                  // Class Coordinator Assignment Switch Card
                  _buildCcToggleCard(),
                  const SizedBox(height: 20),

                  if (_ccEnabled || !_globalEnabled) ...[
                    Text(
                      _ccEnabled ? 'CLASS COORDINATOR ASSIGNMENTS (Auto-Resolved)' : 'DEPARTMENT WISE ASSIGNMENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _ccEnabled ? const Color(0xFF4F46E5) : Colors.blueGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...widget.provider.departments.map((dept) => _buildDeptCard(dept)),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: StickyBottomButtons(
        saveLabel: 'Save Assignments',
        onSave: _onSave,
        onCancel: () => Navigator.pop(context),
        isSaving: _isLoading,
      ),
    );
  }

  Widget _buildActivityBanner() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_activity_rounded, color: _primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.activity.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _dark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'XP: ${widget.activity.xp} • Frequency: ${widget.activity.awardFrequency}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalToggleCard() {
    return Card(
      elevation: 0,
      color: _globalEnabled ? _primary.withOpacity(0.05) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _globalEnabled ? _primary.withOpacity(0.5) : Colors.grey.shade200,
          width: _globalEnabled ? 1.5 : 1,
        ),
      ),
      child: SwitchListTile(
        activeColor: _primary,
        title: const Text(
          'GLOBAL ASSIGNMENT',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _dark),
        ),
        subtitle: const Text(
          'Enable to assign this activity to ALL departments, ALL sections, and ANY faculty member across the college.',
          style: TextStyle(fontSize: 12),
        ),
        value: _globalEnabled,
        onChanged: _ccEnabled ? null : (val) {
          setState(() {
            _globalEnabled = val;
          });
        },
      ),
    );
  }

  Widget _buildCcToggleCard() {
    const ccColor = Color(0xFF4F46E5); // indigo
    return Card(
      elevation: 0,
      color: _ccEnabled ? ccColor.withOpacity(0.05) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _ccEnabled ? ccColor.withOpacity(0.5) : Colors.grey.shade200,
          width: _ccEnabled ? 1.5 : 1,
        ),
      ),
      child: SwitchListTile(
        activeColor: ccColor,
        title: const Text(
          'CLASS COORDINATOR ASSIGNMENT',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _dark),
        ),
        subtitle: const Text(
          'Automatically assign this activity to the Class Coordinator (CC) of every section.',
          style: TextStyle(fontSize: 12),
        ),
        value: _ccEnabled,
        onChanged: _globalEnabled ? null : (val) {
          setState(() {
            _ccEnabled = val;
          });
        },
      ),
    );
  }

  Widget _buildCcInfoCard() {
    const ccColor = Color(0xFF4F46E5); // indigo
    return Card(
      elevation: 0,
      color: ccColor.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ccColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ccColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: ccColor, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Auto-Resolved by System',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: ccColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'This activity will automatically be assigned to the Class Coordinator of every section.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            _ccInfoRow(Icons.apartment_rounded, 'Departments', 'All'),
            const SizedBox(height: 8),
            _ccInfoRow(Icons.view_list_rounded, 'Sections', 'All'),
            const SizedBox(height: 8),
            _ccInfoRow(Icons.person_rounded, 'Faculty', 'Resolved Automatically'),
          ],
        ),
      ),
    );
  }

  Widget _ccInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text('$label : ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
        Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
      ],
    );
  }

  int? _getCcForSection(int sectionId) {
    if (widget.activity.assignmentMode == 'CLASS_COORDINATOR' &&
        widget.activity.assignmentSummary.isNotEmpty) {
      for (final assignment in widget.activity.assignmentSummary) {
        if (assignment['sectionId'] == sectionId && assignment['teacherId'] != null) {
          return assignment['teacherId'] as int;
        }
      }
    }

    for (final cc in widget.provider.classCoordinators) {
      if (cc['sectionId'] == sectionId && cc['teacherId'] != null) {
        return cc['teacherId'] as int;
      }
    }
    return null;
  }

  Widget _buildDeptCard(dynamic dept) {
    final deptId = dept['id'] as int;
    final deptName = dept['name'] as String;
    final sections = dept['sections'] as List<dynamic>? ?? [];
    print('DEBUG_LOG: Widget _buildDeptCard deptName: $deptName (id: $deptId), sections found: ${sections.length}, data: $sections');
    final teachers = _getTeachersForDepartment(deptId, deptName);

    // Initialize config if not present
    if (!_deptConfigs.containsKey(deptId)) {
      _deptConfigs[deptId] = {
        'isSectionWise': false,
        'sameFacultyForAll': false,
        'sectionsSelection': <int, int?>{},
        'noSectionSelection': 0, // Default to Any Faculty
      };
    }

    // Initialize config if not present
    if (!_deptConfigs.containsKey(deptId)) {
      _deptConfigs[deptId] = {
        'sectionsSelection': <int, int?>{},
        'noSectionSelection': 0, // Default to Any Faculty
      };
    }

    final config = _deptConfigs[deptId]!;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dept Header
            Row(
              children: [
                const Icon(Icons.apartment_rounded, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    deptName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _dark),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (sections.isNotEmpty) ...[
              const Text(
                'Configure Sections:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              ...sections.map((sec) {
                final secId = sec['id'] as int;
                final secName = sec['sectionName'] as String;
                final sectionSels = config['sectionsSelection'] as Map<int, int?>;
                
                if (!sectionSels.containsKey(secId)) {
                  sectionSels[secId] = 0; // Default: Any Faculty
                }

                int? displayValue = sectionSels[secId];
                bool isMissingCc = false;

                if (_ccEnabled) {
                  final ccId = _getCcForSection(secId);
                  if (ccId != null) {
                    displayValue = ccId;
                  } else {
                    displayValue = null;
                    isMissingCc = true;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Section $secName',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: isMissingCc 
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: const Text('❌ No Class Coordinator Assigned', 
                                style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)),
                            )
                          : SearchableFacultySelector(
                              teachers: widget.provider.allTeachers,
                              selectedValue: displayValue,
                              readOnly: _ccEnabled,
                              onChanged: (val) {
                                if (!_ccEnabled) {
                                  setState(() {
                                    sectionSels[secId] = val;
                                  });
                                }
                              },
                            ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              // No sections - direct teacher selector
              const Text(
                'Assign To:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              SearchableFacultySelector(
                teachers: widget.provider.allTeachers,
                selectedValue: config['noSectionSelection'] as int?,
                readOnly: _ccEnabled,
                onChanged: (val) {
                  if (!_ccEnabled) {
                    setState(() {
                      config['noSectionSelection'] = val;
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SearchableFacultySelector extends StatefulWidget {
  final List<dynamic> teachers;
  final int? selectedValue;
  final ValueChanged<int?> onChanged;
  final bool readOnly;

  const SearchableFacultySelector({
    super.key,
    required this.teachers,
    required this.selectedValue,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<SearchableFacultySelector> createState() => _SearchableFacultySelectorState();
}

class _SearchableFacultySelectorState extends State<SearchableFacultySelector> {
  static const Color _primary = Color(0xFFEA4335);

  String _getTeacherText(dynamic t) {
    if (t == null) return 'Any Faculty';
    final name = t['fullName']?.toString() ?? 'Unknown';
    final dept = t['department'] != null ? t['department']['name']?.toString() : null;
    return dept != null ? '$name ($dept)' : name;
  }

  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _FacultySearchSheet(
          teachers: widget.teachers,
          selectedValue: widget.selectedValue,
          onSelected: (val) {
            Navigator.pop(context);
            widget.onChanged(val);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.selectedValue == 0 || widget.selectedValue == null
        ? null
        : widget.teachers.firstWhere(
            (t) => t['id'] == widget.selectedValue,
            orElse: () => null,
          );

    return InkWell(
      onTap: widget.readOnly ? null : () => _showSearchDialog(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: widget.readOnly ? const Color(0xFFF1F5F9) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.readOnly ? Colors.grey.shade200 : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _getTeacherText(current),
                style: TextStyle(
                  fontSize: 13, 
                  color: widget.readOnly ? Colors.grey.shade600 : const Color(0xFF1E293B),
                  fontWeight: widget.readOnly ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!widget.readOnly)
              const Icon(Icons.arrow_drop_down, color: _primary),
            if (widget.readOnly && current != null)
              const Icon(Icons.lock_outline_rounded, color: Colors.blueGrey, size: 16),
          ],
        ),
      ),
    );
  }
}

class _FacultySearchSheet extends StatefulWidget {
  final List<dynamic> teachers;
  final int? selectedValue;
  final ValueChanged<int?> onSelected;

  const _FacultySearchSheet({
    required this.teachers,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  State<_FacultySearchSheet> createState() => _FacultySearchSheetState();
}

class _FacultySearchSheetState extends State<_FacultySearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.teachers.where((t) {
      if (_query.isEmpty) return true;
      final name = (t['fullName'] ?? '').toString().toLowerCase();
      final username = (t['username'] ?? '').toString().toLowerCase();
      final deptName = (t['department'] != null ? t['department']['name'] ?? '' : '').toString().toLowerCase();
      final q = _query.toLowerCase();
      return name.contains(q) || username.contains(q) || deptName.contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Search Faculty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name, username, or department...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (val) {
              setState(() {
                _query = val;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = widget.selectedValue == 0 || widget.selectedValue == null;
                  return ListTile(
                    title: const Text('Any Faculty', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    selected: isSelected,
                    selectedColor: const Color(0xFFEA4335),
                    selectedTileColor: const Color(0xFFEA4335).withOpacity(0.05),
                    onTap: () => widget.onSelected(0),
                  );
                }
                final t = filtered[index - 1];
                final id = t['id'] as int;
                final isSelected = widget.selectedValue == id;
                final name = t['fullName']?.toString() ?? 'Unknown';
                final dept = t['department'] != null ? t['department']['name']?.toString() : null;
                
                return ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: dept != null ? Text(dept, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)) : null,
                  selected: isSelected,
                  selectedColor: const Color(0xFFEA4335),
                  selectedTileColor: const Color(0xFFEA4335).withOpacity(0.05),
                  onTap: () => widget.onSelected(id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
