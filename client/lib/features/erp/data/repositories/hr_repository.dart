import '../../../../core/api_client.dart';
import '../models/erp_models.dart';

class HrRepository {
  final ApiClient apiClient;

  HrRepository(this.apiClient);

  Future<List<StaffProfile>> getStaff() async {
    final response = await apiClient.dio.get('/erp/hr/staff');
    return (response.data as List).map((e) => StaffProfile.fromJson(e)).toList();
  }

  Future<void> createStaff(Map<String, dynamic> data) async {
    await apiClient.dio.post('/erp/hr/staff/admin', data: data);
  }

  Future<void> generatePayroll(String month, int year) async {
    await apiClient.dio.post('/erp/hr/payroll/generate?month=$month&year=$year');
  }

  Future<List<PayrollRecord>> getPayrollHistory(String month, int year) async {
    final response = await apiClient.dio.get('/erp/hr/payroll/history?month=$month&year=$year');
    return (response.data as List).map((e) => PayrollRecord.fromJson(e)).toList();
  }

  Future<void> updatePayrollRecord(int payrollId, Map<String, dynamic> data) async {
    await apiClient.dio.patch('/erp/hr/payroll/$payrollId', data: data);
  }
}
