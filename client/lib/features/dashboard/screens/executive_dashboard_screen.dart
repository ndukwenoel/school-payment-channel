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
      final response = await _apiClient.dio.get('/reports/executive-analytics');
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

    final double totalPlatformVolume = (_analyticsData!['total_platform_volume'] ?? 0).toDouble();
    final int totalTransactions = _analyticsData!['total_transactions'] ?? 0;
    final int totalInvoicesIssued = _analyticsData!['total_invoices_issued'] ?? 0;
    final double totalPayrollProcessed = (_analyticsData!['total_payroll_processed'] ?? 0).toDouble();
    final int activeSchools = _analyticsData!['active_schools'] ?? 0;
    final double saasRevenueCollected = (_analyticsData!['saas_revenue_collected'] ?? 0).toDouble();
    final int totalStudents = _analyticsData!['total_students'] ?? 0;
    final int totalUsers = _analyticsData!['total_users'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ENTERPRISE SAAS DASHBOARD", style: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue), onPressed: _fetchAnalytics),
              ],
            ),
            const SizedBox(height: 24),
            
            // Tier 1 KPIs: Money
            Row(
              children: [
                Expanded(child: _buildKpiCard("PLATFORM VOLUME", "₦${totalPlatformVolume.toStringAsFixed(2)}", Icons.account_balance_wallet, AppTheme.sageGreen)),
                const SizedBox(width: 16),
                Expanded(child: _buildKpiCard("PAYROLL PROCESSED", "₦${totalPayrollProcessed.toStringAsFixed(2)}", Icons.payments, Colors.orangeAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildKpiCard("SAAS REVENUE", "₦${saasRevenueCollected.toStringAsFixed(2)}", Icons.verified, AppTheme.primaryBlue)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Tier 2 KPIs: Engagement
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        const Text("PLATFORM ENGAGEMENT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniStat("Active Schools", activeSchools.toString(), Icons.school),
                            _buildMiniStat("Total Users", totalUsers.toString(), Icons.people_alt),
                            _buildMiniStat("Total Students", totalStudents.toString(), Icons.face),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                
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
                        const Text("TRANSACTION METRICS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 24),
                        _buildInvoiceStatRow("Successful Payments", totalTransactions, AppTheme.sageGreen),
                        const SizedBox(height: 16),
                        _buildInvoiceStatRow("Invoices Issued", totalInvoicesIssued, AppTheme.primaryBlue),
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
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
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

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }
}
