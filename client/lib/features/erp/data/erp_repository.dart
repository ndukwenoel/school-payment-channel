import '../../../core/api_client.dart';
import '../../../core/offline_service.dart';
import '../../../core/offline_exceptions.dart';
import 'package:dio/dio.dart';

class ErpRepository {
  final ApiClient apiClient;
  final OfflineService? offlineService; // Optional for offline mode

  ErpRepository(this.apiClient, {this.offlineService});

  // --- Academic ---
  Future<List<dynamic>> getClassrooms() async {
    // Read-only usually requires net, or we cache. MVP: Requires Net.
    final response = await apiClient.dio.get('/erp/academic/classrooms');
    return response.data;
  }

  Future<void> createClassroom(Map<String, dynamic> data) async {
    await apiClient.dio.post('/erp/academic/classrooms', data: data);
  }

  Future<List<dynamic>> getSubjects() async {
    final response = await apiClient.dio.get('/erp/academic/subjects');
    return response.data;
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
  Future<List<dynamic>> getCourseTests({int? classroomId, int? subjectId}) async {
    final params = <String, dynamic>{};
    if (classroomId != null) params['classroom_id'] = classroomId;
    if (subjectId != null) params['subject_id'] = subjectId;
    final response = await apiClient.dio.get('/erp/academic/tests', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getCourseTest(int testId) async {
    final response = await apiClient.dio.get('/erp/academic/tests/$testId');
    return response.data;
  }

  Future<void> createCourseTest(Map<String, dynamic> data) async {
    await apiClient.dio.post('/erp/academic/tests', data: data);
  }

  Future<void> deleteCourseTest(int testId) async {
    await apiClient.dio.delete('/erp/academic/tests/$testId');
  }

  // --- TestResult ---
  Future<List<dynamic>> getTestResults(int testId) async {
    final response = await apiClient.dio.get('/erp/academic/tests/$testId/results');
    return response.data;
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

  Future<List<dynamic>> getStudentTestResults(int studentId) async {
    final response = await apiClient.dio.get('/erp/academic/students/$studentId/results');
    return response.data;
  }

  // --- StudentDocument ---
  Future<List<dynamic>> getStudentDocuments(int studentId) async {
    final response = await apiClient.dio.get('/erp/academic/students/$studentId/documents');
    return response.data;
  }

  Future<void> addStudentDocument(int studentId, Map<String, dynamic> data) async {
    await apiClient.dio.post('/erp/academic/students/$studentId/documents', data: data);
  }

  // --- HR / Payroll ---
  Future<List<dynamic>> getStaff() async {
    final response = await apiClient.dio.get('/erp/hr/staff');
    return response.data;
  }

  Future<void> createStaff(Map<String, dynamic> data) async {
    await apiClient.dio.post('/erp/hr/staff/admin', data: data);
  }

  Future<void> generatePayroll(String month, int year) async {
    await apiClient.dio.post('/erp/hr/payroll/generate?month=$month&year=$year');
  }

  Future<List<dynamic>> getPayrollHistory(String month, int year) async {
    final response = await apiClient.dio.get('/erp/hr/payroll/history?month=$month&year=$year');
    return response.data;
  }

  Future<void> updatePayrollRecord(int payrollId, Map<String, dynamic> data) async {
    await apiClient.dio.patch('/erp/hr/payroll/$payrollId', data: data);
  }

  // --- Inventory ---
  Future<List<dynamic>> getInventory() async {
    final response = await apiClient.dio.get('/erp/inventory/items');
    return response.data;
  }

  Future<void> createInventoryItem(Map<String, dynamic> data) async {
    await apiClient.dio.post('/erp/inventory/items', data: data);
  }

  Future<void> updateStock(int itemId, int change) async {
    await apiClient.dio.patch('/erp/inventory/items/$itemId/stock?quantity_change=$change');
  }

  // --- Collaboration ---
  Future<void> createBroadcast(Map<String, dynamic> data) async {
    await apiClient.dio.post('/erp/collaboration/broadcasts', data: data);
  }

  Future<void> uploadResource(Map<String, dynamic> data) async {
    try {
      await apiClient.dio.post('/erp/collaboration/resources', data: data);
    } catch (e) {
      if (offlineService != null) {
        await offlineService!.queueAction('upload', data);
        throw OfflineQueuedException("No Network. Resource saved offline.");
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getPendingResources() async {
    final response = await apiClient.dio.get('/erp/collaboration/resources/pending');
    return response.data;
  }

  Future<void> updateResourceStatus(int id, String status) async {
    await apiClient.dio.put('/erp/collaboration/resources/$id/status?status=$status');
  }

  // --- Student Registry ---
  Future<List<dynamic>> getStudents() async {
    final response = await apiClient.dio.get('/students/');
    return response.data;
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
