import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_models.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

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
    final grades = _students.map((s) => s.grade).toSet().toList();

    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(title: const Text("CREATE NEW FEE")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TARGET AUDIENCE", style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      title: const Text("Single Student", style: TextStyle(fontSize: 14)),
                      value: false,
                      groupValue: _isBulk,
                      activeColor: AppTheme.blueVibrant,
                      onChanged: (val) => setState(() => _isBulk = val!),
                    ),
                    RadioListTile<bool>(
                      title: const Text("Whole Class", style: TextStyle(fontSize: 14)),
                      value: true,
                      groupValue: _isBulk,
                      activeColor: AppTheme.blueVibrant,
                      onChanged: (val) => setState(() => _isBulk = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!_isBulk)
                DropdownButtonFormField<int>(
                  value: _selectedStudentId,
                  dropdownColor: AppTheme.surfaceLight,
                  items: _students.map((s) => DropdownMenuItem(value: s.id, child: Text("${s.fullName} (${s.enrollmentNumber})"))).toList(),
                  onChanged: (val) => setState(() => _selectedStudentId = val),
                  decoration: const InputDecoration(labelText: "Select Student"),
                  validator: (val) => val == null && !_isBulk ? 'Select a student' : null,
                )
              else
                 DropdownButtonFormField<String>(
                  value: _selectedGrade,
                  dropdownColor: AppTheme.surfaceLight,
                  items: grades.map((g) => DropdownMenuItem(value: g, child: Text("Grade $g"))).toList(),
                  onChanged: (val) => setState(() => _selectedGrade = val),
                  decoration: const InputDecoration(labelText: "Select Class/Grade"),
                  validator: (val) => (val == null || val.isEmpty) && _isBulk ? 'Select a grade' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Fee Title (e.g. Tuition Term 1)"),
                validator: (val) => val!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount", prefixText: "\$ "),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 24),
              const Text("DEADLINE", style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                    builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.blueVibrant)), child: child!),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${_dueDate.day}/${_dueDate.month}/${_dueDate.year}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Icon(Icons.calendar_today, size: 18, color: AppTheme.blueVibrant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _loading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isBulk ? "GENERATE CLASS FEES" : "CREATE INDIVIDUAL FEE"),
                  )
            ],
          ),
        ),
      ),
    );
  }
}
