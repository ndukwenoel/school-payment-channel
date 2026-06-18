// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvoiceLineItem _$InvoiceLineItemFromJson(Map<String, dynamic> json) =>
    InvoiceLineItem(
      id: (json['id'] as num).toInt(),
      invoiceId: (json['invoice_id'] as num).toInt(),
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$InvoiceLineItemToJson(InvoiceLineItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoice_id': instance.invoiceId,
      'title': instance.title,
      'amount': instance.amount,
    };

Invoice _$InvoiceFromJson(Map<String, dynamic> json) => Invoice(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String,
      studentId: (json['student_id'] as num).toInt(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      lineItems: (json['line_items'] as List<dynamic>?)
              ?.map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$InvoiceToJson(Invoice instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'due_date': instance.dueDate.toIso8601String(),
      'status': instance.status,
      'student_id': instance.studentId,
      'total_amount': instance.totalAmount,
      'line_items': instance.lineItems,
    };

PaymentAttempt _$PaymentAttemptFromJson(Map<String, dynamic> json) =>
    PaymentAttempt(
      id: (json['id'] as num).toInt(),
      invoiceId: (json['invoice_id'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      provider: json['provider'] as String,
      status: json['status'] as String,
      transactionId: json['transaction_id'] as String?,
      paymentDate: DateTime.parse(json['payment_date'] as String),
    );

Map<String, dynamic> _$PaymentAttemptToJson(PaymentAttempt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoice_id': instance.invoiceId,
      'amount': instance.amount,
      'provider': instance.provider,
      'status': instance.status,
      'transaction_id': instance.transactionId,
      'payment_date': instance.paymentDate.toIso8601String(),
    };

PaymentIntent _$PaymentIntentFromJson(Map<String, dynamic> json) =>
    PaymentIntent(
      authorizationUrl: json['authorization_url'] as String?,
      clientSecret: json['client_secret'] as String?,
      reference: json['reference'] as String?,
      transactionId: json['transaction_id'] as String?,
      provider: json['provider'] as String,
    );

Map<String, dynamic> _$PaymentIntentToJson(PaymentIntent instance) =>
    <String, dynamic>{
      'authorization_url': instance.authorizationUrl,
      'client_secret': instance.clientSecret,
      'reference': instance.reference,
      'transaction_id': instance.transactionId,
      'provider': instance.provider,
    };
