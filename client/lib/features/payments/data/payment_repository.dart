import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import '../data/payment_models.dart';
import '../../dashboard/data/dashboard_models.dart'; // Import Student model

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

  // Fee Actions
  Future<List<Fee>> getStudentFees(int studentId) async {
    try {
      final response = await _apiClient.dio.get('/fees/student/$studentId');
      return (response.data as List).map((e) => Fee.fromJson(e)).toList();
    } catch (e) {
      throw e;
    }
  }

  // Payment Actions
  Future<PaymentIntent> createPaymentIntent(int feeId, double amount) async {
    try {
      final response = await _apiClient.dio.post('/payments/create-intent', queryParameters: {'fee_id': feeId, 'amount': amount});
      return PaymentIntent.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }

  Future<Payment> confirmPayment(int feeId, double amount, String method) async {
    try {
      final response = await _apiClient.dio.post('/payments/confirm', data: {
        'fee_id': feeId,
        'amount_paid': amount,
        'payment_method': method
      });
      return Payment.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }

  Future<List<Payment>> getPaymentHistory() async {
     try {
      final response = await _apiClient.dio.get('/payments/history');
      return (response.data as List).map((e) => Payment.fromJson(e)).toList();
    } catch (e) {
      throw e;
    }
  }
}
