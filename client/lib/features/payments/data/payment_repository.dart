import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../data/payment_models.dart';
import '../../dashboard/data/dashboard_repository.dart'; // Import Student model

class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository(this._apiClient);

  // Parent Actions
  Future<void> linkStudent(String enrollmentNumber) async {
    try {
      await _apiClient.dio.post('/parents/link-student', queryParameters: {'enrollment_number': enrollmentNumber});
    } catch (e) {
      throw e;
    }
  }

  Future<List<Student>> getMyStudents() async {
    try {
      final response = await _apiClient.dio.get('/parents/my-students');
      return (response.data as List).map((e) => Student.fromJson(e)).toList();
    } catch (e) {
      throw e;
    }
  }

  // Invoice Actions
  Future<List<Invoice>> getStudentInvoices(int studentId) async {
    try {
      final response = await _apiClient.dio.get('/invoices/student/$studentId');
      return (response.data as List).map((e) => Invoice.fromJson(e)).toList();
    } catch (e) {
      throw e;
    }
  }

  // Payment Actions
  Future<PaymentIntent> createPaymentIntent(int invoiceId, double amount) async {
    try {
      final response = await _apiClient.dio.post('/payments/create-intent', queryParameters: {'invoice_id': invoiceId, 'amount': amount});
      return PaymentIntent.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }

  Future<PaymentAttempt> confirmPayment(int invoiceId, double amount, String method) async {
    try {
      final response = await _apiClient.dio.post('/payments/confirm', data: {
        'invoice_id': invoiceId,
        'amount': amount,
        'provider': method
      });
      return PaymentAttempt.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }

  Future<List<PaymentAttempt>> getPaymentHistory() async {
     try {
      final response = await _apiClient.dio.get('/payments/history');
      return (response.data as List).map((e) => PaymentAttempt.fromJson(e)).toList();
    } catch (e) {
      throw e;
    }
  }
}
