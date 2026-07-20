import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spdms_app/core/theme/app_theme.dart';
import 'package:spdms_app/features/xp/providers/xp_provider.dart';
import 'package:spdms_app/features/badge/providers/badge_provider.dart';
import 'package:spdms_app/features/student/pages/student_dashboard_page.dart';
import 'package:spdms_app/features/teacher/pages/teacher_dashboard.dart';
import 'package:spdms_app/features/admin/pages/admin_dashboard.dart';
import 'package:spdms_app/features/captain/pages/captain_dashboard_page.dart';
import 'package:spdms_app/features/auth/pages/login_page.dart';
import 'package:spdms_app/features/auth/providers/auth_provider.dart';
import 'package:spdms_app/core/di/service_locator.dart';
import 'package:spdms_app/shared/providers/student_search_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  
  final authProvider = getIt<AuthProvider>();
  await authProvider.checkAuthStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => getIt<XpProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<BadgeProvider>()),
        ChangeNotifierProvider(create: (_) => StudentSearchProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SPDMS – Student Discipline Monitor',
      theme: AppTheme.light(),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            final role = auth.role ?? '';
            final userType = auth.currentUser?['userType'] ?? '';
            final isCaptain = (auth.currentUser?['isCaptain'] ?? auth.currentUser?['captain'] ?? false) == true;

            if (role == 'ROLE_ADMIN') {
              return const AdminDashboard();
            } else if (userType == 'TEACHER' || role == 'ROLE_TEACHER' || role == 'ROLE_DISCIPLINE_COMMITTEE') {
              return const TeacherDashboard();
            } else if (userType == 'CAPTAIN' || isCaptain) {
              return const CaptainDashboardPage();
            } else if (role == 'ROLE_STUDENT' || userType == 'STUDENT' || role == 'STUDENT') {
              return const StudentDashboardPage();
            } else {
              // Unknown role or missing data
              return const LoginPage();
            }
          }
          return const LoginPage();
        },
      ),
    );
  }
}
