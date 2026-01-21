import 'package:flutter/material.dart';

class StudentImportPage extends StatelessWidget {
  const StudentImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Import Students")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Icon(Icons.upload_file, size: 64, color: Colors.grey),
             const SizedBox(height: 16),
             const Text("CSV Upload Feature Coming Soon"),
             const SizedBox(height: 16),
             ElevatedButton(onPressed: () {}, child: const Text("Select File"))
          ],
        ),
      ),
    );
  }
}
