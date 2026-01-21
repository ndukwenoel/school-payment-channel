// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Fee _$FeeFromJson(Map<String, dynamic> json) => Fee(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String,
      studentId: (json['student_id'] as num).toInt(),
    );

Map<String, dynamic> _$FeeToJson(Fee instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'amount': instance.amount,
      'due_date': instance.dueDate.toIso8601String(),
      'status': instance.status,
      'student_id': instance.studentId,
    };

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
      id: (json['id'] as num).toInt(),
      feeId: (json['fee_id'] as num).toInt(),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      transactionId: json['transaction_id'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
    );

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
      'id': instance.id,
      'fee_id': instance.feeId,
      'amount_paid': instance.amountPaid,
      'payment_method': instance.paymentMethod,
      'transaction_id': instance.transactionId,
      'payment_date': instance.paymentDate.toIso8601String(),
    };

PaymentIntent _$PaymentIntentFromJson(Map<String, dynamic> json) =>
    PaymentIntent(
      clientSecret: json['client_secret'] as String,
      transactionId: json['transaction_id'] as String,
      gateway: json['gateway'] as String,
    );

Map<String, dynamic> _$PaymentIntentToJson(PaymentIntent instance) =>
    <String, dynamic>{
      'client_secret': instance.clientSecret,
      'transaction_id': instance.transactionId,
      'gateway': instance.gateway,
    };
