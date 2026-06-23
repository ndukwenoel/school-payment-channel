import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/erp_repository.dart';
import '../../../core/theme.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key});

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  String _month = "May"; // Default for demo
  int _year = 2026;
  bool _loading = false;
  List<dynamic> _payrolls = [];

  @override
  void initState() {
    super.initState();
    _loadPayrollHistory();
  }

  void _loadPayrollHistory() async {
    setState(() => _loading = true);
    try {
      final records = await context.read<ErpRepository>().getPayrollHistory(_month, _year);
      if (mounted) {
        setState(() {
          _payrolls = records;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading payroll: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _generatePayroll() async {
    setState(() => _loading = true);
    try {
      await context.read<ErpRepository>().generatePayroll(_month, _year);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payroll generated for $_month $_year")));
        _loadPayrollHistory(); // Refresh table
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error generating payroll: $e")));
        setState(() => _loading = false);
      }
    }
  }

  void _showEditDialog(Map<String, dynamic> payroll) {
    final bonusesController = TextEditingController(text: payroll['bonuses'].toString());
    final deductionsController = TextEditingController(text: payroll['deductions'].toString());

    showDialog(
      context: context,
      builder: (context) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Payroll - ${payroll['staff_name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: bonusesController,
                    decoration: const InputDecoration(labelText: 'Bonuses'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: deductionsController,
                    decoration: const InputDecoration(labelText: 'Deductions'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : () async {
                    setDialogState(() => saving = true);
                    try {
                      await context.read<ErpRepository>().updatePayrollRecord(payroll['id'], {
                        'bonuses': double.parse(bonusesController.text),
                        'deductions': double.parse(deductionsController.text),
                      });
                      if (mounted) {
                        Navigator.pop(context);
                        _loadPayrollHistory();
                      }
                    } catch (e) {
                      setDialogState(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving: $e")));
                    }
                  },
                  child: saving ? const CircularProgressIndicator() : const Text('Save'),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(
        title: const Text("PAYROLL"),
        backgroundColor: AppTheme.surfaceDark,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildControlCard(),
            const SizedBox(height: 32),
            Expanded(
              child: _buildHistoryTable(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bluePale.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AUTOMATED PAYROLL", style: TextStyle(color: AppTheme.bluePale, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("Generate payroll for all active staff based on their current designation profile. This will calculate Net Pay based on Base Salary, Bonuses, and Deductions.", style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 24),
          Row(
            children: [
              DropdownButton<String>(
                value: _month,
                dropdownColor: AppTheme.surfaceLight,
                items: ["January", "February", "March", "April", "May", "June"].map((m) => 
                  DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: AppTheme.textDark)))
                ).toList(),
                onChanged: (v) {
                  setState(() => _month = v!);
                  _loadPayrollHistory();
                },
              ),
              const SizedBox(width: 16),
              Text("$_year", style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(
                onPressed: _loading ? null : _generatePayroll,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bluePale),
                child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("GENERATE PAYROLL"),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable() {
    if (_loading && _payrolls.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_payrolls.isEmpty) {
      return const Center(child: Text("No payroll generated for this month yet.", style: TextStyle(color: AppTheme.textMuted50)));
    }

    return Card(
      color: AppTheme.surfaceLight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payrolls.length,
        itemBuilder: (context, index) {
          final p = _payrolls[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.bluePale.withOpacity(0.2),
              child: const Icon(Icons.person, color: AppTheme.blueVibrant),
            ),
            title: Text(p['staff_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${p['designation']} • Base: ₦${p['base_salary']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Net Pay: ₦${p['net_pay']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    Text("+₦${p['bonuses']} / -₦${p['deductions']}", style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: AppTheme.bluePale),
                  onPressed: () => _showEditDialog(p),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
