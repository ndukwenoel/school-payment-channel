import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme.dart';
import 'dart:html' as html;
import 'dart:typed_data';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  
  List<dynamic> _exceptions = [];
  Map<String, dynamic>? _agingReport;
  double _totalRevenue = 0.0;
  List<dynamic> _revenueBreakdowns = [];
  Map<String, dynamic>? _expectedSettlements;
  
  bool _isLoadingExceptions = true;
  bool _isLoadingOverview = true;
  bool _isLoadingAging = true;

  @override
  void initState() {
    super.initState();
    _fetchExceptions();
    _fetchOverviewData();
    _fetchAgingReport();
  }

  Future<void> _fetchExceptions() async {
    setState(() => _isLoadingExceptions = true);
    try {
      final response = await _apiClient.dio.get('/api/v1/finance/exceptions');
      setState(() {
        _exceptions = response.data;
      });
    } on DioException catch (e) {
      _showError('Failed to load exceptions', e);
    } finally {
      setState(() => _isLoadingExceptions = false);
    }
  }

  Future<void> _fetchOverviewData() async {
    setState(() => _isLoadingOverview = true);
    try {
      final revRes = await _apiClient.dio.get('/api/v1/finance/revenue-report');
      final setRes = await _apiClient.dio.get('/api/v1/finance/expected-settlements');
      
      setState(() {
        _totalRevenue = revRes.data['total_revenue'] ?? 0.0;
        _revenueBreakdowns = revRes.data['breakdowns'] ?? [];
        _expectedSettlements = setRes.data;
      });
    } on DioException catch (e) {
      _showError('Failed to load overview data', e);
    } finally {
      setState(() => _isLoadingOverview = false);
    }
  }
  
  Future<void> _fetchAgingReport() async {
    setState(() => _isLoadingAging = true);
    try {
      final response = await _apiClient.dio.get('/api/v1/finance/aging-report');
      setState(() {
        _agingReport = response.data;
      });
    } on DioException catch (e) {
      _showError('Failed to load aging report', e);
    } finally {
      setState(() => _isLoadingAging = false);
    }
  }

  void _showError(String prefix, DioException e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$prefix: ${e.response?.data['detail'] ?? e.message}')),
      );
    }
  }

  Future<void> _resolveException(int transactionId, String action) async {
    try {
      await _apiClient.dio.post(
        '/api/v1/finance/resolve/$transactionId',
        data: {'action': action},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exception resolved successfully')),
        );
      }
      _fetchExceptions();
    } on DioException catch (e) {
      _showError('Failed to resolve', e);
    }
  }

  Future<void> _uploadSettlement() async {
    try {
      final uploadInput = html.FileUploadInputElement()..accept = '.csv';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((e) async {
            setState(() => _isLoadingOverview = true);
            try {
              final formData = FormData.fromMap({
                "file": MultipartFile.fromBytes(
                  reader.result as Uint8List,
                  filename: "settlement.csv",
                ),
              });
              final response = await _apiClient.dio.post(
                '/api/v1/settlements/upload',
                data: formData,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Upload successful: ${response.data["processed"]} records processed')),
                );
              }
              _fetchOverviewData();
            } catch (err) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload: $err')));
              }
              setState(() => _isLoadingOverview = false);
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error triggering file picker: $e')),
        );
      }
    }
  }

  void _showResolveDialog(int transactionId, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Exception'),
        content: Text('How would you like to resolve: \n$description?'),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
              _resolveException(transactionId, 'refund');
            },
            child: const Text('Refund to Bank'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              _resolveException(transactionId, 'credit_wallet');
            },
            child: const Text('Credit Parent Wallet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance Intelligence Platform', style: TextStyle(fontSize: 18)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Exceptions'),
              Tab(text: 'Aging Report'),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Upload Settlement CSV',
              onPressed: _uploadSettlement,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildExceptionsTab(),
            _buildAgingReportTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoadingOverview) {
      return Center(child: CircularProgressIndicator());
    }

    final totalExpected = _expectedSettlements?['total_expected'] ?? 0.0;
    final providers = _expectedSettlements?['providers'] ?? {};

    return RefreshIndicator(
      onRefresh: _fetchOverviewData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("LEDGER REVENUE", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5)),
          SizedBox(height: 8),
          _buildMetricCard("Total Collected Revenue", "?${_totalRevenue.toStringAsFixed(2)}", AppTheme.limeLight),
          
          if (_revenueBreakdowns.isNotEmpty) ...[
            SizedBox(height: 16),
            const Text("Revenue by Category:", style: TextStyle(color: AppTheme.textMuted)),
            SizedBox(height: 8),
            ..._revenueBreakdowns.map((b) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pie_chart, color: AppTheme.textMuted),
              title: Text(b['category'].toString()),
              trailing: Text("₦${b['amount'].toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )).toList(),
          ],
          
          SizedBox(height: 24),
          const Text("EXPECTED SETTLEMENTS", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5)),
          SizedBox(height: 8),
          _buildMetricCard("Pending Payouts", "?${totalExpected.toStringAsFixed(2)}", AppTheme.blueVibrant),
          SizedBox(height: 16),
          if (providers.isNotEmpty) ...[
            const Text("Breakdown by Provider:", style: TextStyle(color: AppTheme.textMuted)),
            SizedBox(height: 8),
            ...providers.entries.map((e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_wallet, color: AppTheme.textMuted),
              title: Text(e.key.toString().toUpperCase()),
              trailing: Text("?${e.value.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )).toList(),
          ] else
            const Text("No pending provider payouts.", style: TextStyle(color: AppTheme.textMuted50)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String amount, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          SizedBox(height: 8),
          Text(amount, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentColor)),
        ],
      ),
    );
  }

  Widget _buildExceptionsTab() {
    if (_isLoadingExceptions) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_exceptions.isEmpty) {
      return Center(child: Text('No reconciliation exceptions found.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchExceptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _exceptions.length,
        itemBuilder: (context, index) {
          final exc = _exceptions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
              title: Text(exc['description'], style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('Unreconciled Amount: ₦${exc['amount']}'),
              trailing: ElevatedButton(
                onPressed: () => _showResolveDialog(exc['id'], exc['description']),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blueVibrant, foregroundColor: AppTheme.textDark),
                child: const Text('Resolve'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgingReportTab() {
    if (_isLoadingAging) {
      return Center(child: CircularProgressIndicator());
    }

    final totalOverdue = _agingReport?['total_overdue'] ?? 0.0;
    final List buckets = _agingReport?['buckets'] ?? [];

    if (totalOverdue == 0) {
      return Center(child: Text("No overdue invoices. Great job!"));
    }

    return RefreshIndicator(
      onRefresh: _fetchAgingReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("AGING DEBT SUMMARY", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5)),
          SizedBox(height: 8),
          _buildMetricCard("Total Overdue", "?${totalOverdue.toStringAsFixed(2)}", Colors.redAccent),
          SizedBox(height: 24),
          const Text("DEBT BY AGE BUCKET", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5)),
          SizedBox(height: 12),
          ...buckets.map((b) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.hourglass_bottom, color: Colors.redAccent),
              title: Text(b['bucket'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${b['invoice_ids'].length} invoices affected"),
              trailing: Text("₦${b['total_amount'].toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          )).toList(),
        ],
      ),
    );
  }
}
