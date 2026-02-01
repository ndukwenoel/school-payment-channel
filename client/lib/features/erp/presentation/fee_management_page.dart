import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../../core/theme.dart';

class FeeManagementPage extends StatefulWidget {
  const FeeManagementPage({super.key});

  @override
  State<FeeManagementPage> createState() => _FeeManagementPageState();
}

class _FeeManagementPageState extends State<FeeManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _gradeController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;

  Future<void> _createBulkFee() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await context.read<DashboardRepository>().createBulkFees(
        _titleController.text,
        double.parse(_amountController.text),
        _dueDate,
        _gradeController.text
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fees created & pushed to parents!")));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(title: const Text("FEE MANAGEMENT")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("CREATE NEW FEE", style: TextStyle(color: AppTheme.limeLight, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              const Text(
                "Push a new fee requirement to all students in a specific grade. Parents will be notified immediately.",
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Fee Title (e.g. Term 2 Exam Fee)"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount (\$)"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gradeController,
                decoration: const InputDecoration(labelText: "Target Grade (e.g. Grade 10)"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text("Due Date: ${_dueDate.toLocal().toString().split(' ')[0]}", style: const TextStyle(color: Colors.white70)),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030)
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    child: const Text("Change"),
                  )
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _createBulkFee,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blueVibrant),
                  child: _loading ? const CircularProgressIndicator() : const Text("PUSH TO PARENTS"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
