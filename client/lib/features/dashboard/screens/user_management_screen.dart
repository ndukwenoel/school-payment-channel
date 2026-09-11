import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _selectedRole;
  // Track which school groups are collapsed
  final Set<String> _collapsedSchools = {};

  final List<String> _roles = ['All', 'super_admin', 'admin', 'school_admin', 'teacher', 'staff', 'parent'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      String path = '/users/';
      if (_selectedRole != null && _selectedRole != 'All') {
        path += '?role=$_selectedRole';
      }
      final response = await _apiClient.dio.get(path);
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      }
    }
  }

  /// Groups users by school_name, with "Platform (No School)" for null
  Map<String, List<Map<String, dynamic>>> _groupBySchool() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final user in _users) {
      final school = user['school_name'] ?? 'Platform (No School)';
      grouped.putIfAbsent(school, () => []);
      grouped[school]!.add(user);
    }
    // Sort school names alphabetically, but put "Platform" last
    final sorted = Map.fromEntries(
      grouped.entries.toList()..sort((a, b) {
        if (a.key == 'Platform (No School)') return 1;
        if (b.key == 'Platform (No School)') return -1;
        return a.key.compareTo(b.key);
      }),
    );
    return sorted;
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'super_admin': return Colors.deepPurple;
      case 'admin': return AppTheme.primaryBlue;
      case 'school_admin': return AppTheme.primaryBlue;
      case 'teacher': return AppTheme.success;
      case 'staff': return AppTheme.warning;
      case 'parent': return Colors.teal;
      default: return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupBySchool();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("USER MANAGEMENT",
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRole ?? 'All',
                          items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r == 'All' ? 'All Roles' : r.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            setState(() => _selectedRole = val);
                            _fetchUsers();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue), onPressed: _fetchUsers),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${_users.length} users across ${grouped.length} school${grouped.length == 1 ? '' : 's'}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Center(child: Text('No users found.', style: TextStyle(color: AppTheme.textMuted)))
                      : ListView.builder(
                          itemCount: grouped.length,
                          itemBuilder: (context, index) {
                            final schoolName = grouped.keys.elementAt(index);
                            final schoolUsers = grouped[schoolName]!;
                            final isCollapsed = _collapsedSchools.contains(schoolName);

                            return _buildSchoolGroup(schoolName, schoolUsers, isCollapsed);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolGroup(String schoolName, List<Map<String, dynamic>> users, bool isCollapsed) {
    // Count roles in this school
    final roleCounts = <String, int>{};
    for (final u in users) {
      final r = u['role'] ?? 'unknown';
      roleCounts[r] = (roleCounts[r] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // School header (clickable to collapse/expand)
          InkWell(
            onTap: () {
              setState(() {
                if (isCollapsed) {
                  _collapsedSchools.remove(schoolName);
                } else {
                  _collapsedSchools.add(schoolName);
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.04),
                borderRadius: isCollapsed
                    ? BorderRadius.circular(14)
                    : const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        schoolName == 'Platform (No School)' ? '⚙' : schoolName[0],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(schoolName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: roleCounts.entries.map((e) => _buildRoleChip(e.key, e.value)).toList(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${users.length} users',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  Icon(isCollapsed ? Icons.expand_more : Icons.expand_less, color: AppTheme.textMuted),
                ],
              ),
            ),
          ),
          // User rows (collapsible)
          if (!isCollapsed) ...[
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.background.withOpacity(0.5),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 44, child: Text('ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1))),
                  Expanded(flex: 3, child: Text('NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1))),
                  Expanded(flex: 4, child: Text('EMAIL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1))),
                  Expanded(flex: 2, child: Text('ROLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1))),
                  SizedBox(width: 50, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1))),
                ],
              ),
            ),
            ...users.map((user) => _buildUserRow(user)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _roleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${role.replaceAll('_', ' ')} ($count)',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _roleColor(role)),
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.textMuted.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text('${user['id']}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),
          Expanded(
            flex: 3,
            child: Text(user['full_name'] ?? 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark)),
          ),
          Expanded(
            flex: 4,
            child: Text(user['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor(user['role'] ?? '').withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                (user['role'] ?? '').replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _roleColor(user['role'] ?? ''), letterSpacing: 0.3),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Icon(
              user['is_active'] == true ? Icons.check_circle : Icons.cancel,
              color: user['is_active'] == true ? AppTheme.success : AppTheme.error,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
