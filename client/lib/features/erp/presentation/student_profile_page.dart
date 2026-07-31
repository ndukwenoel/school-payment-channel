import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../dashboard/data/dashboard_repository.dart';

class StudentProfilePage extends StatefulWidget {
  final dynamic student;

  const StudentProfilePage({Key? key, required this.student}) : super(key: key);

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  bool _loadingInvoices = true;
  List<dynamic> _invoices = [];
  List<String> _uploadedDocuments = []; // Mock documents

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final repo = context.read<DashboardRepository>();
      final results = await repo.getStudentInvoices(widget.student['id']);
      if (mounted) {
        setState(() {
          _invoices = results;
          _loadingInvoices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingInvoices = false);
      }
    }
  }

  Future<void> _convertToInstallments(int invoiceId, double totalAmount) async {
    try {
      // Split into 4 monthly installments
      final installments = List.generate(4, (i) => {
        'amount_due': totalAmount / 4,
        'due_date': DateTime.now().add(Duration(days: 30 * (i + 1))).toIso8601String()
      });
      
      await context.read<DashboardRepository>().createInstallmentPlan(invoiceId, installments);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice successfully split into an Installment Plan! Parent will be notified.')));
        _loadInvoices(); // Refresh invoices to show updated state
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

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
    final student = widget.student;
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('${student['full_name']} Profile'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Medical"),
              Tab(text: "Documents"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(student),
            _buildMedicalTab(student),
            _buildDocumentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(dynamic student) {
    return SingleChildScrollView(
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
            
            _buildSection(context, 'Finance & Billing', [
              if (_loadingInvoices) const Center(child: CircularProgressIndicator())
              else if (_invoices.isEmpty) const Text("No invoices found for this student.")
              else ..._invoices.map((inv) {
                final hasInstallments = inv['installment_plan'] != null;
                final total = inv['total_amount'] ?? 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inv['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("₦${total.toStringAsFixed(2)} • ${inv['status'].toUpperCase()}", style: TextStyle(fontSize: 12, color: Colors.blue[800])),
                        ],
                      ),
                      if (inv['status'] != 'paid' && !hasInstallments)
                         ElevatedButton(
                           onPressed: () => _convertToInstallments(inv['id'], total),
                           style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                           child: const Text("Split Bill", style: TextStyle(fontSize: 12, color: Colors.white)),
                         )
                      else if (hasInstallments)
                         const Chip(label: Text("Installments Active", style: TextStyle(fontSize: 10)))
                    ],
                  ),
                );
              }).toList()
            ]),

          ],
        ),
      );
  }

  Widget _buildMedicalTab(dynamic student) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
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
    );
  }

  Widget _buildDocumentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              await Future.delayed(const Duration(milliseconds: 500));
              setState(() {
                _uploadedDocuments.add("mock_document_${DateTime.now().millisecondsSinceEpoch}.pdf");
              });
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Document uploaded!")));
            },
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload New Document"),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _uploadedDocuments.isEmpty 
              ? const Center(child: Text("No documents uploaded yet.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _uploadedDocuments.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.description, color: Colors.blue),
                        title: Text(_uploadedDocuments[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => _uploadedDocuments.removeAt(index));
                          },
                        ),
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }
}
