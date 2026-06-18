import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../data/erp_repository.dart';
import '../../../core/theme.dart';

class AcademicDashboardPage extends StatelessWidget {
  const AcademicDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildSectionTitle("ACADEMIC OVERVIEW"),
              const SizedBox(height: 16),
              _buildQuickStats(context),
              const SizedBox(height: 32),
              _buildSectionTitle("MY CLASSROOMS"),
              const SizedBox(height: 16),
              _buildClassroomList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("TEACHER CONSOLE", style: TextStyle(color: AppTheme.blueVibrant, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 4),
            const Text("Welcome back, Prof.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.surfaceLight,
          child: const Icon(Icons.person_3_outlined, color: Colors.white),
        )
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1));
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Total Students", "124", Icons.groups_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("Attendance", "98%", Icons.how_to_reg_outlined)),
        const SizedBox(width: 12),
        InkWell(
          onTap: () => context.push('/erp/upload'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(color: AppTheme.blueVibrant, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.upload_file, color: Colors.black),
          ),
        )
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.limeLight, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildClassroomList(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: context.read<ErpRepository>().getClassrooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final rooms = snapshot.data ?? [];
        if (rooms.isEmpty) return const Text("No classrooms assigned.", style: TextStyle(color: Colors.white38));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Section ${room['section']}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
