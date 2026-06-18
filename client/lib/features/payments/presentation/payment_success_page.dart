import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/payment_models.dart';
import '../../../core/theme.dart';

class PaymentSuccessPage extends StatelessWidget {
  final Invoice invoice;
  const PaymentSuccessPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildSuccessIcon(),
              const SizedBox(height: 24),
              const Text("Payment Processing", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text("Your transaction is being verified", style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
              const SizedBox(height: 32),
              _buildReceiptCard(),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                child: const Text(
                  "Verification can take up to 2 minutes.",
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blueVibrant, foregroundcolor: AppTheme.textDark),
                child: const Text("Download PDF Receipt"),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/invoices'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Return to Dashboard", style: TextStyle(color: AppTheme.textDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(color: AppTheme.limeLight, shape: BoxShape.circle),
      child: const Icon(Icons.check, size: 40, color: Colors.black),
    );
  }

  Widget _buildReceiptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("PAYMENT BREAKDOWN", style: TextStyle(color: AppTheme.bluePale, fontSize: 11, letterSpacing: 1)),
              Text("${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}", style: const TextStyle(color: AppTheme.textMuted.withOpacity(0.5), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 24),
          _buildReceiptRow(invoice.title, invoice.totalAmount),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.textMuted.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Paid", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("?${invoice.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.limeLight)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          Text("?${val.toStringAsFixed(2)}", style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
