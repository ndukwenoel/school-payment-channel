import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme.dart';
import '../data/payment_repository.dart';
import '../data/payment_models.dart';

class InstallmentRequestPage extends StatefulWidget {
  final Invoice invoice;

  const InstallmentRequestPage({super.key, required this.invoice});

  @override
  State<InstallmentRequestPage> createState() => _InstallmentRequestPageState();
}

class _InstallmentRequestPageState extends State<InstallmentRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  int _months = 2;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Payment Plan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppTheme.surfaceLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Invoice: ${widget.invoice.title}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text("Total Amount: ₦${widget.invoice.totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.limeLight, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Select Duration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _months,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                dropdownColor: AppTheme.surfaceLight,
                items: [2, 3, 4, 5, 6].map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text("$m Months (₦${(widget.invoice.totalAmount / m).toStringAsFixed(2)}/mo)"),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _months = val);
                },
              ),
              const SizedBox(height: 24),
              const Text("Reason for Request", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Briefly explain why you need an installment plan...",
                ),
                validator: (val) => val == null || val.isEmpty ? "Please provide a reason" : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _submitting = true);
    try {
      final repo = context.read<PaymentRepository>();
      final installments = List.generate(_months, (i) {
         return {
           "amount_due": widget.invoice.totalAmount / _months,
           "due_date": DateTime.now().add(Duration(days: 30 * (i + 1))).toIso8601String()
         };
      });

      await repo.requestPaymentPlan(widget.invoice.id, installments, _reasonController.text);
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request submitted successfully. Admin will review.")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
