import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  final List<Map<String, dynamic>> _subjects = [
    {"id": 1, "name": "Mathematics", "code": "MTH101", "credits": 4},
    {"id": 2, "name": "English Language", "code": "ENG101", "credits": 4},
    {"id": 3, "name": "Basic Science", "code": "BSC101", "credits": 3},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subjects Management"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("All Subjects", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showAddSubjectModal,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Subject"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final s = _subjects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.surfaceLight,
                      child: const Icon(Icons.book, color: AppTheme.primaryBlue),
                    ),
                    title: Text(s["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Code: ${s["code"]} • Credits: ${s["credits"]}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () {
                        // Edit subject
                      },
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  void _showAddSubjectModal() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final credCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Subject"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Subject Name (e.g. Physics)"),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: "Subject Code (e.g. PHY101)"),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: credCtrl,
                  decoration: const InputDecoration(labelText: "Credits"),
                  keyboardType: TextInputType.number,
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    _subjects.add({
                      "id": _subjects.length + 1,
                      "name": nameCtrl.text,
                      "code": codeCtrl.text,
                      "credits": int.tryParse(credCtrl.text) ?? 3,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
