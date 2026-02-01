import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/payment_models.dart';
import '../../../core/theme.dart';

class PaymentMethodPage extends StatefulWidget {
  final Fee fee;
  const PaymentMethodPage({super.key, required this.fee});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String _selectedMethod = 'Apple Pay';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNavHeader(context),
              const SizedBox(height: 24),
              _buildSectionLabel("DIGITAL WALLETS"),
              _buildMethodOption("Apple Pay", "Default Wallet", Icons.apple, Colors.black),
              _buildMethodOption("Google Pay", "Fast Checkout", Icons.g_mobiledata, Colors.white, iconTextColor: Colors.blue),
              const SizedBox(height: 24),
              _buildSectionLabel("SAVED CARDS"),
              _buildMethodOption("Visa Ending in 4242", "Expires 12/26", Icons.credit_card, Colors.blueAccent),
              _buildMethodOption("Mastercard Platinum", "Expires 05/25", Icons.credit_card, Colors.redAccent),
              const SizedBox(height: 24),
              _buildSectionLabel("BANK ACCOUNTS"),
              _buildMethodOption("Chase Savings", "Direct Debit •••• 8812", Icons.account_balance, AppTheme.greenDeep),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildConfirmDock(),
    );
  }

  Widget _buildNavHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 16),
        const Text("PAYMENT METHOD", style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.5)),
    );
  }

  Widget _buildMethodOption(String name, String sub, IconData icon, Color iconBg, {Color? iconTextColor}) {
    bool selected = _selectedMethod == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1E36) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: selected ? AppTheme.blueVibrant : Colors.transparent, width: 4)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(4)),
              child: Icon(icon, color: iconTextColor ?? Colors.white, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppTheme.blueVibrant : Colors.white.withOpacity(0.2), width: 2),
              ),
              child: selected ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.blueVibrant, shape: BoxShape.circle))) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmDock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppTheme.voidBlack, AppTheme.voidBlack.withOpacity(0)],
          stops: const [0.8, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🔒 SECURE 256-BIT SSL ENCRYPTION", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: const BorderSide(color: Colors.white24, style: BorderStyle.solid),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("+ Add New Payment Method", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.push('/payment-success', extra: widget.fee),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Continue to Pay"),
                Row(
                  children: [
                    Text("\$${widget.fee.amount.toStringAsFixed(2)}"),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
