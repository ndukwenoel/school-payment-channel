import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

class ExecutiveDashboardScreen extends StatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  State<ExecutiveDashboardScreen> createState() => _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState extends State<ExecutiveDashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get('/api/v1/finance/analytics/executive');
      if (mounted) {
        setState(() {
          _analyticsData = response.data;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load analytics: ${e.response?.data['detail'] ?? e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_analyticsData == null) {
      return const Center(child: Text("No data available."));
    }

    final double totalRevenue = (_analyticsData!['total_revenue'] ?? 0).toDouble();
    final double totalExpenses = (_analyticsData!['total_expenses'] ?? 0).toDouble();
    final double netProfit = (_analyticsData!['net_profit'] ?? 0).toDouble();
    final int totalInvoices = _analyticsData!['total_invoices'] ?? 0;
    final int paidInvoices = _analyticsData!['paid_invoices'] ?? 0;
    final int unpaidInvoices = _analyticsData!['unpaid_invoices'] ?? 0;
    final List<dynamic> recentExpenses = _analyticsData!['recent_expenses'] ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent, // Background provided by MainLayout
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("EXECUTIVE DASHBOARD", style: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.refresh, color: AppTheme.sageGreen), onPressed: _fetchAnalytics),
              ],
            ),
            const SizedBox(height: 24),
            
            // KPIs
            Row(
              children: [
                Expanded(child: _buildKpiCard("TOTAL REVENUE", "₦${totalRevenue.toStringAsFixed(2)}", Icons.trending_up, AppTheme.sageGreen)),
                const SizedBox(width: 16),
                Expanded(child: _buildKpiCard("TOTAL EXPENSES", "₦${totalExpenses.toStringAsFixed(2)}", Icons.trending_down, Colors.redAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildKpiCard("NET PROFIT", "₦${netProfit.toStringAsFixed(2)}", Icons.account_balance, AppTheme.blueVibrant)),
              ],
            ),
            const SizedBox(height: 24),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoices Overview
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("INVOICE METRICS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 24),
                        _buildInvoiceStatRow("Total Issued", totalInvoices, AppTheme.textMuted),
                        const SizedBox(height: 16),
                        _buildInvoiceStatRow("Paid", paidInvoices, AppTheme.sageGreen),
                        const SizedBox(height: 16),
                        _buildInvoiceStatRow("Unpaid", unpaidInvoices, Colors.orangeAccent),
                        const SizedBox(height: 24),
                        LinearProgressIndicator(
                          value: totalInvoices == 0 ? 0 : paidInvoices / totalInvoices,
                          backgroundColor: AppTheme.textMuted.withOpacity(0.2),
                          color: AppTheme.sageGreen,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text("${totalInvoices == 0 ? 0 : (paidInvoices / totalInvoices * 100).toStringAsFixed(1)}% Collection Rate", style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                
                // Recent Expenses
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("RECENT EXPENSES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        if (recentExpenses.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("No recent expenses logged.", style: TextStyle(color: AppTheme.textMuted)),
                          )
                        else
                          ...recentExpenses.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppTheme.orangeAccent.withOpacity(0.2),
                                      child: const Icon(Icons.receipt, size: 16, color: AppTheme.orangeAccent),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text("${e['category']} • ${e['date'].toString().split('T')[0]}", style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                  ],
                                ),
                                Text("₦${e['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                              ],
                            ),
                          )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        ],
      ),
    );
  }

  Widget _buildInvoiceStatRow(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
        Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
