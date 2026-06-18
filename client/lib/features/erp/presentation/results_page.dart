import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/erp_repository.dart';
import '../../../core/theme.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _loading = false;
  Map<String, dynamic>? _report;
  
  // Demo inputs
  int _classId = 1; // Needs dynamic list in real app
  String _term = "Term 1";
  String _year = "2025/2026";

  void _generateReport() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<ErpRepository>().generateTermReport(_classId, _term, _year);
      if (mounted) {
        setState(() {
          _report = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(title: const Text("TERM RESULTS")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildControlRow(),
            const SizedBox(height: 24),
            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator())
                : _report == null 
                  ? const Center(child: Text("Select criteria and generate report.", style: TextStyle(color: AppTheme.textMuted.withOpacity(0.5))))
                  : _buildReportView(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildControlRow() {
    return Row(
      children: [
        // Simply using a button for demo as class selection requires fetching classes first
        Expanded(
          child: ElevatedButton(
            onPressed: _loading ? null : _generateReport,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blueVibrant),
            child: const Text("GENERATE TERM 1 REPORT"),
          ),
        )
      ],
    );
  }

  Widget _buildReportView() {
    final students = _report!['student_reports'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("REPORT: ${_report!['classroom']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.limeLight)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: students.length,
            separatorBuilder: (c, i) => const Divider(color: AppTheme.textMuted.withOpacity(0.1)),
            itemBuilder: (context, index) {
              final s = students[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.surfaceLight,
                  child: Text("#${s['rank']}", style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
                ),
                title: Text(s['student_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Average: ${s['average'].toStringAsFixed(1)}%"),
                trailing: Text("${s['total_score'].toStringAsFixed(0)} pts", style: const TextStyle(color: AppTheme.limeLight, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ],
    );
  }
}
