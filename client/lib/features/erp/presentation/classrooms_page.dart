import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class ClassroomsPage extends StatefulWidget {
  const ClassroomsPage({super.key});

  @override
  State<ClassroomsPage> createState() => _ClassroomsPageState();
}

class _ClassroomsPageState extends State<ClassroomsPage> {
  final List<Map<String, dynamic>> _classrooms = [
    {"id": 1, "name": "JSS 1A", "capacity": 30, "enrolled": 28},
    {"id": 2, "name": "JSS 1B", "capacity": 30, "enrolled": 30},
    {"id": 3, "name": "SS 3 Science", "capacity": 25, "enrolled": 20},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Classrooms Management"),
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
                const Text("All Classrooms", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showAddClassroomModal,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Classroom"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _classrooms.length,
              itemBuilder: (context, index) {
                final c = _classrooms[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.surfaceLight,
                      child: const Icon(Icons.room, color: AppTheme.primaryBlue),
                    ),
                    title: Text(c["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Capacity: ${c["capacity"]} • Enrolled: ${c["enrolled"]}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () {
                        // Edit classroom
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

  void _showAddClassroomModal() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final capCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Classroom"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Classroom Name (e.g. Grade 1A)"),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: capCtrl,
                  decoration: const InputDecoration(labelText: "Capacity"),
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
                    _classrooms.add({
                      "id": _classrooms.length + 1,
                      "name": nameCtrl.text,
                      "capacity": int.tryParse(capCtrl.text) ?? 30,
                      "enrolled": 0,
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
