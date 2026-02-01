import '../../../core/api_client.dart';
import '../../../core/offline_service.dart';
import '../../../core/offline_exceptions.dart';

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

  // --- HR ---
  Future<List<dynamic>> getStaff() async {
    final response = await apiClient.dio.get('/erp/hr/staff');
    return response.data;
  }

  Future<void> createStaff(Map<String, dynamic> data) async {
    await apiClient.dio.post('/erp/hr/staff', data: data);
  }

  Future<void> generatePayroll(String month, int year) async {
    await apiClient.dio.post('/erp/hr/payroll/generate', queryParameters: {
      'month': month,
      'year': year
    });
  }

  // --- Inventory ---
  Future<List<dynamic>> getInventory() async {
    final response = await apiClient.dio.get('/erp/inventory/items');
    return response.data;
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
}
