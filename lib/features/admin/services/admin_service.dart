import 'dart:convert';
import 'package:spdms_app/core/utils/api_client.dart' as http;
import 'package:spdms_app/features/auth/providers/auth_provider.dart';
import 'package:spdms_app/core/config/api_config.dart';
import 'package:spdms_app/core/exceptions/api_exception.dart';

class AdminService {
  final AuthProvider authProvider;
  AdminService(this.authProvider);

  String get token => authProvider.token ?? '';

  Future<http.Response> get(String endpoint) async {
    return http.get(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: {'Authorization': 'Bearer $token'});
  }

  Future<http.Response> post(String endpoint, Object body) async {
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String endpoint, Object body) async {
    return http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String endpoint) async {
    return http.delete(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: {'Authorization': 'Bearer $token'});
  }
}
