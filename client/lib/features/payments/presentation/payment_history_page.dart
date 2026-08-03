import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/payment_repository.dart';
import '../data/payment_models.dart';
import '../../../core/theme.dart';

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(title: const Text("PAYMENT HISTORY")),
      body: FutureBuilder<List<PaymentAttempt>>(
        future: context.read<PaymentRepository>().getPaymentHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          final payments = snapshot.data ?? [];
          if (payments.isEmpty) {
            return Center(
              child: Text("No transaction records found.", style: TextStyle(color: AppTheme.textMuted50)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final p = payments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.blueVibrant.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.receipt_long, color: AppTheme.blueVibrant, size: 20),
                  ),
                  title: Text(
                    "TXN-${p.transactionId?.toUpperCase() ?? 'UNKNOWN'}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                  ),
                  subtitle: Text(
                    "${p.paymentDate.day}/${p.paymentDate.month}/${p.paymentDate.year}",
                    style: const TextStyle(color: AppTheme.textMuted50, fontSize: 12),
                  ),
                  trailing: Text(
                    "₦${p.amount.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.limeLight, fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
