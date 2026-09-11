import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('/audit-logs/');
      if (mounted) {
        setState(() {
          _logs = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load logs: $e')));
      }
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
                const Text("SECURITY AUDIT LOGS", style: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue), onPressed: _fetchLogs),
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
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(AppTheme.surfaceLight),
                            dataRowMinHeight: 56,
                            dataRowMaxHeight: double.infinity,
                            columns: const [
                              DataColumn(label: Text("Timestamp", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("User ID", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Table", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Details", style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _logs.map((log) {
                              final timestamp = log['timestamp']?.toString().split('.')[0].replaceFirst('T', ' ') ?? '';
                              return DataRow(cells: [
                                DataCell(Text(timestamp, style: const TextStyle(fontSize: 13))),
                                DataCell(Text(log['user_id']?.toString() ?? 'System', style: const TextStyle(fontSize: 13))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: log['action'] == 'UPDATE' ? Colors.blue.withOpacity(0.1) : 
                                             log['action'] == 'CREATE' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(log['action'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, 
                                      color: log['action'] == 'UPDATE' ? Colors.blue : 
                                             log['action'] == 'CREATE' ? Colors.green : Colors.red)),
                                  )
                                ),
                                DataCell(Text(log['table_name'] ?? '', style: const TextStyle(fontSize: 13))),
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: SizedBox(
                                      width: 400,
                                      child: Text(log['new_values'] ?? '', style: const TextStyle(fontSize: 13)),
                                    ),
                                  )
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
