import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_models.dart';
import 'package:go_router/go_router.dart';

class CreateFeePage extends StatefulWidget {
  const CreateFeePage({super.key});

  @override
  State<CreateFeePage> createState() => _CreateFeePageState();
}

class _CreateFeePageState extends State<CreateFeePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _gradeController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  
  List<Student> _students = [];
  int? _selectedStudentId;
  String? _selectedGrade;
  bool _loading = false;
  bool _isBulk = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await context.read<DashboardRepository>().getStudents();
      setState(() {
        _students = students;
        if (students.isNotEmpty) _selectedStudentId = students.first.id;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading students: $e")));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isBulk && _selectedStudentId == null) return;
    if (_isBulk && (_selectedGrade == null || _selectedGrade!.isEmpty)) return;
    
    setState(() => _loading = true);
    try {
      final repo = context.read<DashboardRepository>();
      if (_isBulk) {
        await repo.createBulkFees(
          _titleController.text,
          double.parse(_amountController.text),
          _dueDate,
          _selectedGrade!,
        );
      } else {
        await repo.createFee(
          _titleController.text,
          double.parse(_amountController.text),
          _dueDate,
          _selectedStudentId!,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fee(s) Created Successfully!")));
        context.pop();
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
    // Extract unique grades
    final grades = _students.map((s) => s.grade).toSet().toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Create Fee")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text("Single Student"),
                      value: false,
                      groupValue: _isBulk,
                      onChanged: (val) => setState(() => _isBulk = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text("Whole Class"),
                      value: true,
                      groupValue: _isBulk,
                      onChanged: (val) => setState(() => _isBulk = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!_isBulk)
                DropdownButtonFormField<int>(
                  value: _selectedStudentId,
                  items: _students.map((s) => DropdownMenuItem(value: s.id, child: Text("${s.fullName} (${s.enrollmentNumber})"))).toList(),
                  onChanged: (val) => setState(() => _selectedStudentId = val),
                  decoration: const InputDecoration(labelText: "Student", border: OutlineInputBorder()),
                  validator: (val) => val == null && !_isBulk ? 'Select a student' : null,
                )
              else
                 DropdownButtonFormField<String>(
                  value: _selectedGrade,
                  items: grades.map((g) => DropdownMenuItem(value: g, child: Text("Grade $g"))).toList(),
                  onChanged: (val) => setState(() => _selectedGrade = val),
                  decoration: const InputDecoration(labelText: "Select Class/Grade", border: OutlineInputBorder()),
                  validator: (val) => (val == null || val.isEmpty) && _isBulk ? 'Select a grade' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Fee Title (e.g. Tuition Term 1)", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount", border: OutlineInputBorder(), prefixText: "\$"),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Due Date"),
                subtitle: Text("${_dueDate.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
              ),
              const SizedBox(height: 24),
              _loading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: Text(_isBulk ? "Create Fees for Class" : "Create Fee"),
                  )
            ],
          ),
        ),
      ),
    );
  }
}
