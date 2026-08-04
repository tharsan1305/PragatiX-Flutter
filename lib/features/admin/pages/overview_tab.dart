import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/features/admin/pages/students_tab.dart';
import 'package:pragatix/features/admin/pages/teachers_tab.dart';
import 'package:pragatix/features/admin/pages/departments_tab.dart';
import 'package:pragatix/features/admin/services/attendance_settings_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/leaderboard/pages/shared_leaderboard_page.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  // ── Dashboard stats ──────────────────────────────────────────────────────────
  int totalStudents = 0;
  int totalTeachers = 0;
  int totalDepartments = 0;
  int totalAlerts = 0;
  int pendingBadgeRequests = 0;
  bool isLoading = true;
  bool hasError = false;

  // ── Attendance Engine Control Center ────────────────────────────────────────
  final AttendanceSettingsService _engineService = AttendanceSettingsService();
  Map<String, dynamic> _engineSettings = {};
  bool _engineLoading = false;
  bool _engineRunning = false;
  String? _lastEngineActionResult;
  String? _engineYear; // resolved from current user's academic year or null for super admin

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEngineStatus();
  }

  // ── Stats ────────────────────────────────────────────────────────────────────

  Future<void> _fetchStats() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final stats = await getIt<AdminRepository>().getStats();
      if (!mounted) return;
      setState(() {
        totalStudents = stats['totalStudents'] ?? 0;
        totalTeachers = stats['teachersCount'] ?? 0;
        totalDepartments = stats['totalDepartments'] ?? 0;
        totalAlerts = stats['totalAlerts'] ?? 0;
        pendingBadgeRequests = stats['pendingBadgeRequests'] ?? 0;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error fetching dashboard stats: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  // ── Engine Control Center ────────────────────────────────────────────────────

  String? _resolveEngineYear(AuthProvider auth) {
    if (auth.isSuperAdmin) return _engineYear; // may be null for super admin
    final user = auth.currentUser ?? {};
    return user['academicYear'] as String?;
  }

  Future<void> _loadEngineStatus() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isSuperAdmin && !_isAdmin(auth)) return;
    setState(() => _engineLoading = true);
    try {
      final year = _resolveEngineYear(auth);
      final data = await _engineService.getEngineStatus(academicYear: year);
      if (mounted) setState(() => _engineSettings = data);
    } catch (_) {
      // silently ignore — engine status is non-critical
    } finally {
      if (mounted) setState(() => _engineLoading = false);
    }
  }

  bool _isAdmin(AuthProvider auth) {
    final roles = (auth.currentUser?['roles'] as List<dynamic>?) ?? [];
    return roles.any((r) {
      final name = r is String ? r : (r as Map)['name']?.toString() ?? '';
      return name.contains('ADMIN');
    });
  }

  Future<void> _runEngine(
    Future<Map<String, dynamic>> Function() action,
    String label,
  ) async {
    setState(() {
      _engineRunning = true;
      _lastEngineActionResult = null;
    });
    try {
      final result = await action();
      final status = result['status'] ?? 'DONE';
      final msg = result['message'] ?? 'Completed';
      final time = result['executionTimeSeconds'] ?? '?';
      setState(() => _lastEngineActionResult = '$label → $status: $msg ($time s)');
      await _loadEngineStatus();
    } catch (e) {
      setState(() => _lastEngineActionResult = 'Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Engine error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _engineRunning = false);
    }
  }

  Future<void> _saveEngineMode(bool testMode) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final year = _resolveEngineYear(auth);
    setState(() => _engineSettings['testModeEnabled'] = testMode);
    try {
      await _engineService.updateSettings(
        {'testModeEnabled': testMode},
        academicYear: year,
      );
      await _loadEngineStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save mode: $e')),
        );
      }
    }
  }

  Future<void> _pickTestDate() async {
    DateTime initial = DateTime.now();
    final existing = _engineSettings['testDate'] as String?;
    if (existing != null && existing.isNotEmpty) {
      try { initial = DateTime.parse(existing); } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final year = _resolveEngineYear(auth);
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      setState(() => _engineSettings['testDate'] = dateStr);
      try {
        await _engineService.updateSettings({'testDate': dateStr}, academicYear: year);
      } catch (_) {}
    }
  }

  Future<void> _pickTestTime() async {
    final existing = _engineSettings['testTime'] as String?;
    TimeOfDay initial = TimeOfDay.now();
    if (existing != null && existing.isNotEmpty) {
      final parts = existing.split(':');
      if (parts.length >= 2) {
        initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final year = _resolveEngineYear(auth);
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      setState(() => _engineSettings['testTime'] = timeStr);
      try {
        await _engineService.updateSettings({'testTime': timeStr}, academicYear: year);
      } catch (_) {}
    }
  }

  String _fmt12(String? t) {
    if (t == null || t.isEmpty) return 'Not set';
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final tod = TimeOfDay(hour: h, minute: m);
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final hour12 = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    return '$hour12:${tod.minute.toString().padLeft(2, '0')} $period';
  }

  bool get _isTestMode => _engineSettings['testModeEnabled'] == true;

  String get _simulatedTimestamp {
    final d = _engineSettings['testDate'] as String?;
    final t = _engineSettings['testTime'] as String?;
    if (d == null || d.isEmpty) return 'Not configured';
    final time = (t != null && t.length >= 5) ? t.substring(0, 5) : '--:--';
    return '$d  $time';
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'DONE': return const Color(0xFF22C55E);
      case 'RUNNING': return const Color(0xFF3B82F6);
      case 'ERROR': return const Color(0xFFEF4444);
      case 'SKIPPED (HOLIDAY)': return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser ?? {};
    final List<dynamic> roles = currentUser['roles'] ?? [];
    final String? assignedYear = currentUser['academicYear'];

    final bool isSuperAdmin = roles.any((r) {
      final name = r is String ? r : (r as Map)['name']?.toString() ?? '';
      return name == 'ROLE_SUPER_ADMIN' || name == 'SUPER_ADMIN';
    });
    final bool isAdmin = roles.any((r) {
      final name = r is String ? r : (r as Map)['name']?.toString() ?? '';
      return name.contains('ADMIN');
    });
    final bool showEngineControl = isSuperAdmin || isAdmin;

    // Resolve engine year from user profile if not super admin
    if (!isSuperAdmin && assignedYear != null && _engineYear != assignedYear) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _engineYear = assignedYear);
      });
    }

    String titlePrefix = 'Admin';
    String welcomeText = 'System Admin';
    if (isSuperAdmin) {
      titlePrefix = 'Super Admin';
      welcomeText = 'Super Admin';
    } else if (assignedYear != null) {
      String cleanYear = assignedYear.replaceAll('_', ' ').toLowerCase();
      cleanYear = cleanYear
          .split(' ')
          .map((s) => s[0].toUpperCase() + s.substring(1))
          .join(' ');
      titlePrefix = '$cleanYear Admin';
      welcomeText = '$cleanYear Admin';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          '$titlePrefix Overview',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchStats();
              _loadEngineStatus();
            },
          ),
        ],
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load dashboard data',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchStats,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $welcomeText',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Here is a summary of the discipline system metrics.',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 20),

                        // ── Attendance Engine Control Center ──────────────────
                        if (showEngineControl) ...[
                          _buildEngineControlCard(isSuperAdmin, assignedYear),
                          const SizedBox(height: 20),
                        ],

                        // ── Stat Cards Grid ───────────────────────────────────
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                          children: [
                            _buildStatCard(
                              title: 'Students',
                              count: totalStudents.toString(),
                              icon: Icons.people_alt_rounded,
                              color: const Color(0xFF4A90E2),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const StudentsTab())),
                            ),
                            _buildStatCard(
                              title: 'Teachers',
                              count: totalTeachers.toString(),
                              icon: Icons.school_rounded,
                              color: const Color(0xFF34A853),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const TeachersTab())),
                            ),
                            _buildStatCard(
                              title: 'Departments',
                              count: totalDepartments.toString(),
                              icon: Icons.account_balance_rounded,
                              color: const Color(0xFFFBBC05),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const DepartmentsTab())),
                            ),
                            _buildStatCard(
                              title: 'Leaderboard',
                              count: 'Top',
                              icon: Icons.emoji_events_rounded,
                              color: const Color(0xFFE91E63),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SharedLeaderboardPage(
                                    title: 'Global Leaderboard',
                                    showFilters: true,
                                    showCurrentUserRank: false,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ── Attendance Engine Control Center Card ────────────────────────────────────

  Widget _buildEngineControlCard(bool isSuperAdmin, String? assignedYear) {
    final academicYearLabel = (_engineSettings['academicYear']?.toString() ??
            assignedYear ??
            'N/A')
        .replaceAll('_', ' ');

    final dailyStatus = _engineSettings['dailyEngineStatus'] as String? ?? 'WAITING';
    final weeklyStatus = _engineSettings['weeklyEngineStatus'] as String? ?? 'WAITING';
    final lastDaily = _engineSettings['lastDailyRun'] as String?;
    final lastWeekly = _engineSettings['lastWeeklyRun'] as String?;

    final effectiveDate = _isTestMode
        ? (_engineSettings['testDate'] as String? ?? 'Not set')
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    final effectiveTime = _isTestMode
        ? _fmt12(_engineSettings['testTime'] as String?)
        : _fmt12(
            '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:00');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: _engineLoading
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isTestMode
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                              : const Color(0xFF22C55E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isTestMode ? Icons.science : Icons.verified_outlined,
                          color: _isTestMode
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF22C55E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Attendance Engine Control',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      // Mode Toggle Chip
                      GestureDetector(
                        onTap: () => _saveEngineMode(!_isTestMode),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isTestMode
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isTestMode ? 'TEST MODE' : 'PRODUCTION',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Status Grid ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _statusItem(
                                'Academic Year', academicYearLabel, null),
                            ),
                            Expanded(
                              child: _statusItem(
                                'Engine Mode',
                                _isTestMode ? 'Test Mode' : 'Production',
                                _isTestMode
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _statusItem('Engine Date', effectiveDate, null)),
                            Expanded(child: _statusItem('Engine Time', effectiveTime, null)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _statusItem(
                                    'Daily Engine', dailyStatus, _statusColor(dailyStatus))),
                            Expanded(
                                child: _statusItem(
                                    'Weekly Engine', weeklyStatus, _statusColor(weeklyStatus))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _statusItem(
                                'Last Daily Run',
                                lastDaily != null
                                    ? lastDaily.replaceAll('T', ' ').substring(
                                        0,
                                        lastDaily.length > 16 ? 16 : lastDaily.length)
                                    : 'Never',
                                null,
                              ),
                            ),
                            Expanded(
                              child: _statusItem(
                                'Last Weekly Run',
                                lastWeekly != null
                                    ? lastWeekly.replaceAll('T', ' ').substring(
                                        0,
                                        lastWeekly.length > 16 ? 16 : lastWeekly.length)
                                    : 'Never',
                                null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Test Mode Expanded Section ───────────────────────────────
                  if (_isTestMode) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test Date & Time',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _dateTimeTile(
                                  label: 'Test Date',
                                  value: _engineSettings['testDate'] as String? ?? 'Not set',
                                  icon: Icons.calendar_today,
                                  onTap: _pickTestDate,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _dateTimeTile(
                                  label: 'Test Time',
                                  value: _fmt12(_engineSettings['testTime'] as String?),
                                  icon: Icons.access_time,
                                  onTap: _pickTestTime,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SIMULATED TIMESTAMP',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _simulatedTimestamp,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Manual Controls ─────────────────────────────────────
                    if (_lastEngineActionResult != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _lastEngineActionResult!,
                          style: const TextStyle(
                              fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    _engineRunning
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Engine running… check backend logs',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _engineBtn(
                                      'Run Daily',
                                      Icons.today,
                                      const Color(0xFF3B82F6),
                                      () => _runEngine(
                                        () => _engineService.runDailyEngine(
                                            academicYear: _engineYear),
                                        'Daily Engine',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _engineBtn(
                                      'Run Weekly',
                                      Icons.view_week,
                                      const Color(0xFF8B5CF6),
                                      () => _runEngine(
                                        () => _engineService.runWeeklyEngine(
                                            academicYear: _engineYear),
                                        'Weekly Engine',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _engineBtn(
                                      'Run Both',
                                      Icons.double_arrow,
                                      const Color(0xFF22C55E),
                                      () => _runEngine(
                                        () => _engineService.runBothEngines(
                                            academicYear: _engineYear),
                                        'Both Engines',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _engineBtn(
                                      'Reset State',
                                      Icons.restart_alt,
                                      const Color(0xFFEF4444),
                                      () => _runEngine(
                                        () => _engineService.resetEngineState(
                                            academicYear: _engineYear),
                                        'Reset',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _statusItem(String label, String value, Color? valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
        const SizedBox(height: 3),
        valueColor != null
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: valueColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: valueColor),
                ),
              )
            : Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _dateTimeTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade500)),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(icon, size: 14, color: const Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _engineBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
      ),
    );
  }

  // ── Stat Card ────────────────────────────────────────────────────────────────

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
