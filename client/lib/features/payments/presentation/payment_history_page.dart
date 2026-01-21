import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/payment_repository.dart';
import '../data/payment_models.dart';

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment History")),
      body: FutureBuilder<List<Payment>>(
        future: context.read<PaymentRepository>().getPaymentHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }
          final payments = snapshot.data ?? [];
          if (payments.isEmpty) return const Center(child: Text("No payments found."));

          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final p = payments[index];
              return ListTile(
                leading: const Icon(Icons.receipt),
                title: Text("TXN: ${p.transactionId}"),
                subtitle: Text(p.paymentDate.toString()),
                trailing: Text("\$${p.amountPaid}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              );
            },
          );
        },
      ),
    );
  }
}
