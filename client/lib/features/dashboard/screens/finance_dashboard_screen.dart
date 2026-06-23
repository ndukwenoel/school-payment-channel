import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme.dart';
import 'package:file_picker/file_picker.dart';
import '../../finance/presentation/posting_rules_page.dart';
import 'package:fl_chart/fl_chart.dart';

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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final fileBytes = result.files.first.bytes;
        final fileName = result.files.first.name;
        
        if (fileBytes != null) {
          setState(() => _isLoadingOverview = true);
          try {
            final formData = FormData.fromMap({
              "file": MultipartFile.fromBytes(
                fileBytes,
                filename: fileName,
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
        }
      }
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
      length: 9,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance Intelligence Platform', style: TextStyle(fontSize: 18)),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Transactions'),
              Tab(text: 'Exceptions'),
              Tab(text: 'Aging Report'),
              Tab(text: 'Posting Rules'),
              Tab(text: 'Verifications'),
              Tab(text: 'Plan Requests'),
              Tab(text: 'Expenses'),
              Tab(text: 'Settings'),
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
            _buildTransactionsTab(),
            _buildExceptionsTab(),
            _buildAgingReportTab(),
            const PostingRulesPage(),
            _buildVerificationsTab(),
            _buildPlanRequestsTab(),
            _buildExpensesTab(),
            _buildSettingsTab(),
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
    final totalSettled = _expectedSettlements?['total_settled'] ?? 0.0;
    final providers = _expectedSettlements?['providers'] ?? {};

    return RefreshIndicator(
      onRefresh: _fetchOverviewData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("LEDGER REVENUE", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5)),
          SizedBox(height: 8),
          _buildMetricCard("Total Collected Revenue", "₦${_totalRevenue.toStringAsFixed(2)}", AppTheme.limeLight),
          
          if (_revenueBreakdowns.isNotEmpty) ...[
            SizedBox(height: 16),
            const Text("Revenue by Category:", style: TextStyle(color: AppTheme.textMuted)),
            SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _getRevenueSections(),
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildRevenueLegend(),
          ],
          
          SizedBox(height: 32),
          const Text("SETTLEMENTS & PAYOUTS", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMetricCard("Pending Payouts", "₦${totalExpected.toStringAsFixed(2)}", Colors.orangeAccent)),
              SizedBox(width: 16),
              Expanded(child: _buildMetricCard("Actual Settled", "₦${totalSettled.toStringAsFixed(2)}", AppTheme.blueVibrant)),
            ],
          ),
          
          SizedBox(height: 16),
          if (providers.isNotEmpty) ...[
            const Text("Pending Breakdown by Provider:", style: TextStyle(color: AppTheme.textMuted)),
            SizedBox(height: 8),
            ...providers.entries.map((e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_wallet, color: AppTheme.textMuted),
              title: Text(e.key.toString().toUpperCase()),
              trailing: Text("₦${e.value.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )).toList(),
          ] else
            const Text("No pending provider payouts.", style: TextStyle(color: AppTheme.textMuted50)),
        ],
      ),
    );
  }

  // Helper colors for the chart
  final List<Color> _chartColors = [
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.green,
    Colors.red,
    Colors.teal,
  ];

  List<PieChartSectionData> _getRevenueSections() {
    return _revenueBreakdowns.asMap().entries.map((entry) {
      final index = entry.key;
      final b = entry.value;
      final amount = (b['amount'] as num).toDouble();
      final color = _chartColors[index % _chartColors.length];
      
      final percentage = _totalRevenue > 0 ? (amount / _totalRevenue) * 100 : 0.0;
      
      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildRevenueLegend() {
    return Column(
      children: _revenueBreakdowns.asMap().entries.map((entry) {
        final index = entry.key;
        final b = entry.value;
        final color = _chartColors[index % _chartColors.length];
        return Row(
          children: [
            Container(width: 16, height: 16, color: color),
            SizedBox(width: 8),
            Text(b['category'].toString(), style: const TextStyle(color: Colors.white)),
            Spacer(),
            Text("₦${(b['amount'] as num).toDouble().toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        );
      }).toList(),
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

  // --- Transactions Logic ---
  List<dynamic> _transactions = [];
  bool _isLoadingTransactions = true;

  Future<void> _fetchTransactions() async {
    setState(() => _isLoadingTransactions = true);
    try {
      final response = await _apiClient.dio.get('/api/v1/finance/transactions');
      if (mounted) {
        setState(() {
          _transactions = response.data;
        });
      }
    } on DioException catch (e) {
      _showError('Failed to load transactions', e);
    } finally {
      if (mounted) setState(() => _isLoadingTransactions = false);
    }
  }

  Widget _buildTransactionsTab() {
    if (_isLoadingTransactions) {
      if (_transactions.isEmpty) {
        _fetchTransactions();
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions found.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final txn = _transactions[index];
          final entries = txn['entries'] as List;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(txn['description'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      Text(txn['created_at'].toString().split('T').join(' ').substring(0, 16), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                  const Divider(height: 24),
                  ...entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e['account']),
                        Text(
                          e['type'] == 'credit' ? '+₦${e['amount']}' : '-₦${e['amount']}',
                          style: TextStyle(
                            color: e['type'] == 'credit' ? AppTheme.greenDeep : Colors.redAccent,
                            fontWeight: FontWeight.bold
                          ),
                        )
                      ],
                    ),
                  ))
                ],
              ),
            ),
          );
        },
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

  Future<void> _sendSecureReminders(String type, String target, String customMessage) async {
    try {
      final data = {
        'type': type,
        'target': target,
      };
      if (customMessage.isNotEmpty) {
        data['custom_message'] = customMessage;
      }
      final response = await _apiClient.dio.post('/api/v1/finance/send-reminders', data: data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully sent ${response.data["messages_sent"]} secure messages!')),
        );
      }
      _fetchAgingReport(); // Refresh to show updated overdue status
    } on DioException catch (e) {
      _showError('Failed to send messages', e);
    }
  }

  void _showReminderOptionsDialog() {
    String selectedType = 'all';
    String selectedTarget = 'overdue_only';
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Send Notifications / Broadcast'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Target Audience:'),
                    DropdownButton<String>(
                      value: selectedTarget,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'overdue_only', child: Text('Parents with Overdue Invoices')),
                        DropdownMenuItem(value: 'all_parents', child: Text('All Parents (General Broadcast)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedTarget = val);
                      },
                    ),
                    SizedBox(height: 16),
                    const Text('Channel:'),
                    DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Channels')),
                        DropdownMenuItem(value: 'email', child: Text('Email')),
                        DropdownMenuItem(value: 'sms', child: Text('SMS')),
                        DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                    SizedBox(height: 16),
                    const Text('Custom Message (Optional for Overdue, Required for All):'),
                    SizedBox(height: 8),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Type your broadcast message here...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedTarget == 'all_parents' && messageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom message is required for general broadcast')));
                      return;
                    }
                    context.pop();
                    _sendSecureReminders(selectedType, selectedTarget, messageController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blueVibrant, foregroundColor: Colors.white),
                  child: const Text('Send Message'),
                ),
              ],
            );
          }
        );
      }
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("AGING DEBT SUMMARY", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5)),
              ElevatedButton.icon(
                onPressed: _showReminderOptionsDialog,
                icon: const Icon(Icons.message, size: 16),
                label: const Text("Send Reminders"),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blueVibrant, foregroundColor: Colors.white),
              )
            ],
          ),
          SizedBox(height: 16),
          _buildMetricCard("Total Overdue", "₦${totalOverdue.toStringAsFixed(2)}", Colors.redAccent),
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

  // --- Verifications Logic ---

  List<dynamic> _verifications = [];
  bool _isLoadingVerifications = true;

  Future<void> _fetchVerifications() async {
    setState(() => _isLoadingVerifications = true);
    try {
      final response = await _apiClient.dio.get('/api/v1/finance/pending-verifications');
      if (mounted) {
        setState(() {
          _verifications = response.data;
        });
      }
    } on DioException catch (e) {
      _showError('Failed to load verifications', e);
    } finally {
      if (mounted) setState(() => _isLoadingVerifications = false);
    }
  }

  Future<void> _verifyPayment(int paymentId) async {
    try {
      await _apiClient.dio.post('/api/v1/payments/$paymentId/verify');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verified successfully!')),
        );
      }
      _fetchVerifications();
      _fetchOverviewData();
    } on DioException catch (e) {
      _showError('Failed to verify payment', e);
    }
  }

  Widget _buildVerificationsTab() {
    if (_isLoadingVerifications) {
      if (_verifications.isEmpty) {
        _fetchVerifications();
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (_verifications.isEmpty) {
      return const Center(child: Text('No pending verifications.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchVerifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _verifications.length,
        itemBuilder: (context, index) {
          final verification = _verifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: AppTheme.blueVibrant, size: 36),
              title: Text('Ref: ${verification['transaction_id']}', style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('Amount: ₦${verification['amount']} \nDate: ${verification['payment_date']}'),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (verification['receipt_url'] != null)
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: () {
                        // In a real app we'd open the image URL
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mock Receipt Viewer Opened")));
                      },
                      tooltip: 'View Receipt',
                    ),
                  ElevatedButton(
                    onPressed: () => _verifyPayment(verification['id']),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenDeep, foregroundColor: Colors.white),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Plan Requests Logic ---

  List<dynamic> _planRequests = [];
  bool _isLoadingPlanRequests = true;

  Future<void> _fetchPlanRequests() async {
    setState(() => _isLoadingPlanRequests = true);
    try {
      final response = await _apiClient.dio.get('/api/v1/invoices/plan-requests/all');
      if (mounted) {
        setState(() {
          _planRequests = response.data;
        });
      }
    } on DioException catch (e) {
      _showError('Failed to load plan requests', e);
    } finally {
      if (mounted) setState(() => _isLoadingPlanRequests = false);
    }
  }

  Future<void> _handlePlanRequest(int requestId, String action) async {
    try {
      await _apiClient.dio.post('/api/v1/invoices/plan-requests/$requestId/$action');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan request $action successfully!')),
        );
      }
      _fetchPlanRequests();
    } on DioException catch (e) {
      _showError('Failed to $action request', e);
    }
  }

  Widget _buildPlanRequestsTab() {
    if (_isLoadingPlanRequests) {
      if (_planRequests.isEmpty) {
        _fetchPlanRequests();
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (_planRequests.isEmpty) {
      return const Center(child: Text('No pending plan requests.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchPlanRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _planRequests.length,
        itemBuilder: (context, index) {
          final req = _planRequests[index];
          final installments = req['proposed_installments'] as List;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Invoice #${req['invoice_id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(req['status'].toUpperCase(), style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Reason: ${req['reason']}', style: const TextStyle(color: AppTheme.textMuted)),
                  SizedBox(height: 12),
                  const Text('Proposed Installments:', style: TextStyle(fontWeight: FontWeight.w500)),
                  ...installments.map((i) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• ₦${i['amount']} due ${i['due_date'].toString().split('T')[0]}'),
                  )),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _handlePlanRequest(req['id'], 'reject'),
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                        child: const Text('Reject'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _handlePlanRequest(req['id'], 'approve'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenDeep, foregroundColor: Colors.white),
                        child: const Text('Approve'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  // --- Expenses & Payroll Logic ---

  List<dynamic> _expenses = [];
  bool _isLoadingExpenses = true;

  Future<void> _fetchExpenses() async {
    setState(() => _isLoadingExpenses = true);
    try {
      final response = await _apiClient.dio.get('/api/v1/finance/expenses');
      if (mounted) {
        setState(() {
          _expenses = response.data;
        });
      }
    } on DioException catch (e) {
      _showError('Failed to load expenses', e);
    } finally {
      if (mounted) setState(() => _isLoadingExpenses = false);
    }
  }

  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'School Expenses';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Log New Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Expense Title'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount (₦)'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        DropdownMenuItem(value: 'School Expenses', child: Text('General School Expenses')),
                        DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                        DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                        DropdownMenuItem(value: 'Events', child: Text('Events')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => category = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || amountController.text.isEmpty) return;
                    try {
                      await _apiClient.dio.post('/api/v1/finance/expenses', data: {
                        'title': titleController.text,
                        'amount': double.parse(amountController.text),
                        'category': category,
                        'payment_date': DateTime.now().toIso8601String(),
                      });
                      if (context.mounted) {
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense logged successfully')));
                        _fetchExpenses();
                      }
                    } on DioException catch (e) {
                      _showError('Failed to log expense', e);
                    }
                  },
                  child: const Text('Log Expense'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showExecutePayrollDialog() {
    final monthController = TextEditingController(text: _getMonthName(DateTime.now().month));
    final yearController = TextEditingController(text: DateTime.now().year.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Execute Monthly Payroll'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Execute payroll will calculate total pending net pay for the month, log an Expense, and debit the Payroll Expense ledger account.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              TextField(
                controller: monthController,
                decoration: const InputDecoration(labelText: 'Month (e.g. June)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await _apiClient.dio.post('/api/v1/erp/hr/payroll/execute', queryParameters: {
                    'month': monthController.text,
                    'year': int.parse(yearController.text),
                  });
                  if (context.mounted) {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.data['message'])));
                    _fetchExpenses();
                  }
                } on DioException catch (e) {
                  _showError('Failed to execute payroll', e);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blueVibrant, foregroundColor: Colors.white),
              child: const Text('Execute'),
            ),
          ],
        );
      }
    );
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  Widget _buildExpensesTab() {
    if (_isLoadingExpenses) {
      if (_expenses.isEmpty) _fetchExpenses();
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchExpenses,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("EXPENSES & PAYROLL", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5)),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showExecutePayrollDialog,
                    icon: const Icon(Icons.payments, size: 16),
                    label: const Text("Execute Payroll"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.purpleDeep, foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddExpenseDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Log Expense"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blueVibrant, foregroundColor: Colors.white),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          if (_expenses.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No expenses logged yet.'),
            ))
          else
            ..._expenses.map((e) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: e['category'] == 'Payroll' ? AppTheme.purpleDeep.withOpacity(0.2) : AppTheme.orangeAccent.withOpacity(0.2),
                  child: Icon(e['category'] == 'Payroll' ? Icons.group : Icons.receipt, color: e['category'] == 'Payroll' ? AppTheme.purpleDeep : AppTheme.orangeAccent),
                ),
                title: Text(e['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${e['category']} • ${e['payment_date'].toString().split('T')[0]}'),
                trailing: Text('₦${e['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
              ),
            )),
        ],
      ),
    );
  }

  // --- Settings Logic ---

  bool _isLoadingSettings = false;
  Map<String, dynamic>? _schoolSettings;

  Future<void> _fetchSchoolSettings() async {
    setState(() => _isLoadingSettings = true);
    try {
      final response = await _apiClient.dio.get('/api/v1/schools/me');
      if (mounted) {
        setState(() {
          _schoolSettings = response.data;
        });
      }
    } on DioException catch (e) {
      _showError('Failed to load settings', e);
    } finally {
      if (mounted) setState(() => _isLoadingSettings = false);
    }
  }

  Future<void> _updateSettings(Map<String, dynamic> updates) async {
    try {
      await _apiClient.dio.put('/api/v1/schools/me', data: updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings updated successfully")));
      }
      _fetchSchoolSettings();
    } on DioException catch (e) {
      _showError('Failed to update settings', e);
    }
  }

  Future<void> _runLateFeesEngine() async {
    try {
      final response = await _apiClient.dio.post('/api/v1/finance/run-late-fees');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Engine ran: ${response.data["invoices_updated"]} invoices updated, ₦${response.data["total_late_fees_added"]} fees added.')),
        );
      }
      _fetchAgingReport();
    } on DioException catch (e) {
      _showError('Failed to run engine', e);
    }
  }

  Widget _buildSettingsTab() {
    if (_isLoadingSettings) {
      if (_schoolSettings == null) {
        _fetchSchoolSettings();
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (_schoolSettings == null) {
      return const Center(child: Text("Failed to load settings"));
    }

    final bool enableLateFees = _schoolSettings!['enable_late_fees'] ?? false;
    final double lateFeePercentage = (_schoolSettings!['late_fee_percentage'] as num?)?.toDouble() ?? 0.0;
    final int gracePeriod = _schoolSettings!['late_fee_grace_period_days'] ?? 0;

    return RefreshIndicator(
      onRefresh: _fetchSchoolSettings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("AUTOMATED ENGINE SETTINGS", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5)),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Late Fee Engine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Switch(
                        value: enableLateFees,
                        activeColor: AppTheme.limeLight,
                        onChanged: (val) => _updateSettings({'enable_late_fees': val}),
                      ),
                    ],
                  ),
                  const Text("Automatically apply percentage-based late fees to overdue invoices.", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const Divider(height: 32),
                  
                  if (enableLateFees) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: lateFeePercentage.toString(),
                            decoration: const InputDecoration(labelText: "Late Fee Percentage (%)", border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            onFieldSubmitted: (val) {
                              final numVal = double.tryParse(val);
                              if (numVal != null) _updateSettings({'late_fee_percentage': numVal});
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: gracePeriod.toString(),
                            decoration: const InputDecoration(labelText: "Grace Period (Days)", border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            onFieldSubmitted: (val) {
                              final numVal = int.tryParse(val);
                              if (numVal != null) _updateSettings({'late_fee_grace_period_days': numVal});
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _runLateFeesEngine,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Run Late Fees Engine Now"),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orangeAccent, foregroundColor: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    const Text("Note: The engine usually runs automatically via cron job at midnight.", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
