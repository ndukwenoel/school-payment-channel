import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../auth/presentation/auth_bloc.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _enabledModules = ['academics', 'finance', 'hr', 'parent_portal'];

  @override
  void initState() {
    super.initState();
    _fetchSchoolModules();
  }

  Future<void> _fetchSchoolModules() async {
    try {
      final res = await _apiClient.dio.get('/schools/me');
      final modulesStr = res.data['modules_enabled'];
      if (modulesStr != null) {
        if (mounted) {
          setState(() {
            _enabledModules = jsonDecode(modulesStr);
          });
        }
      }
    } catch (e) {
      // Ignore if not found or super admin
    }
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/erp/finance')) return 1;
    if (location.startsWith('/erp/fees')) return 2;
    if (location.startsWith('/invoices')) return 3;
    if (location.startsWith('/erp/academic')) return 4;
    if (location.startsWith('/erp/tests')) return 5;
    if (location.startsWith('/erp/results')) return 6;
    if (location.startsWith('/erp/students')) return 9;
    if (location.startsWith('/erp/payroll')) return 7;
    if (location.startsWith('/erp/broadcasts')) return 8;
    if (location.startsWith('/erp/staff')) return 10;
    if (location.startsWith('/erp/executive')) return 11;
    if (location.startsWith('/erp/school-management')) return 12;
    if (location.startsWith('/erp/user-management')) return 13;
    if (location.startsWith('/erp/platform-billing')) return 14;
    if (location.startsWith('/erp/global-settings')) return 15;
    if (location.startsWith('/erp/audit-logs')) return 16;
    return 0; // Default fallback
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0: context.go('/dashboard'); break;
      case 1: context.go('/erp/finance'); break;
      case 2: context.go('/erp/fees'); break;
      case 3: context.go('/invoices'); break;
      case 4: context.go('/erp/academic'); break;
      case 5: context.go('/erp/tests'); break;
      case 6: context.go('/erp/results'); break;
      case 7: context.go('/erp/payroll'); break;
      case 8: context.go('/erp/broadcasts'); break;
      case 9: context.go('/erp/students'); break;
      case 10: context.go('/erp/staff'); break;
      case 11: context.go('/erp/executive'); break;
      case 12: context.go('/erp/school-management'); break;
      case 13: context.go('/erp/user-management'); break;
      case 14: context.go('/erp/platform-billing'); break;
      case 15: context.go('/erp/global-settings'); break;
      case 16: context.go('/erp/audit-logs'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          _buildSidebar(selectedIndex),
          Expanded(
            child: Container(
              color: AppTheme.background, 
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(int selectedIndex) {
    return Container(
      width: 260,
      color: AppTheme.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: AppTheme.primaryBlue, size: 36),
              SizedBox(width: 12),
              Text("Channel", style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textDark
              )),
            ],
          ),
          SizedBox(height: 8),
          const Text("EDUCATION SYSTEMS", style: TextStyle(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          
          SizedBox(height: 32),
          
          Expanded(
            child: SingleChildScrollView(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  String role = '';
                  if (state is AuthAuthenticated) {
                    role = state.role;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (role == 'super_admin' || role == 'superadmin') ...[
                        const Text("SYSTEM ADMIN", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        SizedBox(height: 12),
                        _NavItem(icon: Icons.dashboard_customize, label: "Overview", isSelected: selectedIndex == 0, onTap: () => _onItemTapped(0)),
                        _NavItem(icon: Icons.pie_chart, label: "Executive Dashboard", isSelected: selectedIndex == 11, onTap: () => _onItemTapped(11)),
                        
                        SizedBox(height: 24),
                        const Text("MANAGEMENT", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        SizedBox(height: 12),
                        _NavItem(icon: Icons.school_rounded, label: "School Management", isSelected: selectedIndex == 12, onTap: () => _onItemTapped(12)),
                        _NavItem(icon: Icons.people_alt_rounded, label: "User Management", isSelected: selectedIndex == 13, onTap: () => _onItemTapped(13)),
                        _NavItem(icon: Icons.receipt_long, label: "Platform Billing", isSelected: selectedIndex == 14, onTap: () => _onItemTapped(14)),
                        
                        SizedBox(height: 24),
                        const Text("SYSTEM CONFIG", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        SizedBox(height: 12),
                        _NavItem(icon: Icons.settings, label: "Global Settings", isSelected: selectedIndex == 15, onTap: () => _onItemTapped(15)),
                        _NavItem(icon: Icons.security, label: "Security Audit Logs", isSelected: selectedIndex == 16, onTap: () => _onItemTapped(16)),
                      ],
                      
                      if (role == 'school_admin' || role == 'admin') ...[
                        const Text("CORE", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        SizedBox(height: 12),
                        _NavItem(icon: Icons.dashboard_customize, label: "Overview", isSelected: selectedIndex == 0, onTap: () => _onItemTapped(0)),
                        if (_enabledModules.contains('finance')) ...[
                          _NavItem(icon: Icons.account_balance, label: "Finance & Settlement", isSelected: selectedIndex == 1, onTap: () => _onItemTapped(1)),
                          _NavItem(icon: Icons.payments, label: "Fee Management", isSelected: selectedIndex == 2, onTap: () => _onItemTapped(2)),
                          _NavItem(icon: Icons.receipt_long, label: "Invoices", isSelected: selectedIndex == 3, onTap: () => _onItemTapped(3)),
                        ],
                        
                        SizedBox(height: 32),
                        const Text("ACADEMIC", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        SizedBox(height: 12),
                        _NavItem(icon: Icons.menu_book, label: "Academics", isSelected: selectedIndex == 4, onTap: () => _onItemTapped(4)),
                        _NavItem(icon: Icons.people_outline, label: "Student Registry", isSelected: selectedIndex == 9, onTap: () => _onItemTapped(9)),
                        _NavItem(icon: Icons.assignment_outlined, label: "Tests & Scores", isSelected: selectedIndex == 5, onTap: () => _onItemTapped(5)),
                        _NavItem(icon: Icons.workspace_premium, label: "Results & Grades", isSelected: selectedIndex == 6, onTap: () => _onItemTapped(6)),

                        SizedBox(height: 32),
                        const Text("ADMIN", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        SizedBox(height: 12),
                        _NavItem(icon: Icons.campaign, label: "Broadcasts", isSelected: selectedIndex == 8, onTap: () => _onItemTapped(8)),
                        if (_enabledModules.contains('hr')) ...[
                          _NavItem(icon: Icons.badge, label: "Staff Registry", isSelected: selectedIndex == 10, onTap: () => _onItemTapped(10)),
                          _NavItem(icon: Icons.account_balance_wallet, label: "HR & Payroll", isSelected: selectedIndex == 7, onTap: () => _onItemTapped(7)),
                        ],
                      ],

                      if (role == 'parent') ...[
                        const Text("PARENT PORTAL", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        SizedBox(height: 12),
                        _NavItem(icon: Icons.dashboard_customize, label: "Overview", isSelected: selectedIndex == 0, onTap: () => _onItemTapped(0)),
                        _NavItem(icon: Icons.receipt_long, label: "Invoices", isSelected: selectedIndex == 3, onTap: () => _onItemTapped(3)),
                        _NavItem(icon: Icons.menu_book, label: "Child Academics", isSelected: selectedIndex == 4, onTap: () => _onItemTapped(4)),
                        _NavItem(icon: Icons.assignment_outlined, label: "Tests & Scores", isSelected: selectedIndex == 5, onTap: () => _onItemTapped(5)),
                      ],

                      if (role == 'teacher') ...[
                        const Text("TEACHER PORTAL", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        SizedBox(height: 12),
                        _NavItem(icon: Icons.dashboard_customize, label: "Overview", isSelected: selectedIndex == 0, onTap: () => _onItemTapped(0)),
                        _NavItem(icon: Icons.menu_book, label: "Academics", isSelected: selectedIndex == 4, onTap: () => _onItemTapped(4)),
                        _NavItem(icon: Icons.people_outline, label: "My Students", isSelected: selectedIndex == 9, onTap: () => _onItemTapped(9)),
                        _NavItem(icon: Icons.assignment_outlined, label: "Tests & Scores", isSelected: selectedIndex == 5, onTap: () => _onItemTapped(5)),
                        _NavItem(icon: Icons.workspace_premium, label: "Results & Grades", isSelected: selectedIndex == 6, onTap: () => _onItemTapped(6)),
                      ],
                    ],
                  );
                }
              ),
            ),
          ),

          SizedBox(height: 16),
          Divider(color: AppTheme.background),
          SizedBox(height: 16),
          // User profile snippet
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryBlueLight,
                radius: 18,
                child: const Text("AD", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    String displayName = "User";
                    String roleName = "Guest";
                    String initial = "U";
                    if (state is AuthAuthenticated) {
                      roleName = state.role;
                      if (state.role == 'super_admin' || state.role == 'superadmin') {
                        displayName = "Super Admin";
                        initial = "SA";
                      } else if (state.role == 'admin' || state.role == 'school_admin') {
                        displayName = "Administrator";
                        initial = "AD";
                      } else if (state.role == 'teacher') {
                        displayName = "Teacher";
                        initial = "TR";
                      } else {
                        displayName = "Parent";
                        initial = "PR";
                      }
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark)),
                        Text(roleName.toUpperCase(), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    );
                  }
                ),
              ),
              IconButton(
                tooltip: "Logout",
                icon: const Icon(Icons.logout, size: 18, color: AppTheme.textMuted),
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogout());
                  context.go('/');
                },
              )
            ],
          )
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.white : AppTheme.textMuted,
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.white : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
