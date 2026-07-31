import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme.dart';
import '../data/payment_repository.dart';

class InstallmentManagementPage extends StatefulWidget {
  const InstallmentManagementPage({super.key});

  @override
  State<InstallmentManagementPage> createState() => _InstallmentManagementPageState();
}

class _InstallmentManagementPageState extends State<InstallmentManagementPage> {
  bool _isLoading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final repo = context.read<PaymentRepository>();
      final reqs = await repo.getPlanRequests();
      if (mounted) {
        setState(() {
          _requests = reqs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Installment Requests"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text("No pending installment requests.", style: TextStyle(color: AppTheme.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    return _buildRequestCard(req);
                  },
                ),
    );
  }

  Widget _buildRequestCard(dynamic req) {
    final proposed = req['proposed_installments'] as List? ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Invoice #${req['invoice_id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: req['status'] == 'pending' ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(req['status'].toString().toUpperCase(), style: TextStyle(fontSize: 10, color: req['status'] == 'pending' ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text("Reason: ${req['reason'] ?? 'None provided'}", style: const TextStyle(color: AppTheme.textDark)),
            const SizedBox(height: 12),
            const Text("Proposed Schedule:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            ...proposed.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("₦${(p['amount_due'] ?? p['amount'] ?? 0).toStringAsFixed(2)}"),
                  Text((p['due_date'] ?? '').toString().split('T')[0]),
                ],
              ),
            )),
            const SizedBox(height: 16),
            if (req['status'] == 'pending') Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(req['id'], false),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(req['id'], true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text("Approve"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(int requestId, bool isApprove) async {
    try {
      final repo = context.read<PaymentRepository>();
      if (isApprove) {
        await repo.approvePlanRequest(requestId);
      } else {
        await repo.rejectPlanRequest(requestId);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request ${isApprove ? 'approved' : 'rejected'}.")));
      _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
