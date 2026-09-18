import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

class PlatformBillingScreen extends StatefulWidget {
  const PlatformBillingScreen({super.key});

  @override
  State<PlatformBillingScreen> createState() => _PlatformBillingScreenState();
}

class _PlatformBillingScreenState extends State<PlatformBillingScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _invoices = [];

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get(
        '/platform-billing/',
        queryParameters: {'skip': 0, 'limit': 100},
      );
      if (mounted) {
        setState(() {
          _invoices = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load invoices: $e')));
      }
    }
  }

  Future<void> _markAsPaid(int invoiceId) async {
    try {
      await _apiClient.dio.patch('/platform-billing/$invoiceId/pay');
      _fetchInvoices();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice marked as paid')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("PLATFORM BILLING", style: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue), onPressed: _fetchInvoices),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(AppTheme.surfaceLight),
                            columns: const [
                              DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("School ID", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Billing Period", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _invoices.map((inv) {
                              final date = inv['created_at']?.toString().split('T')[0] ?? '';
                              final status = inv['status'] ?? 'unpaid';
                              return DataRow(cells: [
                                DataCell(Text(date, style: const TextStyle(fontSize: 13))),
                                DataCell(Text(inv['school_id']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                DataCell(Text(inv['billing_period'] ?? 'N/A', style: const TextStyle(fontSize: 13))),
                                DataCell(Text('₦${inv['amount_due']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status == 'paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(status.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: status == 'paid' ? Colors.green : Colors.orange)),
                                  )
                                ),
                                DataCell(
                                  status == 'unpaid'
                                    ? TextButton(
                                        onPressed: () => _markAsPaid(inv['id']),
                                        child: const Text('Mark Paid', style: TextStyle(fontSize: 12)),
                                      )
                                    : const SizedBox(),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
