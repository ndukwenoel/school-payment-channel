import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/auth_bloc.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  // Mock data for schools
  List<Map<String, dynamic>> schools = [
    {"id": 1, "name": "Greenwood High", "status": "active", "students": 1200},
    {"id": 2, "name": "Oakridge Academy", "status": "pending", "students": 0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Super Admin - School Enrollment"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogout());
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Enrolled Schools", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showEnrollSchoolModal,
                  icon: const Icon(Icons.add),
                  label: const Text("Enroll New School"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: schools.length,
              itemBuilder: (context, index) {
                final school = schools[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlueLight,
                      child: const Icon(Icons.school, color: AppTheme.primaryBlue),
                    ),
                    title: Text(school["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${school["students"]} Students Enrolled"),
                    trailing: Chip(
                      label: Text(school["status"].toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                      backgroundColor: school["status"] == "active" ? Colors.green : Colors.orange,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEnrollSchoolModal() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enroll New School"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "School Name"),
                  validator: (val) => val!.isEmpty ? "Enter school name" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Admin Email"),
                  validator: (val) => val!.isEmpty ? "Enter admin email" : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    schools.add({
                      "id": schools.length + 1,
                      "name": nameController.text,
                      "status": "pending",
                      "students": 0,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("School enrolled successfully!")));
                }
              },
              child: const Text("Enroll"),
            ),
          ],
        );
      },
    );
  }
}
