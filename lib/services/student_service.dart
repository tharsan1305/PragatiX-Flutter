import 'package:spdms_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';

class StudentService {

  static const String baseUrl =
      ApiConfig.baseUrl;

  Future<List<Student>> getStudents() async {

    final response = await http.get(
      Uri.parse("$baseUrl/students"),
    );

    if (response.statusCode == 200) {

      List data = jsonDecode(response.body);

      return data
          .map((e) => Student.fromJson(e))
          .toList();
    }

    throw Exception("Failed to load students");
  }
}