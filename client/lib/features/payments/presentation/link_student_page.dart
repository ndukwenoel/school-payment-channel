import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/payment_repository.dart';
import '../../../core/theme.dart';

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
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(title: const Text("LINK STUDENT")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please enter the enrollment number assigned by the school to link your account.",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            SizedBox(height: 32),
            TextField(
              controller: _enrollmentController,
              decoration: const InputDecoration(
                labelText: "Enrollment Number",
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            SizedBox(height: 40),
            _loading 
              ? Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _linkStudent,
                  child: const Text("INITIALIZE LINKING"),
                )
          ],
        ),
      ),
    );
  }
}
