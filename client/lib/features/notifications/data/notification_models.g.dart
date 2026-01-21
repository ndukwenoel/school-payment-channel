// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationLog _$NotificationLogFromJson(Map<String, dynamic> json) =>
    NotificationLog(
      id: (json['id'] as num).toInt(),
      recipientEmail: json['recipient_email'] as String,
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: json['status'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );

Map<String, dynamic> _$NotificationLogToJson(NotificationLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recipient_email': instance.recipientEmail,
      'subject': instance.subject,
      'message': instance.message,
      'status': instance.status,
      'sent_at': instance.sentAt.toIso8601String(),
    };

DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) =>
    DashboardStats(
      totalStudents: (json['total_students'] as num).toInt(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      outstandingFees: (json['outstanding_fees'] as num).toDouble(),
      totalFeesCreated: (json['total_fees_created'] as num).toDouble(),
    );

Map<String, dynamic> _$DashboardStatsToJson(DashboardStats instance) =>
    <String, dynamic>{
      'total_students': instance.totalStudents,
      'total_revenue': instance.totalRevenue,
      'outstanding_fees': instance.outstandingFees,
      'total_fees_created': instance.totalFeesCreated,
    };
