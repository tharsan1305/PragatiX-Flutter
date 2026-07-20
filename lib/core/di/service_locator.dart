import 'package:get_it/get_it.dart';

// Providers
import 'package:spdms_app/features/auth/providers/auth_provider.dart';
import 'package:spdms_app/features/xp/providers/xp_provider.dart';
import 'package:spdms_app/features/badge/providers/badge_provider.dart';
import 'package:spdms_app/features/activity/providers/activity_provider.dart';

// Services
import 'package:spdms_app/features/activity/services/activity_proxy_service.dart';
import 'package:spdms_app/features/activity/services/activity_service.dart';
import 'package:spdms_app/features/activity/services/group_activity_service.dart';
import 'package:spdms_app/features/admin/services/admin_proxy_service.dart';
import 'package:spdms_app/features/admin/services/admin_service.dart';
import 'package:spdms_app/features/auth/services/auth_service.dart';
import 'package:spdms_app/features/captain/services/captain_proxy_service.dart';
import 'package:spdms_app/features/captain/services/captain_service.dart';
import 'package:spdms_app/features/student/services/student_proxy_service.dart';
import 'package:spdms_app/features/student/services/student_service.dart';
import 'package:spdms_app/features/teacher/services/teacher_proxy_service.dart';
import 'package:spdms_app/features/teacher/services/teacher_service.dart';
import 'package:spdms_app/features/team/services/team_proxy_service.dart';
import 'package:spdms_app/features/leaderboard/services/leaderboard_service.dart';

// Repositories
import 'package:spdms_app/features/activity/repository/activity_repository.dart';
import 'package:spdms_app/features/badge/repository/badge_repository.dart';
import 'package:spdms_app/features/admin/repository/admin_repository.dart';
import 'package:spdms_app/features/auth/repository/auth_repository.dart';
import 'package:spdms_app/features/captain/repository/captain_repository.dart';
import 'package:spdms_app/features/student/repository/student_repository.dart';
import 'package:spdms_app/features/teacher/repository/teacher_repository.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // 1. Providers
  getIt.registerLazySingleton(() => AuthProvider());
  getIt.registerLazySingleton(() => XpProvider());
  getIt.registerLazySingleton(() => BadgeProvider());
  getIt.registerFactory(() => ActivityProvider(getIt<ActivityRepository>()));

  // 2. Services
  getIt.registerLazySingleton(() => AuthService());
  getIt.registerLazySingleton(() => AdminService(getIt<AuthProvider>()));
  getIt.registerLazySingleton(() => ActivityService(getIt<AuthProvider>().token ?? ''));
  getIt.registerLazySingleton(() => CaptainService(getIt<AuthProvider>()));
  getIt.registerLazySingleton(() => GroupActivityService(getIt<AuthProvider>().token ?? ''));
  getIt.registerLazySingleton(() => StudentService(getIt<AuthProvider>()));
  getIt.registerLazySingleton(() => TeacherService(getIt<AuthProvider>()));
  getIt.registerLazySingleton(() => LeaderboardService(getIt<AuthProvider>()));
  
  // Proxy Services
  getIt.registerLazySingleton(() => ActivityProxyService());
  getIt.registerLazySingleton(() => AdminProxyService());
  getIt.registerLazySingleton(() => CaptainProxyService());
  getIt.registerLazySingleton(() => StudentProxyService());
  getIt.registerLazySingleton(() => TeacherProxyService());
  getIt.registerLazySingleton(() => TeamProxyService());

  // 3. Repositories
  getIt.registerLazySingleton(() => ActivityRepository(getIt<ActivityService>()));
  getIt.registerLazySingleton(() => AdminRepository(getIt<AdminService>()));
  getIt.registerLazySingleton(() => BadgeRepository());
  getIt.registerLazySingleton(() => AuthRepository(getIt<AuthService>()));
  getIt.registerLazySingleton(() => CaptainRepository(getIt<CaptainService>()));
  getIt.registerLazySingleton(() => StudentRepository(getIt<StudentService>()));
  getIt.registerLazySingleton(() => TeacherRepository(getIt<TeacherService>()));
}
