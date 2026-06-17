import 'package:json_annotation/json_annotation.dart';

part 'payment_models.g.dart';

@JsonSerializable()
class InvoiceLineItem {
  final int id;
  @JsonKey(name: 'invoice_id')
  final int invoiceId;
  final String title;
  final double amount;

  InvoiceLineItem({
    required this.id,
    required this.invoiceId,
    required this.title,
    required this.amount,
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) => _$InvoiceLineItemFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceLineItemToJson(this);
}

@JsonSerializable()
class Invoice {
  final int id;
  final String title;
  @JsonKey(name: 'due_date')
  final DateTime dueDate;
  final String status;
  @JsonKey(name: 'student_id')
  final int studentId;
  @JsonKey(name: 'total_amount', defaultValue: 0.0)
  final double totalAmount;
  @JsonKey(name: 'line_items', defaultValue: [])
  final List<InvoiceLineItem> lineItems;

  Invoice({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.studentId,
    required this.totalAmount,
    required this.lineItems,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceToJson(this);
}

@JsonSerializable()
class PaymentAttempt {
  final int id;
  @JsonKey(name: 'invoice_id')
  final int invoiceId;
  final double amount;
  final String provider;
  final String status;
  @JsonKey(name: 'transaction_id')
  final String? transactionId;
  @JsonKey(name: 'payment_date')
  final DateTime paymentDate;

  PaymentAttempt({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.provider,
    required this.status,
    this.transactionId,
    required this.paymentDate,
  });

  factory PaymentAttempt.fromJson(Map<String, dynamic> json) => _$PaymentAttemptFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentAttemptToJson(this);
}

@JsonSerializable()
class PaymentIntent {
  @JsonKey(name: 'authorization_url')
  final String? authorizationUrl;
  @JsonKey(name: 'client_secret')
  final String? clientSecret;
  @JsonKey(name: 'reference')
  final String? reference;
  @JsonKey(name: 'transaction_id')
  final String? transactionId;
  final String provider;

  PaymentIntent({
    this.authorizationUrl,
    this.clientSecret,
    this.reference,
    this.transactionId,
    required this.provider,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) => _$PaymentIntentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentIntentToJson(this);
}
