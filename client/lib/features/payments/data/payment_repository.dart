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

  Future<PaymentAttempt> submitManualPayment(int invoiceId, double amount, String referenceNumber, {String? receiptUrl}) async {
    try {
      final response = await _apiClient.dio.post('/payments/manual-transfer', data: {
        'invoice_id': invoiceId,
        'amount': amount,
        'reference_number': referenceNumber,
        if (receiptUrl != null) 'receipt_url': receiptUrl,
      });
      return PaymentAttempt.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }

  Future<PaymentAttempt> verifyManualPayment(int paymentId) async {
    try {
      final response = await _apiClient.dio.post('/payments/$paymentId/verify');
      return PaymentAttempt.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }

  // Installment Plans
  Future<void> createInstallmentPlan(int invoiceId, List<Map<String, dynamic>> installments) async {
    await _apiClient.dio.post('/invoices/$invoiceId/installments', data: {
      'installments': installments,
    });
  }

  // Virtual Accounts
  Future<Map<String, dynamic>> requestVirtualAccount(int studentId) async {
    final response = await _apiClient.dio.post('/virtual-accounts/request/$studentId');
    return response.data;
  }

  // Payment Bundles
  Future<Map<String, dynamic>> createPaymentBundle(List<int> invoiceIds) async {
    final response = await _apiClient.dio.post('/payments/bundle', data: {
      'invoice_ids': invoiceIds,
    });
    return response.data;
  }

  // Payment Plan Requests
  Future<Map<String, dynamic>> requestPaymentPlan(int invoiceId, List<Map<String, dynamic>> proposedInstallments, String reason) async {
    final response = await _apiClient.dio.post('/invoices/$invoiceId/plan-requests', data: {
      'proposed_installments': proposedInstallments,
      'reason': reason,
    });
    return response.data;
  }

  Future<List<dynamic>> getPlanRequests() async {
    final response = await _apiClient.dio.get('/invoices/plan-requests/all');
    return response.data as List;
  }

  Future<void> approvePlanRequest(int requestId) async {
    await _apiClient.dio.post('/invoices/plan-requests/$requestId/approve');
  }

  Future<void> rejectPlanRequest(int requestId) async {
    await _apiClient.dio.post('/invoices/plan-requests/$requestId/reject');
  }

  // Credit Balance (Wallet) & Auto-Pay
  Future<Map<String, dynamic>> topUpWallet(double amount, String reference) async {
    final response = await _apiClient.dio.post('/parents/wallet/top-up', data: {
      'amount': amount,
      'reference': reference,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> toggleAutoPay() async {
    final response = await _apiClient.dio.post('/parents/wallet/toggle-autopay');
    return response.data;
  }

  Future<Map<String, dynamic>> payWithBalance(int invoiceId) async {
    final response = await _apiClient.dio.post('/invoices/$invoiceId/pay-with-balance');
    return response.data;
  }
}
