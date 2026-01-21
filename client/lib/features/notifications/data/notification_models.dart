import 'package:json_annotation/json_annotation.dart';

part 'notification_models.g.dart';

@JsonSerializable()
class NotificationLog {
  final int id;
  @JsonKey(name: 'recipient_email')
  final String recipientEmail;
  final String subject;
  final String message;
  final String status;
  @JsonKey(name: 'sent_at')
  final DateTime sentAt;

  NotificationLog({required this.id, required this.recipientEmail, required this.subject, required this.message, required this.status, required this.sentAt});

  factory NotificationLog.fromJson(Map<String, dynamic> json) => _$NotificationLogFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationLogToJson(this);
}

@JsonSerializable()
class DashboardStats {
  @JsonKey(name: 'total_students')
  final int totalStudents;
  @JsonKey(name: 'total_revenue')
  final double totalRevenue;
  @JsonKey(name: 'outstanding_fees')
  final double outstandingFees;
  @JsonKey(name: 'total_fees_created')
  final double totalFeesCreated;

  DashboardStats({required this.totalStudents, required this.totalRevenue, required this.outstandingFees, required this.totalFeesCreated});

  factory DashboardStats.fromJson(Map<String, dynamic> json) => _$DashboardStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardStatsToJson(this);
}
