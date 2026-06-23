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
  bool _saveAsTemplate = false;
  List<dynamic> _templates = [];
  dynamic _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await context.read<DashboardRepository>().getFeeTemplates();
      setState(() => _templates = templates);
    } catch (e) {
      // ignore
    }
  }

  void _onTemplateSelected(dynamic template) {
    if (template == null) return;
    setState(() {
      _selectedTemplate = template;
      _titleController.text = template['name'];
      
      // Calculate total from line items if present
      final items = template['line_items'] as List?;
      if (items != null && items.isNotEmpty) {
        double total = 0;
        for (var item in items) {
          total += (item['amount'] as num).toDouble();
        }
        _amountController.text = total.toString();
      }
    });
  }

  Future<void> _createBulkFee() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final title = _titleController.text;
      final amount = double.parse(_amountController.text);
      
      final repo = context.read<DashboardRepository>();
      
      if (_saveAsTemplate) {
        await repo.createFeeTemplate(title, "Template for $title", [
          {'title': title, 'amount': amount}
        ]);
      }

      await repo.createBulkFees(title, amount, _dueDate, _gradeController.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bulk invoice generation started in the background. Parents will be notified.")));
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("CREATE NEW FEE", style: TextStyle(color: AppTheme.limeLight, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              SizedBox(height: 8),
              const Text(
                "Push a new fee requirement to all students in a specific grade. Parents will be notified immediately.",
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              SizedBox(height: 24),
              
              if (_templates.isNotEmpty) ...[
                DropdownButtonFormField<dynamic>(
                  decoration: const InputDecoration(labelText: "Load Existing Template (Optional)"),
                  dropdownColor: AppTheme.surfaceLight,
                  value: _selectedTemplate,
                  items: [
                    const DropdownMenuItem(value: null, child: Text("None")),
                    ..._templates.map((t) => DropdownMenuItem(value: t, child: Text(t['name']))).toList(),
                  ],
                  onChanged: _onTemplateSelected,
                ),
                SizedBox(height: 16),
              ],

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Fee Title (e.g. Term 2 Exam Fee)"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount (₦)"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _gradeController,
                decoration: const InputDecoration(labelText: "Target Grade (e.g. Grade 10)"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Text("Due Date: ${_dueDate.toLocal().toString().split(' ')[0]}", style: const TextStyle(color: AppTheme.textMuted)),
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
              SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Save this structure as a new Template", style: TextStyle(color: Colors.white70)),
                value: _saveAsTemplate,
                activeColor: AppTheme.limeLight,
                checkColor: Colors.black,
                onChanged: (v) => setState(() => _saveAsTemplate = v ?? false),
              ),
              SizedBox(height: 32),
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
