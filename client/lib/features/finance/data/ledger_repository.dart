import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

class LedgerRepository {
  final ApiClient _apiClient;

  LedgerRepository(this._apiClient);

  Future<List<dynamic>> getAccounts() async {
    final response = await _apiClient.dio.get('/ledger/accounts');
    return response.data;
  }

  Future<Map<String, dynamic>> createAccount(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/ledger/accounts', data: data);
    return response.data;
  }

  Future<List<dynamic>> getTransactions() async {
    final response = await _apiClient.dio.get('/ledger/transactions');
    return response.data;
  }

  Future<List<dynamic>> getPostingRules() async {
    final response = await _apiClient.dio.get('/ledger/rules');
    return response.data;
  }

  Future<Map<String, dynamic>> createPostingRule(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/ledger/rules', data: data);
    return response.data;
  }
}
