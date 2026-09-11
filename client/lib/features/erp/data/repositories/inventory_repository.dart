import '../../../../core/api_client.dart';
import '../models/erp_models.dart';

class InventoryRepository {
  final ApiClient apiClient;

  InventoryRepository(this.apiClient);

  Future<List<InventoryItem>> getInventory() async {
    final response = await apiClient.dio.get('/erp/inventory/items');
    return (response.data as List).map((e) => InventoryItem.fromJson(e)).toList();
  }

  Future<void> createInventoryItem(Map<String, dynamic> data) async {
    await apiClient.dio.post('/erp/inventory/items', data: data);
  }

  Future<void> updateStock(int itemId, int change) async {
    await apiClient.dio.patch('/erp/inventory/items/$itemId/stock?quantity_change=$change');
  }
}
