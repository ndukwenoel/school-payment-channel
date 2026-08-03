import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/payment_models.dart';
import '../data/payment_repository.dart';
import '../../../core/theme.dart';

class PaymentMethodPage extends StatefulWidget {
  final Invoice invoice;
  const PaymentMethodPage({super.key, required this.invoice});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String _selectedMethod = 'Paystack Checkout';
  bool _isLoading = false;

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<PaymentRepository>();
      if (_selectedMethod == 'Virtual Account') {
        final result = await repo.requestVirtualAccount(widget.invoice.studentId);
        if (mounted) {
          _showVirtualAccountDialog(result);
        }
        return;
      }
      
      if (_selectedMethod == 'Offline Bank Transfer') {
        if (mounted) {
          _showOfflineTransferDialog();
        }
        return;
      }

      final intent = await repo.createPaymentIntent(widget.invoice.id, widget.invoice.totalAmount);
      
      if (intent.authorizationUrl != null) {
        final uri = Uri.parse(intent.authorizationUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          // Show dialog instructing the user to return here after completing payment
          if (mounted) {
             _showAwaitingPaymentDialog();
          }
        } else {
          throw Exception('Could not launch payment URL');
        }
      } else {
        // Fallback for Mock or intent without URL
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Intent created. Processing mock payment...")));
           context.push('/payment-success', extra: widget.invoice);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAwaitingPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Complete Payment"),
        content: const Text("Please complete the payment in your browser. Once done, return to the app and click Verify."),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/payment-success', extra: widget.invoice);
            },
            child: const Text("I have paid"),
          ),
        ],
      ),
    );
  }

  void _showVirtualAccountDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Wire Transfer Instructions"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Please transfer the total amount to the following dedicated account:"),
            SizedBox(height: 16),
            Text("Bank: ${data['bank_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Account Name: ${data['account_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Account Number: ${data['account_number']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.blueVibrant)),
            SizedBox(height: 16),
            const Text("Your invoice will automatically be marked as paid once the transfer is received.", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop(); // Go back to invoices list
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  void _showOfflineTransferDialog() {
    final TextEditingController refController = TextEditingController();
    bool submitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Offline Bank Transfer"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Please transfer the total amount to:"),
                SizedBox(height: 8),
                const Text("Bank: Opay", style: TextStyle(fontWeight: FontWeight.bold)),
                const Text("Account Name: School Payment Gateway", style: TextStyle(fontWeight: FontWeight.bold)),
                const Text("Account No: 1234567890", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.blueVibrant)),
                SizedBox(height: 16),
                const Text("After transferring, enter the Session ID or Reference Number below to auto-reconcile."),
                SizedBox(height: 8),
                TextField(
                  controller: refController,
                  decoration: InputDecoration(
                    labelText: "Reference / Session ID",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                const Text("(Optional) Upload Receipt: [Mocked Button]"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () {
                  setState(() => _isLoading = false); // Reset loading state
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: submitting ? null : () async {
                  if (refController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a reference number")));
                    return;
                  }
                  
                  setDialogState(() => submitting = true);
                  try {
                    final repo = context.read<PaymentRepository>();
                    await repo.submitManualPayment(
                      widget.invoice.id, 
                      widget.invoice.totalAmount, 
                      refController.text,
                      receiptUrl: 'https://mock-receipt-url.com/receipt.png'
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment submitted for verification")));
                    context.push('/payment-success', extra: widget.invoice);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  } finally {
                    if (mounted) { // outer widget mounted check is okay here since we don't use context, but for safety let's check both or just setState if mounted
                      setDialogState(() => submitting = false);
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Submit Verification"),
              ),
            ],
          );
        }
      ),
    );
  }

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
              SizedBox(height: 24),
              _buildSectionLabel("SUPPORTED METHODS"),
              _buildMethodOption("Paystack Checkout", "Card, Bank Transfer, USSD", Icons.credit_card, Colors.blueAccent),
              _buildMethodOption("Virtual Account", "Dedicated Bank Account", Icons.account_balance, AppTheme.greenDeep),
              _buildMethodOption("Offline Bank Transfer", "Manual Verification", Icons.receipt_long, AppTheme.greenDeep),
              SizedBox(height: 100),
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
          child: const Icon(Icons.arrow_back_ios_new, size: 14, color: AppTheme.textDark),
        ),
        SizedBox(width: 16),
        const Text("PAYMENT METHOD", style: TextStyle(color: AppTheme.textMuted, fontSize: 13, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 0.5)),
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
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  Text(sub, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
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
    double fee = 0.0;
    if (_selectedMethod == 'Paystack Checkout') {
      // Simplified Paystack Fee calculation: 1.5% + 100 NGN (if > 2500) capped at 2000
      double calc = widget.invoice.totalAmount * 0.015;
      if (widget.invoice.totalAmount > 2500) calc += 100;
      if (calc > 2000) calc = 2000;
      fee = calc;
    }
    double finalTotal = widget.invoice.totalAmount + fee;

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
          if (fee > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Convenience Fee", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  Text("₦${fee.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
            ),
          const Text("🔒 SECURE 256-BIT SSL ENCRYPTION", style: TextStyle(color: AppTheme.textMuted50, fontSize: 10, letterSpacing: 1)),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _handlePayment,
            child: _isLoading 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textDark))
              : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Continue to Pay"),
                Row(
                  children: [
                    Text("₦${finalTotal.toStringAsFixed(2)}"),
                    SizedBox(width: 8),
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
