import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/payment_repository.dart';

class LinkStudentPage extends StatefulWidget {
  const LinkStudentPage({super.key});

  @override
  State<LinkStudentPage> createState() => _LinkStudentPageState();
}

class _LinkStudentPageState extends State<LinkStudentPage> {
  final _enrollmentController = TextEditingController();
  bool _loading = false;

  void _linkStudent() async {
    setState(() => _loading = true);
    try {
      await context.read<PaymentRepository>().linkStudent(_enrollmentController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Student linked successfully!")));
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
      appBar: AppBar(title: const Text("Link Student")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Enter your child's enrollment number to link them to your account."),
            const SizedBox(height: 16),
            TextField(
              controller: _enrollmentController,
              decoration: const InputDecoration(labelText: "Enrollment Number", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            _loading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _linkStudent, child: const Text("Link Student"))
          ],
        ),
      ),
    );
  }
}
