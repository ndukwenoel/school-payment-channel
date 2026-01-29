import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dashboard_repository.g.dart';

@JsonSerializable()
class School {
  final int id;
  final String name;
  final String? address;
  @JsonKey(name: 'contact_email')
  final String? contactEmail;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;

  School({required this.id, required this.name, this.address, this.contactEmail, this.logoUrl});

  factory School.fromJson(Map<String, dynamic> json) => _$SchoolFromJson(json);
  Map<String, dynamic> toJson() => _$SchoolToJson(this);
}

@JsonSerializable()
class Student {
  final int id;
  @JsonKey(name: 'enrollment_number')
  final String enrollmentNumber;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String grade;
  @JsonKey(name: 'parent_id')
  final int parentId;

  Student({required this.id, required this.enrollmentNumber, required this.fullName, required this.grade, required this.parentId});

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);
  Map<String, dynamic> toJson() => _$StudentToJson(this);
}

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<School> getMySchool() async {
    try {
      final response = await _apiClient.dio.get('/schools/me');
      return School.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }

  Future<School> updateSchool(String name, String address, String email) async {
     try {
      final response = await _apiClient.dio.put('/schools/me', data: {
        'name': name,
        'address': address,
        'contact_email': email
      });
      return School.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }

  Future<List<Student>> getStudents() async {
    try {
      final response = await _apiClient.dio.get('/students/');
      return (response.data as List).map((e) => Student.fromJson(e)).toList();
    } catch (e) {
      throw e;
    }
  }
  
  Future<void> createFee(String title, double amount, DateTime dueDate, int studentId) async {
    try {
      await _apiClient.dio.post('/fees/', data: {
        'title': title,
        'amount': amount,
        'due_date': dueDate.toIso8601String(),
        'student_id': studentId,
        'discount_id': null // Optional
      });
    } catch (e) {
      throw e;
    }
  }

  Future<void> createBulkFees(String title, double amount, DateTime dueDate, String grade) async {
    try {
      await _apiClient.dio.post('/fees/bulk', data: {
        'title': title,
        'amount': amount,
        'due_date': dueDate.toIso8601String(),
        'grade': grade,
        'discount_id': null
      });
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiClient.dio.get('/reports/summary');
      return response.data;
    } catch (e) {
       // Return empty stats if fail
       return {
         'total_students': 0,
         'total_revenue': 0.0,
         'outstanding_fees': 0.0
       };
    }
  }

}
