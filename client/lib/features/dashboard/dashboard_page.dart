import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/features/dashboard/data/dashboard_repository.dart';
import 'package:client/core/theme.dart';
import 'package:client/core/api_client.dart';

// Simple StatefulWidget for MVP instead of full Bloc for now to save tokens/time
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DashboardRepository _repo;
  bool _loading = true;
  School? _school;
  List<Student> _students = [];

  @override
  void initState() {
    super.initState();
    // In real app, inject repo via Provider/GetIt
    _repo = DashboardRepository(ApiClient());
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final school = await _repo.getMySchool();
      final students = await _repo.getStudents();
      if (mounted) {
        setState(() {
          _school = school;
          _students = students;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading data: $e")));
      }
    }
  }

  @override
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
              const SizedBox(height: 5),
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
        child: FutureBuilder<Map<String, dynamic>>(
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
        ),
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
              const SizedBox(width: 40),
              _buildStatItem("REVENUE", "?${stats['total_revenue']}", AppTheme.limeLight),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.textMuted.withOpacity(0.1)),
          const SizedBox(height: 24),
          _buildStatItem("OUTSTANDING", "?${stats['outstanding_fees']}", AppTheme.bluePale, large: true),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String val, Color color, {bool large = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted.withOpacity(0.5), fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: large ? 32 : 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }



  Widget _buildRecentStudents() {
    return FutureBuilder<List<Student>>(
      future: context.read<DashboardRepository>().getStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }
        final students = snapshot.data ?? [];
        if (students.isEmpty) return const Text("No recent students found.", style: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)));
        
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
              subtitle: Text(s.enrollmentNumber, style: const TextStyle(color: AppTheme.textMuted.withOpacity(0.5), fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted.withOpacity(0.1)),
            ),
          )).toList(),
        );
      },
    );
  }
}
