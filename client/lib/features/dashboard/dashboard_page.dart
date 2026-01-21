import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/dashboard_repository.dart';
import '../../../core/api_client.dart';

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
      appBar: AppBar(title: const Text("Dashboard")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: context.read<DashboardRepository>().getStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final stats = snapshot.data ?? {
             'total_students': 0, 'total_revenue': 0.0, 'outstanding_fees': 0.0
          };
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text("Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 10),
                   Row(
                    children: [
                      _buildStatCard("Students", "${stats['total_students']}", Colors.blue),
                      const SizedBox(width: 10),
                      _buildStatCard("Revenue", "\$${stats['total_revenue']}", Colors.green),
                    ],
                   ),
                   const SizedBox(height: 10),
                   Row(
                    children: [
                      _buildStatCard("Outstanding", "\$${stats['outstanding_fees']}", Colors.orange),
                    ],
                   ),
                   const SizedBox(height: 20),
                   const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   Wrap(
                    spacing: 10,
                    children: [
                       ActionChip(label: const Text("Link Student"), onPressed: () => context.push('/link-student')),
                       ActionChip(label: const Text("Create Fee"), onPressed: () => context.push('/create-fee')),
                       ActionChip(label: const Text("Pay Fees"), onPressed: () => context.push('/fees')),
                       ActionChip(label: const Text("History"), onPressed: () => context.push('/history')),
                       ActionChip(label: const Text("Notifications"), onPressed: () => context.push('/notifications')),
                    ],
                   ),
                   const SizedBox(height: 20),
                   const Text("Recent Students", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   FutureBuilder<List<Student>>(
                    future: context.read<DashboardRepository>().getStudents(),
                    builder: (context, studentSnapshot) {
                        if (studentSnapshot.connectionState == ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }
                        final students = studentSnapshot.data ?? [];
                        if (students.isEmpty) return const Text("No students found.");
                        
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: students.length > 5 ? 5 : students.length,
                          itemBuilder: (context, index) {
                            final s = students[index];
                            return ListTile(
                              leading: CircleAvatar(child: Text(s.fullName[0])),
                              title: Text(s.fullName),
                              subtitle: Text(s.enrollmentNumber),
                            );
                          },
                        );
                    }
                   )
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
