import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/erp_repository.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../../core/theme.dart';
import '../../../core/offline_exceptions.dart';

// --- TEACHER VIEW: UPLOAD ---
class ResourceUploadPage extends StatefulWidget {
  const ResourceUploadPage({super.key});

  @override
  State<ResourceUploadPage> createState() => _ResourceUploadPageState();
}

class _ResourceUploadPageState extends State<ResourceUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController(); // Simulating file upload with URL
  String _type = "note";
  String _visibility = "internal";
  bool _loading = false;

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final school = await context.read<DashboardRepository>().getMySchool();
      
      await context.read<ErpRepository>().uploadResource({
        "title": _titleController.text,
        "file_url": _linkController.text,
        "type": _type,
        "visibility": _visibility,
        "school_id": school.id
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resource uploaded successfully!")));
        context.pop();
      }
    } catch (e) {
      if (e is OfflineQueuedException && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
             content: Text("No Network. Resource saved offline.", style: TextStyle(color: AppTheme.textDark)),
             backgroundColor: Colors.orange,
           ));
           context.pop(); // Close page as if successful
      } else if (mounted) {
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
      appBar: AppBar(title: const Text("UPLOAD RESOURCE")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
               DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: AppTheme.surfaceLight,
                items: ["note", "exam", "test"].map((t) => 
                  DropdownMenuItem(value: t, child: Text(t.toUpperCase(), style: const TextStyle(color: AppTheme.textDark)))
                ).toList(),
                onChanged: (v) => setState(() {
                  _type = v!;
                  // Force internal if exam/test
                  if (_type == "exam" || _type == "test") _visibility = "internal";
                }),
                decoration: const InputDecoration(labelText: "Resource Type"),
              ),
              const SizedBox(height: 16),
              // Visibility Toggle (Only active if not exam/test)
               DropdownButtonFormField<String>(
                value: _visibility,
                dropdownColor: AppTheme.surfaceLight,
                items: ["internal", "public"].map((t) => 
                  DropdownMenuItem(value: t, child: Text(t.toUpperCase(), style: const TextStyle(color: AppTheme.textDark)))
                ).toList(),
                onChanged: (_type == "exam" || _type == "test") ? null : (v) => setState(() => _visibility = v!),
                decoration: const InputDecoration(labelText: "Visibility", helperText: "Exams/Tests are strictly Internal"),
              ),
               const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(labelText: "File Link (Drive/Dropbox etc)"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _loading ? null : _upload, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.blueVibrant), child: _loading ? const CircularProgressIndicator() : const Text("SUBMIT FOR REVIEW")),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- ADMIN VIEW: REVIEW ---
class ResourceReviewPage extends StatefulWidget {
  const ResourceReviewPage({super.key});

  @override
  State<ResourceReviewPage> createState() => _ResourceReviewPageState();
}

class _ResourceReviewPageState extends State<ResourceReviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(title: const Text("PENDING APPROVALS")),
      body: FutureBuilder<List<dynamic>>(
        future: context.read<ErpRepository>().getPendingResources(),
        builder: (context, snapshot) {
           if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
           final items = snapshot.data ?? [];
           
           if (items.isEmpty) return const Center(child: Text("No pending resources.", style: TextStyle(color: AppTheme.textMuted.withOpacity(0.5))));
           
           return ListView.separated(
             padding: const EdgeInsets.all(16),
             itemCount: items.length,
             separatorBuilder: (_, __) => const SizedBox(height: 12),
             itemBuilder: (context, index) {
               final item = items[index];
               final isExam = item['type'] == 'exam' || item['type'] == 'test';
               
               return Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(12)),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(color: isExam ? Colors.redAccent : Colors.teal, borderRadius: BorderRadius.circular(4)),
                           child: Text(item['type'].toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                         ),
                         const SizedBox(width: 8),
                         if (item['visibility'] == 'internal')
                            const Icon(Icons.lock_outline, size: 14, color: AppTheme.textMuted),
                       ],
                     ),
                     const SizedBox(height: 8),
                     Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     Text(item['file_url'], style: const TextStyle(color: AppTheme.bluePale, fontSize: 12)),
                     const SizedBox(height: 16),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         TextButton(
                           onPressed: () => _updateStatus(item['id'], "rejected"),
                           child: const Text("REJECT", style: TextStyle(color: Colors.redAccent)),
                         ),
                         const SizedBox(width: 8),
                         ElevatedButton(
                           onPressed: () => _updateStatus(item['id'], "approved"),
                           style: ElevatedButton.styleFrom(backgroundColor: AppTheme.limeLight, foregroundColor: Colors.black),
                           child: const Text("APPROVE"),
                         )
                       ],
                     )
                   ],
                 ),
               );
             },
           );
        },
      ),
    );
  }
  
  void _updateStatus(int id, String status) async {
    try {
      await context.read<ErpRepository>().updateResourceStatus(id, status);
      setState(() {}); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
