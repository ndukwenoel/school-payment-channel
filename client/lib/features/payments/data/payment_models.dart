import 'package:json_annotation/json_annotation.dart';

part 'payment_models.g.dart';

@JsonSerializable()
class Fee {
  final int id;
  final String title;
  final double amount;
  @JsonKey(name: 'due_date')
  final DateTime dueDate;
  final String status;
  @JsonKey(name: 'student_id')
  final int studentId;

  Fee({required this.id, required this.title, required this.amount, required this.dueDate, required this.status, required this.studentId});

  factory Fee.fromJson(Map<String, dynamic> json) => _$FeeFromJson(json);
  Map<String, dynamic> toJson() => _$FeeToJson(this);
}

@JsonSerializable()
class Payment {
  final int id;
  @JsonKey(name: 'fee_id')
  final int feeId;
  @JsonKey(name: 'amount_paid')
  final double amountPaid;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'transaction_id')
  final String transactionId;
  @JsonKey(name: 'payment_date')
  final DateTime paymentDate;

  Payment({required this.id, required this.feeId, required this.amountPaid, required this.paymentMethod, required this.transactionId, required this.paymentDate});

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentToJson(this);
}

@JsonSerializable()
class PaymentIntent {
  @JsonKey(name: 'client_secret')
  final String clientSecret;
  @JsonKey(name: 'transaction_id')
  final String transactionId;
  final String gateway;

  PaymentIntent({required this.clientSecret, required this.transactionId, required this.gateway});

  factory PaymentIntent.fromJson(Map<String, dynamic> json) => _$PaymentIntentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentIntentToJson(this);
}
