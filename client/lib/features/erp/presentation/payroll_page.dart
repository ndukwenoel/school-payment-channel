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

  void _generatePayroll() async {
    setState(() => _loading = true);
    try {
      await context.read<ErpRepository>().generatePayroll(_month, _year);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payroll generated for $_month $_year")));
      }
    } catch (e) {
      if (mounted) {
        // Backend endpoint expects specific fields, but our generate_monthly_payroll is a custom endpoint
        // Wait, I implemented /erp/hr/payroll/generate which takes month/year params
        // But ErpRepository.generatePayroll calls POST /erp/hr/payroll which expects a full Payroll object.
        // I need to update ErpRepository to call the generate endpoint!
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  // Note: I need to fix ErpRepository to support the generation endpoint properly
  // For now, I'll assume I'll fix it in the next step.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(title: const Text("PAYROLL")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildControlCard(),
            const SizedBox(height: 32),
            const Expanded(
              child: Center(child: Text("Payroll History (Coming Soon)", style: TextStyle(color: Colors.white38))),
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
          const Text("Generate payroll for all active staff based on their current designation profile.", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          Row(
            children: [
              DropdownButton<String>(
                value: _month,
                dropdownColor: AppTheme.surfaceLight,
                items: ["January", "February", "March", "April", "May"].map((m) => 
                  DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.white)))
                ).toList(),
                onChanged: (v) => setState(() => _month = v!),
              ),
              const SizedBox(width: 16),
              Text("$_year", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _generatePayroll,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bluePale),
              child: _loading ? const CircularProgressIndicator() : const Text("GENERATE PAYROLL"),
            ),
          )
        ],
      ),
    );
  }
}
