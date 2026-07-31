import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
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
              Text("EduFlow", style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textDark
              )),
            ],
          ),
          SizedBox(height: 8),
          const Text("ACADEMIC ERP", style: TextStyle(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          
          SizedBox(height: 32),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CORE", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  SizedBox(height: 12),
                  _NavItem(icon: Icons.dashboard_customize, label: "Overview", isSelected: selectedIndex == 0, onTap: () => _onItemTapped(0)),
                  _NavItem(icon: Icons.pie_chart, label: "Executive Dashboard", isSelected: selectedIndex == 11, onTap: () => _onItemTapped(11)),
                  _NavItem(icon: Icons.account_balance, label: "Finance & Settlement", isSelected: selectedIndex == 1, onTap: () => _onItemTapped(1)),
                  _NavItem(icon: Icons.payments, label: "Fee Management", isSelected: selectedIndex == 2, onTap: () => _onItemTapped(2)),
                  _NavItem(icon: Icons.receipt_long, label: "Invoices", isSelected: selectedIndex == 3, onTap: () => _onItemTapped(3)),
                  
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
                  _NavItem(icon: Icons.badge, label: "Staff Registry", isSelected: selectedIndex == 10, onTap: () => _onItemTapped(10)),
                  _NavItem(icon: Icons.account_balance_wallet, label: "HR & Payroll", isSelected: selectedIndex == 7, onTap: () => _onItemTapped(7)),
                  _NavItem(icon: Icons.campaign, label: "Broadcasts", isSelected: selectedIndex == 8, onTap: () => _onItemTapped(8)),
                ],
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dr. Sarah Chen", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark)),
                    Text("School Admin", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 18, color: AppTheme.textMuted),
                onPressed: () {
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
