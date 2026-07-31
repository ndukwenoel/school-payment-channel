import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class RbacPage extends StatefulWidget {
  const RbacPage({super.key});

  @override
  State<RbacPage> createState() => _RbacPageState();
}

class _RbacPageState extends State<RbacPage> {
  final List<Map<String, dynamic>> _roles = [
    {"name": "School Admin", "permissions": ["all"]},
    {"name": "Bursar", "permissions": ["finance.view", "finance.edit", "invoices.create"]},
    {"name": "Teacher", "permissions": ["attendance.mark", "grades.edit"]},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RBAC Management"),
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
                const Text("Roles & Permissions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () {
                    // Create role modal
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("New Role"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _roles.length,
              itemBuilder: (context, index) {
                final role = _roles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(role["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${(role["permissions"] as List).length} Permissions"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: (role["permissions"] as List).map((p) => Chip(label: Text(p), backgroundColor: AppTheme.surfaceLight)).toList(),
                        ),
                      )
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
