import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/erp_repository.dart';

class StaffRegistryPage extends StatefulWidget {
  const StaffRegistryPage({Key? key}) : super(key: key);

  @override
  _StaffRegistryPageState createState() => _StaffRegistryPageState();
}

class _StaffRegistryPageState extends State<StaffRegistryPage> {
  bool _isLoading = true;
  List<dynamic> _staffList = [];
  List<dynamic> _filteredStaff = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ErpRepository>();
      final staff = await repo.getStaff();
      
      setState(() {
        _staffList = staff;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _applyFilters() {
    _filteredStaff = _staffList.where((s) {
      final searchStr = _searchQuery.toLowerCase();
      final name = (s['full_name'] ?? '').toString().toLowerCase();
      final empId = (s['employee_id'] ?? '').toString().toLowerCase();
      
      return _searchQuery.isEmpty || name.contains(searchStr) || empId.contains(searchStr);
    }).toList();
  }

  void _showAddStaffDialog() {
    final formKey = GlobalKey<FormState>();
    String fullName = '';
    String email = '';
    String employeeId = '';
    String designation = 'Teacher';
    double baseSalary = 5000.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New Staff'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => fullName = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
                  onSaved: (v) => email = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Employee ID'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => employeeId = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Designation'),
                  initialValue: designation,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => designation = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Base Salary'),
                  initialValue: baseSalary.toString(),
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v!) == null ? 'Must be a number' : null,
                  onSaved: (v) => baseSalary = double.parse(v!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(ctx);
                
                try {
                  await context.read<ErpRepository>().createStaff({
                    'full_name': fullName,
                    'email': email,
                    'employee_id': employeeId,
                    'designation': designation,
                    'base_salary': baseSalary,
                  });
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Staff Registry'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffDialog,
        icon: Icon(Icons.person_add),
        label: Text('New Staff'),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.white,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or employee ID...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (v) {
                    setState(() {
                      _searchQuery = v;
                      _applyFilters();
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _filteredStaff.length,
                  itemBuilder: (ctx, i) {
                    final staff = _filteredStaff[i];
                    final name = staff['full_name'] ?? 'Unknown Staff';
                    final email = staff['email'] ?? 'No email';
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo[50],
                          child: Text(
                            name[0].toUpperCase(),
                            style: TextStyle(color: Colors.indigo[800], fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text('${staff['employee_id']} • $email'),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                staff['designation'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            )
                          ],
                        ),
                        trailing: Text(
                          '₦${staff['base_salary']?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
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
