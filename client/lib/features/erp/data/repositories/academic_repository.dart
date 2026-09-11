import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../../../../core/offline_service.dart';
import '../../../../core/offline_exceptions.dart';
import '../models/erp_models.dart';

class AcademicRepository {
  final ApiClient apiClient;
  final OfflineService? offlineService;

  AcademicRepository(this.apiClient, {this.offlineService});

  // --- Academic ---
  Future<List<Classroom>> getClassrooms() async {
    final response = await apiClient.dio.get('/erp/academic/classrooms');
    return (response.data as List).map((e) => Classroom.fromJson(e)).toList();
  }

  Future<void> createClassroom(Map<String, dynamic> data) async {
    await apiClient.dio.post('/erp/academic/classrooms', data: data);
  }

  Future<List<Subject>> getSubjects() async {
    final response = await apiClient.dio.get('/erp/academic/subjects');
    return (response.data as List).map((e) => Subject.fromJson(e)).toList();
  }

  Future<void> markAttendance(Map<String, dynamic> data) async {
    try {
      await apiClient.dio.post('/erp/academic/attendance', data: data);
    } catch (e) {
      if (offlineService != null) {
        await offlineService!.queueAction('attendance', data);
        throw OfflineQueuedException("No Network. Attendance saved offline.");
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getStudentAttendance(int studentId) async {
    final response = await apiClient.dio.get('/erp/academic/attendance/student/$studentId');
    return response.data;
  }

  Future<Map<String, dynamic>> generateTermReport(int classId, String term, String year) async {
    final response = await apiClient.dio.get('/erp/academic/report/term', queryParameters: {
      'class_id': classId,
      'term': term,
      'academic_year': year
    });
    return response.data;
  }

  // --- CourseTest ---
  Future<List<CourseTest>> getCourseTests({int? classroomId, int? subjectId}) async {
    final params = <String, dynamic>{};
    if (classroomId != null) params['classroom_id'] = classroomId;
    if (subjectId != null) params['subject_id'] = subjectId;
    final response = await apiClient.dio.get('/erp/academic/tests', queryParameters: params);
    return (response.data as List).map((e) => CourseTest.fromJson(e)).toList();
  }

  Future<CourseTest> getCourseTest(int testId) async {
    final response = await apiClient.dio.get('/erp/academic/tests/$testId');
    return CourseTest.fromJson(response.data);
  }

  Future<void> createCourseTest(Map<String, dynamic> data) async {
    await apiClient.dio.post('/erp/academic/tests', data: data);
  }

  Future<void> deleteCourseTest(int testId) async {
    await apiClient.dio.delete('/erp/academic/tests/$testId');
  }

  // --- TestResult ---
  Future<List<TestResult>> getTestResults(int testId) async {
    final response = await apiClient.dio.get('/erp/academic/tests/$testId/results');
    return (response.data as List).map((e) => TestResult.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> recordBulkResults(
    int testId,
    List<Map<String, dynamic>> results,
  ) async {
    final response = await apiClient.dio.post(
      '/erp/academic/tests/$testId/results/bulk',
      data: {'results': results},
    );
    return response.data;
  }

  Future<List<TestResult>> getStudentTestResults(int studentId) async {
    final response = await apiClient.dio.get('/erp/academic/students/$studentId/results');
    return (response.data as List).map((e) => TestResult.fromJson(e)).toList();
  }

  // --- StudentDocument ---
  Future<List<dynamic>> getStudentDocuments(int studentId) async {
    final response = await apiClient.dio.get('/erp/academic/students/$studentId/documents');
    return response.data;
  }

  Future<void> addStudentDocument(int studentId, Map<String, dynamic> data) async {
    await apiClient.dio.post('/erp/academic/students/$studentId/documents', data: data);
  }

  // --- Student Registry ---
  Future<List<Student>> getStudents() async {
    final response = await apiClient.dio.get('/students/');
    return (response.data as List).map((e) => Student.fromJson(e)).toList();
  }

  Future<void> createStudent(Map<String, dynamic> data) async {
    await apiClient.dio.post('/students/admin', data: data);
  }

  Future<void> updateStudent(int id, Map<String, dynamic> data) async {
    await apiClient.dio.patch('/students/$id', data: data);
  }

  Future<Map<String, dynamic>> importStudents(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await apiClient.dio.post('/students/import', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> promoteStudents(String currentGrade, String newGrade) async {
    final response = await apiClient.dio.post('/students/promote', data: {
      'current_grade': currentGrade,
      'new_grade': newGrade,
    });
    return response.data;
  }
}
