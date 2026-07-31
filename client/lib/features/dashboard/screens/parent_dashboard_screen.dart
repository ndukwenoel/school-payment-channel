import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../data/dashboard_repository.dart';
import '../../auth/presentation/auth_bloc.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  bool _loading = true;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<DashboardRepository>();
      final students = await repo.getMyStudents();
      if (mounted) {
        setState(() {
          _students = students;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.textDark, // Deep navy background
      appBar: AppBar(
        backgroundColor: AppTheme.textDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('School Payment ERP', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const Text('EduPay Parent', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.read<AuthBloc>().add(AuthLogout()),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.1),
            child: const Text('PA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outstanding Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Outstanding Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text("Wallet: ₦15,000.00", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text("₦120,500.00", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                             context.push('/invoices');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("View Invoices & Pay"),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Your Children Section
                  const Text("YOUR CHILDREN & PAYMENT ACCOUNTS", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_students.isEmpty)
                    const Text("No children linked yet.", style: TextStyle(color: AppTheme.textMuted)),
                  ..._students.map((student) => _buildChildCard(student)).toList(),

                  const SizedBox(height: 32),
                  
                  // School Broadcasts Section
                  const Text("SCHOOL BROADCASTS", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Welcome to EduPay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text("You can now transfer directly to your child's dedicated virtual account listed above.", style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChildCard(dynamic student) {
    String initials = student.fullName.isNotEmpty ? student.fullName.substring(0, 2).toUpperCase() : "ST";
    
    // Check for virtual account
    bool hasVirtualAccount = student.virtualAccounts != null && student.virtualAccounts!.isNotEmpty;
    String vaDetails = hasVirtualAccount
        ? '${student.virtualAccounts![0].bankName} • ${student.virtualAccounts![0].accountNumber}'
        : 'No Dedicated Account yet';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 24,
                child: Text(initials, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${student.grade} • ${student.enrollmentNumber}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.school, color: AppTheme.primaryBlueLight),
                tooltip: "View Academics",
                onPressed: () {
                  context.push('/parent/child-academics', extra: student);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.textDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.limeLight.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: AppTheme.limeLight, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Class Transfer Account", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(vaDetails, style: TextStyle(color: hasVirtualAccount ? Colors.white : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      if (hasVirtualAccount) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.redAccent, size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "IMPORTANT: You must include ID (STU-${student.id}) in your transfer narration!",
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
