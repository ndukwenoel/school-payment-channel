import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

class SchoolManagementScreen extends StatefulWidget {
  const SchoolManagementScreen({super.key});

  @override
  State<SchoolManagementScreen> createState() => _SchoolManagementScreenState();
}

class _SchoolManagementScreenState extends State<SchoolManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> _schools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchools();
  }

  Future<void> _fetchSchools() async {
    setState(() => _isLoading = true);
    try {
      print("Fetching schools...");
      final response = await _apiClient.dio.get('/schools/');
      print("Fetched schools! Data type: ${response.data.runtimeType}, Data: ${response.data}");
      if (mounted) {
        setState(() {
          _schools = (response.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching schools: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load schools: $e')),
        );
      }
    }
  }

  void _showAddSchoolDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    
    final adminNameController = TextEditingController();
    final adminEmailController = TextEditingController();
    final adminPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Onboard New School', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('School Information', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                const SizedBox(height: 12),
                _dialogField(nameController, 'School Name', Icons.school),
                const SizedBox(height: 12),
                _dialogField(addressController, 'Address', Icons.location_on),
                const SizedBox(height: 12),
                _dialogField(emailController, 'Contact Email', Icons.email),
                const SizedBox(height: 12),
                _dialogField(phoneController, 'Contact Phone', Icons.phone),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(),
                ),
                const Text('Admin Account (Owner)', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                const SizedBox(height: 12),
                _dialogField(adminNameController, 'Admin Full Name', Icons.person),
                const SizedBox(height: 12),
                _dialogField(adminEmailController, 'Admin Login Email', Icons.email_outlined),
                const SizedBox(height: 12),
                _dialogField(adminPasswordController, 'Temporary Password', Icons.lock_outline),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, minimumSize: const Size(0, 48)),
            onPressed: () async {
              if (nameController.text.trim().isEmpty || adminEmailController.text.trim().isEmpty || adminPasswordController.text.trim().isEmpty) return;
              try {
                await _apiClient.dio.post('/schools/onboard', data: {
                  'school': {
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim(),
                    'contact_email': emailController.text.trim(),
                    'contact_phone': phoneController.text.trim(),
                  },
                  'admin_email': adminEmailController.text.trim(),
                  'admin_name': adminNameController.text.trim(),
                  'admin_password': adminPasswordController.text.trim(),
                });
                Navigator.pop(ctx);
                _fetchSchools();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('School onboarded successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Create & Assign Admin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditSchoolDialog(Map<String, dynamic> school) {
    final nameController = TextEditingController(text: school['name']);
    final addressController = TextEditingController(text: school['address'] ?? '');
    final emailController = TextEditingController(text: school['contact_email'] ?? '');
    final phoneController = TextEditingController(text: school['contact_phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit ${school['name']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameController, 'School Name', Icons.school),
              const SizedBox(height: 12),
              _dialogField(addressController, 'Address', Icons.location_on),
              const SizedBox(height: 12),
              _dialogField(emailController, 'Contact Email', Icons.email),
              const SizedBox(height: 12),
              _dialogField(phoneController, 'Contact Phone', Icons.phone),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, minimumSize: const Size(0, 48)),
            onPressed: () async {
              try {
                await _apiClient.dio.put('/schools/me', data: {
                  'name': nameController.text.trim(),
                  'address': addressController.text.trim(),
                  'contact_email': emailController.text.trim(),
                  'contact_phone': phoneController.text.trim(),
                });
                Navigator.pop(ctx);
                _fetchSchools();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('School updated successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: AppTheme.background,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("SCHOOL MANAGEMENT DASHBOARD",
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
                  onPressed: _fetchSchools,
                  tooltip: "Refresh List",
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Onboard School'),
                  onPressed: _showAddSchoolDialog,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()))
            else if (_schools.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('No schools found.', style: TextStyle(color: AppTheme.textMuted))))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schools.length,
                itemBuilder: (context, index) {
                  return _buildSchoolTile(_schools[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolTile(Map<String, dynamic> school) {
    final bool isActive = school['status'] != 'suspended';
    final joinedDateStr = school['created_at'] != null ? school['created_at'].toString().split('T')[0] : 'Unknown';
    final dueStr = school['subscription_due_date'] != null ? school['subscription_due_date'].toString().split('T')[0] : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / Monogram
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: school['logo_url'] != null && school['logo_url'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(school['logo_url'], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackLogo(school['name']),
                    ),
                  )
                : _buildFallbackLogo(school['name']),
          ),
          const SizedBox(width: 20),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(school['name'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(isActive ? 'ACTIVE' : 'SUSPENDED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _iconText(Icons.email_outlined, school['contact_email'] ?? 'N/A'),
                    if (school['contact_phone'] != null && school['contact_phone'].toString().isNotEmpty)
                      _iconText(Icons.phone_outlined, school['contact_phone'].toString()),
                    _iconText(Icons.calendar_today_outlined, 'Joined: $joinedDateStr'),
                    _iconText(Icons.event_available_outlined, 'Due: $dueStr'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(school['address'] ?? 'N/A', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Action Buttons Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('ID: ${school['id']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.grid_view, color: AppTheme.primaryBlue),
                    tooltip: 'Manage Modules',
                    onPressed: () => _showManageModulesDialog(school),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue),
                    tooltip: 'Edit School',
                    onPressed: () => _showEditSchoolDialog(school),
                  ),
                  IconButton(
                    icon: Icon(isActive ? Icons.block : Icons.check_circle_outline, color: isActive ? Colors.red : Colors.green),
                    tooltip: isActive ? 'Suspend School' : 'Activate School',
                    onPressed: () => _toggleSchoolStatus(school['id'], isActive),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo(dynamic name) {
    String initial = 'S';
    if (name != null && name.toString().isNotEmpty) {
      initial = name.toString()[0].toUpperCase();
    }
    return Center(
      child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue.withOpacity(0.7))),
      ],
    );
  }

  void _showManageModulesDialog(Map<String, dynamic> school) {
    List<dynamic> enabledModules = [];
    try {
      enabledModules = jsonDecode(school['modules_enabled'] ?? '["academics"]');
    } catch (e) {
      enabledModules = ["academics"];
    }

    // Default modules that can be toggled
    final Map<String, String> availableModules = {
      'academics': 'Academics (Core)',
      'finance': 'Finance & Ledger',
      'hr': 'HR & Payroll',
      'parent_portal': 'Parent Portal',
    };

    // Keep track of state in dialog
    Map<String, bool> currentToggles = {
      for (var key in availableModules.keys) key: enabledModules.contains(key)
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.white,
              title: const Text("Manage Modules", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableModules.entries.map((entry) {
                    final bool isCore = entry.key == 'academics';
                    return SwitchListTile(
                      title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                      activeColor: AppTheme.primaryBlue,
                      value: currentToggles[entry.key]!,
                      onChanged: isCore ? null : (bool value) {
                        setState(() {
                          currentToggles[entry.key] = value;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    minimumSize: const Size(0, 48), // Safely override infinite width
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final newEnabledList = currentToggles.entries.where((e) => e.value).map((e) => e.key).toList();
                    final modulesJson = jsonEncode(newEnabledList);
                    try {
                      await _apiClient.dio.patch(
                        '/schools/${school['id']}',
                        data: {'modules_enabled': modulesJson},
                      );
                      _fetchSchools();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Modules updated successfully!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update modules: $e')),
                      );
                    }
                  },
                  child: const Text("Save Modules", style: TextStyle(color: AppTheme.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleSchoolStatus(int schoolId, bool currentlyActive) async {
    final newStatus = currentlyActive ? 'suspended' : 'active';
    try {
      await _apiClient.dio.patch('/schools/$schoolId', data: {'status': newStatus});
      _fetchSchools();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('School is now $newStatus.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }
}
