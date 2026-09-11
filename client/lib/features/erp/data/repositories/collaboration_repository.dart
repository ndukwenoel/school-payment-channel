import '../../../../core/api_client.dart';
import '../../../../core/offline_service.dart';
import '../../../../core/offline_exceptions.dart';
import '../models/erp_models.dart';

class CollaborationRepository {
  final ApiClient apiClient;
  final OfflineService? offlineService;

  CollaborationRepository(this.apiClient, {this.offlineService});

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

  Future<List<AcademicResource>> getPendingResources() async {
    final response = await apiClient.dio.get('/erp/collaboration/resources/pending');
    return (response.data as List).map((e) => AcademicResource.fromJson(e)).toList();
  }

  Future<void> updateResourceStatus(int id, String status) async {
    await apiClient.dio.put('/erp/collaboration/resources/$id/status?status=$status');
  }
}
