import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/erp_repository.dart';
import '../../../core/theme.dart';
import '../../dashboard/data/dashboard_repository.dart'; // For School info helpers if needed

class BroadcastPage extends StatefulWidget {
  const BroadcastPage({super.key});

  @override
  State<BroadcastPage> createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _type = "newsletter";
  bool _loading = false;

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final repo = context.read<ErpRepository>();
      // We don't have school_id handy here easily without fetching me, 
      // but the backend uses current_user.school_id mostly. 
      // Wait, schemas.BroadcastCreate REQUIRES school_id. 
      // We should fetch 'me' first or store school_id in AuthState.
      // For now, let's fetch 'me' or assume backend can infer if we change schema? No, strictly schema validation.
      // Let's get school ID from DashboardRepository quick (cached ideally, but we fetch new).
      
      final school = await context.read<DashboardRepository>().getMySchool();
      
      await repo.createBroadcast({
        "title": _titleController.text,
        "message": _messageController.text,
        "type": _type,
        "school_id": school.id
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Broadcast sent successfully!")));
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
      appBar: AppBar(title: const Text("BROADCAST CENTER")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("MASS COMMUNICATION", style: TextStyle(color: AppTheme.limeLight, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              const Text(
                "Send newsletters, alerts, or event notifications to all registered parents.",
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: AppTheme.surfaceLight,
                items: ["newsletter", "alert", "event"].map((t) => 
                  DropdownMenuItem(value: t, child: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white)))
                ).toList(),
                onChanged: (v) => setState(() => _type = v!),
                decoration: const InputDecoration(labelText: "Broadcast Type"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Subject / Title"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: "Message Body"),
                maxLines: 6,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _sendBroadcast,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blueVibrant),
                  icon: const Icon(Icons.send),
                  label: _loading ? const CircularProgressIndicator() : const Text("SEND BROADCAST"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
