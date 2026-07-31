import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/payment_repository.dart';
import '../../../../core/theme.dart';

class RecordTellerModal extends StatefulWidget {
  final int invoiceId;

  const RecordTellerModal({super.key, required this.invoiceId});

  @override
  State<RecordTellerModal> createState() => _RecordTellerModalState();

  static Future<void> show(BuildContext context, int invoiceId) {
    return showDialog(
      context: context,
      builder: (context) => RecordTellerModal(invoiceId: invoiceId),
    );
  }
}

class _RecordTellerModalState extends State<RecordTellerModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _tellerController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _tellerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = context.read<PaymentRepository>();
      final amount = double.parse(_amountController.text);
      
      await repo.submitManualPayment(
        widget.invoiceId,
        amount,
        _tellerController.text,
      );
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manual payment submitted for verification')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Bank Teller'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Log a physical bank teller or manual transfer for verification.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Paid (₦)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (double.tryParse(val) == null) return 'Must be a number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tellerController,
              decoration: const InputDecoration(
                labelText: 'Teller / Reference Number',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.blueVibrant,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit'),
        ),
      ],
    );
  }
}
