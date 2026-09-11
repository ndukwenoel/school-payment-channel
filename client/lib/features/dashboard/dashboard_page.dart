import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/features/dashboard/data/dashboard_repository.dart';
import 'package:client/core/theme.dart';
import 'package:client/core/api_client.dart';
import 'package:client/features/auth/presentation/auth_bloc.dart';

// Simple StatefulWidget for MVP instead of full Bloc for now to save tokens/time
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  @override
  void initState() {
    super.initState();
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            String role = '';
            if (state is AuthAuthenticated) {
              role = state.role;
            }

            if (role == 'super_admin' || role == 'superadmin') {
              return _buildSuperAdminDashboard();
            } else if (role == 'parent') {
              return _buildParentDashboard();
            } else if (role == 'teacher') {
              return _buildTeacherDashboard();
            } else {
              return _buildSchoolAdminDashboard();
            }
          }
        ),
      ),
    );
  }

  Widget _buildSchoolAdminDashboard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<DashboardRepository>().getStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final stats = snapshot.data ?? {
           'total_students': 0, 'total_revenue': 0.0, 'outstanding_fees': 0.0
        };
        
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "ADMIN CONSOLE",
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold),
                ),
              ),
              _buildHeroStats(stats),
              const SizedBox(height: 32),
              const Text("RECENT ENROLLMENTS", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 12),
              _buildRecentStudents(),
              const SizedBox(height: 40),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSuperAdminDashboard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<DashboardRepository>().getSystemStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final stats = snapshot.data ?? {
           'total_schools': 0, 'total_students': 0, 'total_users': 0, 'schools': []
        };
        final List schools = stats['schools'] ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "SYSTEM ADMIN CONSOLE",
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold),
                ),
              ),
              // Summary stat cards
              Row(
                children: [
                  _buildSummaryCard("Schools", "${stats['total_schools']}", Icons.school_rounded, AppTheme.primaryBlue),
                  const SizedBox(width: 16),
                  _buildSummaryCard("Students", "${stats['total_students']}", Icons.people_alt_rounded, AppTheme.success),
                  const SizedBox(width: 16),
                  _buildSummaryCard("Users", "${stats['total_users']}", Icons.person_rounded, AppTheme.warning),
                ],
              ),
              const SizedBox(height: 28),
              // School listing
              const Text(
                "REGISTERED SCHOOLS",
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...schools.map((school) => _buildSchoolCard(school)).toList(),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolCard(Map<String, dynamic> school) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: school['logo_url'] != null && school['logo_url'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(school['logo_url'], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text("${school['name']?[0] ?? 'S'}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      ),
                    ),
                  )
                : Center(
                    child: Text("${school['name']?[0] ?? 'S'}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school['name'] ?? 'Unknown School',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  school['address'] ?? '',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  school['contact_email'] ?? '',
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue.withOpacity(0.7)),
                ),
                if (school['contact_phone'] != null && school['contact_phone'].toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(school['contact_phone'], style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildSchoolStat("Students", "${school['student_count'] ?? 0}", AppTheme.success),
          const SizedBox(width: 20),
          _buildSchoolStat("Staff", "${school['staff_count'] ?? 0}", AppTheme.warning),
        ],
      ),
    );
  }

  Widget _buildSchoolStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildParentDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              "PARENT PORTAL",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Text("Welcome! Your children's academic and financial summaries will appear here.", style: TextStyle(color: AppTheme.textMuted50)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherDashboard() {
    return FutureBuilder<List<Student>>(
      future: context.read<DashboardRepository>().getStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final students = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "TEACHER PORTAL",
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  _buildSummaryCard("Students", "${students.length}", Icons.people, AppTheme.blueVibrant),
                  const SizedBox(width: 16),
                  _buildSummaryCard("Pending Tasks", "0", Icons.pending_actions, AppTheme.warning),
                ],
              ),
              const SizedBox(height: 32),
              const Text("TODAY'S SCHEDULE", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: const Text("Schedule features coming soon.", style: TextStyle(color: AppTheme.textMuted50)),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTeacherScheduleCard(String time, String subject, String section, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(time, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                SizedBox(height: 4),
                Text(section, style: const TextStyle(color: AppTheme.textMuted50, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted10, size: 16),
        ],
      ),
    );
  }

  Widget _buildHeroStats(Map<String, dynamic> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem("STUDENTS", "${stats['total_students']}", AppTheme.blueVibrant),
              SizedBox(width: 40),
              _buildStatItem("REVENUE", "₦${stats['total_revenue']}", AppTheme.limeLight),
            ],
          ),
          SizedBox(height: 24),
          Divider(color: AppTheme.textMuted10),
          SizedBox(height: 24),
          _buildStatItem("OUTSTANDING", "₦${stats['outstanding_fees']}", AppTheme.bluePale, large: true),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String val, Color color, {bool large = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted50, fontSize: 10, letterSpacing: 1)),
        SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: large ? 32 : 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }



  Widget _buildRecentStudents() {
    return FutureBuilder<List<Student>>(
      future: context.read<DashboardRepository>().getStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: LinearProgressIndicator());
        }
        final students = snapshot.data ?? [];
        if (students.isEmpty) return const Text("No recent students found.", style: TextStyle(color: AppTheme.textMuted50));
        
        return Column(
          children: students.take(5).map((s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.blueVibrant.withOpacity(0.1),
                child: Text(s.fullName[0], style: const TextStyle(color: AppTheme.blueVibrant)),
              ),
              title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(s.enrollmentNumber, style: const TextStyle(color: AppTheme.textMuted50, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted10),
            ),
          )).toList(),
        );
      },
    );
  }
}
