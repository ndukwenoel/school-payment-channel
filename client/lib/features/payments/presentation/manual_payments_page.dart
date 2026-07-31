import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/payment_repository.dart';
import '../data/payment_models.dart';
import '../../../../core/theme.dart';
import 'package:intl/intl.dart';

class ManualPaymentsPage extends StatefulWidget {
  const ManualPaymentsPage({super.key});

  @override
  State<ManualPaymentsPage> createState() => _ManualPaymentsPageState();
}

class _ManualPaymentsPageState extends State<ManualPaymentsPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<PaymentAttempt> _pendingPayments = [];
  List<Map<String, dynamic>> _unmatchedPayments = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<PaymentRepository>();
      final futures = await Future.wait([
        repo.getPendingManualPayments(),
        repo.getUnmatchedPayments()
      ]);
      if (mounted) {
        setState(() {
          _pendingPayments = futures[0] as List<PaymentAttempt>;
          _unmatchedPayments = futures[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _verifyPayment(int paymentId) async {
    try {
      final repo = context.read<PaymentRepository>();
      await repo.verifyManualPayment(paymentId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment verified successfully')));
      _loadAllData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    }
  }

  Future<void> _resolveUnmatchedPayment(int paymentId) async {
    // Show a dialog to enter student ID
    final studentIdController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Resolve Unmatched Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the Student ID to allocate these funds to:'),
              const SizedBox(height: 16),
              TextField(
                controller: studentIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Student ID (e.g. 1)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Resolve'),
            ),
          ],
        );
      }
    );

    if (result == true && studentIdController.text.isNotEmpty) {
      final studentId = int.tryParse(studentIdController.text);
      if (studentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Student ID')));
        return;
      }
      
      try {
        final repo = context.read<PaymentRepository>();
        await repo.resolveUnmatchedPayment(paymentId, studentId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment resolved successfully')));
        _loadAllData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resolution failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        backgroundColor: AppTheme.voidBlack,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.limeLight,
          labelColor: AppTheme.limeLight,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Parent Reported'),
            Tab(text: 'Unmatched Alerts'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingPaymentsTab(),
                _buildUnmatchedAlertsTab(),
              ],
            ),
    );
  }

  Widget _buildPendingPaymentsTab() {
    if (_pendingPayments.isEmpty) {
      return const Center(child: Text('No parent reported payments.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingPayments.length,
      itemBuilder: (context, index) {
        final payment = _pendingPayments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Invoice #${payment.invoiceId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '₦${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.limeLight),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Reference / Teller: ${payment.transactionId}', style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 4),
                Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(payment.paymentDate.toLocal())}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reject not implemented yet')));
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _verifyPayment(payment.id),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blueVibrant, foregroundColor: Colors.white),
                      child: const Text('Verify & Approve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnmatchedAlertsTab() {
    if (_unmatchedPayments.isEmpty) {
      return const Center(child: Text('No unmatched email alerts.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _unmatchedPayments.length,
      itemBuilder: (context, index) {
        final payment = _unmatchedPayments[index];
        final createdStr = payment['created_at'] as String;
        final createdAt = DateTime.tryParse(createdStr)?.toLocal() ?? DateTime.now();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bank Transfer Alert', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                    Text(
                      '₦${(payment['amount'] as num).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.limeLight),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Account: ${payment['account_number']} (${payment['bank_name']})', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Ref: ${payment['transaction_ref']}', style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 4),
                Text('Narration: ${payment['narration']}', style: TextStyle(color: Colors.grey[800], fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Text('Received: ${DateFormat('MMM dd, yyyy HH:mm').format(createdAt)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => _resolveUnmatchedPayment(payment['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blueVibrant, foregroundColor: Colors.white),
                      child: const Text('Resolve to Student'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
