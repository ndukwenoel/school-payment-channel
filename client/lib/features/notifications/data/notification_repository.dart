import 'package:dio/dio.dart';
import '../../../../core/api_client.dart';
import 'notification_models.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<void> sendNotification(String email, String subject, String message) async {
    try {
      await _apiClient.dio.post('/notifications/send', data: {
        'recipient_email': email,
        'subject': subject,
        'message': message
      });
    } catch (e) {
      throw e;
    }
  }

  Future<List<NotificationLog>> getHistory() async {
    try {
      final response = await _apiClient.dio.get('/notifications/history');
      return (response.data as List).map((e) => NotificationLog.fromJson(e)).toList();
    } catch (e) {
      throw e;
    }
  }
}
