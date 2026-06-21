import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/erp_repository.dart';
import 'student_profile_page.dart';

class StudentRegistryPage extends StatefulWidget {
  const StudentRegistryPage({Key? key}) : super(key: key);
  
  @override
  _StudentRegistryPageState createState() => _StudentRegistryPageState();
}

class _StudentRegistryPageState extends State<StudentRegistryPage> {
  bool _isLoading = true;
  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  List<dynamic> _classrooms = [];
  String _searchQuery = '';
  String? _selectedGradeFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<ErpRepository>();
      final results = await Future.wait([
        repo.getStudents(),
        repo.getClassrooms(),
      ]);
      
      setState(() {
        _students = results[0];
        _classrooms = results[1];
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
    _filteredStudents = _students.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s['full_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s['enrollment_number'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
          
      final matchesGrade = _selectedGradeFilter == null || s['grade'] == _selectedGradeFilter;
      
      return matchesSearch && matchesGrade;
    }).toList();
  }

  void _showAddStudentDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String enrollment = '';
    String grade = '10th Grade'; // Default
    String parentEmail = '';
    int? selectedClassroom;
    
    // New Comprehensive Fields
    String? dob;
    String? gender;
    String? address;
    String? contactName;
    String? contactPhone;
    String? bloodGroup;
    String? allergies;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New Student'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => name = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Enrollment Number'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => enrollment = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Grade (e.g. 10th Grade)'),
                  initialValue: grade,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  onSaved: (v) => grade = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Parent Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
                  onSaved: (v) => parentEmail = v!,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(labelText: 'Assign Classroom (Optional)'),
                  value: selectedClassroom,
                  items: [
                    DropdownMenuItem<int>(value: null, child: Text('Unassigned')),
                    ..._classrooms.map((c) => DropdownMenuItem<int>(
                      value: c['id'],
                      child: Text('${c['name']} ${c['section'] ?? ''}'),
                    )).toList()
                  ],
                  onChanged: (v) => selectedClassroom = v,
                ),
                SizedBox(height: 16),
                Text('Comprehensive Profile (Optional)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
                  onSaved: (v) => dob = v,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Gender'),
                  onSaved: (v) => gender = v,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Home Address'),
                  onSaved: (v) => address = v,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Emergency Contact Name'),
                  onSaved: (v) => contactName = v,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Emergency Contact Phone'),
                  onSaved: (v) => contactPhone = v,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Blood Group'),
                  onSaved: (v) => bloodGroup = v,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Allergies'),
                  onSaved: (v) => allergies = v,
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
                  await context.read<ErpRepository>().createStudent({
                    'full_name': name,
                    'enrollment_number': enrollment,
                    'grade': grade,
                    'parent_email': parentEmail,
                    'classroom_id': selectedClassroom,
                    'date_of_birth': dob?.isEmpty ?? true ? null : '${dob}T00:00:00Z',
                    'gender': gender,
                    'home_address': address,
                    'emergency_contact_name': contactName,
                    'emergency_contact_phone': contactPhone,
                    'blood_group': bloodGroup,
                    'allergies': allergies,
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

  void _showEditStudentSheet(dynamic student) {
    int? currentClassroom = student['classroom_id'];
    String currentGrade = student['grade'];
    String? currentAddress = student['home_address'];
    String? currentStatus = student['status'];
    String? currentAllergies = student['allergies'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit ${student['full_name']}', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Grade'),
                initialValue: currentGrade,
                onChanged: (v) => currentGrade = v,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Classroom'),
                value: currentClassroom,
                items: [
                  DropdownMenuItem<int>(value: null, child: Text('Unassigned')),
                  ..._classrooms.map((c) => DropdownMenuItem<int>(
                    value: c['id'],
                    child: Text('${c['name']} ${c['section'] ?? ''}'),
                  )).toList()
                ],
                onChanged: (v) => setSheetState(() => currentClassroom = v),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Home Address'),
                initialValue: currentAddress,
                onChanged: (v) => currentAddress = v,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Allergies'),
                initialValue: currentAllergies,
                onChanged: (v) => currentAllergies = v,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Status'),
                value: currentStatus ?? 'active',
                items: ['active', 'suspended', 'graduated', 'transferred']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                    .toList(),
                onChanged: (v) => setSheetState(() => currentStatus = v),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await context.read<ErpRepository>().updateStudent(student['id'], {
                        'grade': currentGrade,
                        'classroom_id': currentClassroom,
                        'home_address': currentAddress,
                        'allergies': currentAllergies,
                        'status': currentStatus,
                      });
                      _loadData();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: Text('Save Changes'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get unique grades for filter
    final grades = _students.map((e) => e['grade'].toString()).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Student Registry'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        icon: Icon(Icons.add),
        label: Text('New Student'),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Filters Header
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name or enrollment #...',
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
                    SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text('All Grades'),
                            selected: _selectedGradeFilter == null,
                            onSelected: (b) {
                              setState(() {
                                _selectedGradeFilter = null;
                                _applyFilters();
                              });
                            },
                          ),
                          SizedBox(width: 8),
                          ...grades.map((g) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(g),
                              selected: _selectedGradeFilter == g,
                              onSelected: (b) {
                                setState(() {
                                  _selectedGradeFilter = b ? g : null;
                                  _applyFilters();
                                });
                              },
                            ),
                          )).toList(),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _filteredStudents.length,
                  itemBuilder: (ctx, i) {
                    final student = _filteredStudents[i];
                    final classroomName = student['classroom_name'];
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: Text(
                            student['full_name'][0].toUpperCase(),
                            style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(student['full_name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text('${student['enrollment_number']} • ${student['grade']}'),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: classroomName != null ? Colors.green[50] : Colors.orange[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                classroomName ?? 'Unassigned',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: classroomName != null ? Colors.green[800] : Colors.orange[800],
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            )
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                          onPressed: () => _showEditStudentSheet(student),
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentProfilePage(student: student))),
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
