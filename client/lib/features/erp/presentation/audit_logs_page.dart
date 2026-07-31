import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final _AuditLogDataSource _dataSource = _AuditLogDataSource();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audit Logs"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("System Audit Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Track all changes across the ERP and Payment modules.", style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 24),
            PaginatedDataTable(
              header: const Text('Recent Activity'),
              columns: const [
                DataColumn(label: Text('Timestamp')),
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Action')),
                DataColumn(label: Text('Details')),
                DataColumn(label: Text('IP Address')),
              ],
              source: _dataSource,
              rowsPerPage: 10,
              showCheckboxColumn: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditLogDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _data = List.generate(50, (index) => {
    "timestamp": DateTime.now().subtract(Duration(hours: index)).toString().split('.')[0],
    "user": "admin_user_$index",
    "action": index % 3 == 0 ? "CREATE_INVOICE" : "UPDATE_SETTINGS",
    "details": "Modified record ID $index",
    "ip": "192.168.1.${index % 255}",
  });

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) return null;
    final log = _data[index];
    return DataRow(cells: [
      DataCell(Text(log["timestamp"])),
      DataCell(Text(log["user"])),
      DataCell(Text(log["action"], style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(log["details"])),
      DataCell(Text(log["ip"])),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;
}
