import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:spdms_app/features/auth/providers/auth_provider.dart';
import 'package:spdms_app/features/auth/repository/auth_repository.dart';
import 'package:spdms_app/features/admin/services/admin_service.dart';
import 'package:spdms_app/features/admin/repository/admin_repository.dart';
import 'package:spdms_app/features/activity/services/activity_service.dart';
import 'package:spdms_app/features/activity/repository/activity_repository.dart';

// HTTP Client Mock
class MockHttpClient extends Mock implements http.Client {}

// Provider Mocks
class MockAuthProvider extends Mock implements AuthProvider {}

// Service Mocks
class MockAdminService extends Mock implements AdminService {}
class MockActivityService extends Mock implements ActivityService {}

// Repository Mocks
class MockAdminRepository extends Mock implements AdminRepository {}
class MockActivityRepository extends Mock implements ActivityRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

// Fake Classes for Fallbacks (if needed for typed parameters like Uri)
class FakeUri extends Fake implements Uri {}

void registerFallbackValues() {
  registerFallbackValue(FakeUri());
  // Register Map<String, dynamic> fallback for request bodies
  registerFallbackValue(<String, dynamic>{});
}
