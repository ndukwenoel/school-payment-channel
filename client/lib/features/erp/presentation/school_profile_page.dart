import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class SchoolProfilePage extends StatefulWidget {
  const SchoolProfilePage({super.key});

  @override
  State<SchoolProfilePage> createState() => _SchoolProfilePageState();
}

class _SchoolProfilePageState extends State<SchoolProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Profile
  final _nameController = TextEditingController(text: "Greenwood High");
  final _addressController = TextEditingController(text: "123 Education Lane");
  final _contactController = TextEditingController(text: "+234800000000");

  // Global Settings
  bool _enableLateFees = true;
  final _lateFeePercentageController = TextEditingController(text: "5.0");
  final _gracePeriodController = TextEditingController(text: "7");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("School Profile & Settings"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("School Profile"),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.surfaceLight,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
                            onPressed: () {
                              // Use file picker to upload logo_url
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: "School Name", border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: "Address", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactController,
                        decoration: const InputDecoration(labelText: "Contact Number", border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle("Global Payment Settings"),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text("Enable Late Fees"),
                        subtitle: const Text("Automatically apply late fees to overdue invoices"),
                        value: _enableLateFees,
                        onChanged: (val) => setState(() => _enableLateFees = val),
                        activeColor: AppTheme.primaryBlue,
                      ),
                      if (_enableLateFees) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lateFeePercentageController,
                          decoration: const InputDecoration(labelText: "Late Fee Percentage (%)", border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _gracePeriodController,
                          decoration: const InputDecoration(labelText: "Grace Period (Days)", border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings updated successfully")));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                  child: const Text("Save Changes"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
    );
  }
}
