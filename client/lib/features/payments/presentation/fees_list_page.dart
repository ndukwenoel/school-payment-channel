import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/payment_repository.dart';
import '../data/payment_models.dart';
import '../../dashboard/data/dashboard_repository.dart'; // Student

class FeesListPage extends StatefulWidget {
  const FeesListPage({super.key});

  @override
  State<FeesListPage> createState() => _FeesListPageState();
}

class _FeesListPageState extends State<FeesListPage> {
  bool _loading = true;
  List<Student> _students = [];
  Map<int, List<Fee>> _fees = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<PaymentRepository>();
      final students = await repo.getMyStudents();
      Map<int, List<Fee>> feesMap = {};
      
      for (var s in students) {
        final fees = await repo.getStudentFees(s.id);
        feesMap[s.id] = fees;
      }

      if (mounted) {
        setState(() {
          _students = students;
          _fees = feesMap;
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

  Future<void> _payFee(Fee fee) async {
    // 1. Create Intent
    try {
      final repo = context.read<PaymentRepository>();
      // Mocking Amount: Pay full remaining? Or fixed? 
      // For MVP pay full amount.
      await repo.createPaymentIntent(fee.id, fee.amount);
      
      // 2. Mock Gateway UI
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Payment"),
          content: Text("Pay \$${fee.amount} using Mock Card?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Pay Now")),
          ],
        )
      );

      if (confirm == true) {
        // 3. Confirm Payment
        await repo.confirmPayment(fee.id, fee.amount, "card");
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Successful!")));
           _loadData(); // Refresh
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("School Fees")),
      body: _students.isEmpty 
        ? const Center(child: Text("No students linked."))
        : ListView.builder(
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              final studentFees = _fees[student.id] ?? [];
              
              return ExpansionTile(
                title: Text(student.fullName),
                subtitle: Text("Grade: ${student.grade}"),
                initiallyExpanded: true,
                children: studentFees.isEmpty 
                  ? [const ListTile(title: Text("No fees found"))]
                  : studentFees.map((fee) => ListTile(
                      title: Text(fee.title),
                      subtitle: Text("Due: ${fee.dueDate.toString().split(' ')[0]}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("\$${fee.amount}  ", style: const TextStyle(fontWeight: FontWeight.bold)),
                          fee.status == 'paid' 
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : ElevatedButton(
                                onPressed: () => _payFee(fee),
                                child: const Text("Pay"),
                              )
                        ],
                      ),
                    )).toList(),
              );
            },
          ),
    );
  }
}
