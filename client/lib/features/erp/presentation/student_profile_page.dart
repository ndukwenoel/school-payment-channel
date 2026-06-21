import 'package:flutter/material.dart';

class StudentProfilePage extends StatelessWidget {
  final dynamic student;

  const StudentProfilePage({Key? key, required this.student}) : super(key: key);

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(flex: 3, child: Text(value, style: TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${student['full_name']} Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: student['profile_picture_url'] != null ? NetworkImage(student['profile_picture_url']) : null,
                    child: student['profile_picture_url'] == null 
                      ? Text(student['full_name'][0].toUpperCase(), style: TextStyle(fontSize: 40, color: Colors.blue[800]))
                      : null,
                  ),
                  SizedBox(height: 16),
                  Text(student['full_name'], style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${student['enrollment_number']} • ${student['grade']}', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  SizedBox(height: 8),
                  Chip(
                    label: Text((student['status'] ?? 'Active').toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: student['status'] == 'suspended' ? Colors.red : Colors.green,
                  )
                ],
              ),
            ),
            SizedBox(height: 24),

            _buildSection(context, 'Personal Information', [
              _buildInfoRow('Date of Birth', student['date_of_birth']?.toString().split('T')[0] ?? 'N/A'),
              _buildInfoRow('Gender', student['gender'] ?? 'N/A'),
              _buildInfoRow('Home Address', student['home_address'] ?? 'N/A'),
            ]),

            _buildSection(context, 'Academic Details', [
              _buildInfoRow('Enrollment No.', student['enrollment_number']),
              _buildInfoRow('Current Grade', student['grade']),
              _buildInfoRow('Classroom', student['classroom_name'] ?? 'Unassigned'),
              _buildInfoRow('Admission Date', student['admission_date']?.toString().split('T')[0] ?? 'N/A'),
            ]),

            _buildSection(context, 'Medical History', [
              _buildInfoRow('Blood Group', student['blood_group'] ?? 'N/A'),
              _buildInfoRow('Genotype', student['genotype'] ?? 'N/A'),
              _buildInfoRow('Allergies', student['allergies'] ?? 'None'),
              _buildInfoRow('Medical Conditions', student['medical_conditions'] ?? 'None'),
            ]),

            _buildSection(context, 'Emergency Contact', [
              _buildInfoRow('Contact Name', student['emergency_contact_name'] ?? 'N/A'),
              _buildInfoRow('Contact Phone', student['emergency_contact_phone'] ?? 'N/A'),
            ]),
          ],
        ),
      ),
    );
  }
}
