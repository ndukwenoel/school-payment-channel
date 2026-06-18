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
              _buildMethodOption("Offline Bank Transfer", "Manual Verification", Icons.account_balance, AppTheme.greenDeep),
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
                    Text("?${widget.invoice.totalAmount.toStringAsFixed(2)}"),
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
