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
              SizedBox(height: 32),
              _buildSectionTitle("ACADEMIC OVERVIEW"),
              SizedBox(height: 16),
              _buildQuickStats(context),
              SizedBox(height: 32),
              _buildSectionTitle("MY CLASSROOMS"),
              SizedBox(height: 16),
              _buildClassroomList(context),
              SizedBox(height: 32),
              _buildSectionTitle("COURSE TESTS"),
              SizedBox(height: 16),
              _buildCourseTestCard(context),

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
            SizedBox(height: 4),
            const Text("Welcome back, Prof.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.surfaceLight,
          child: const Icon(Icons.person_3_outlined, color: AppTheme.textDark),
        )
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: AppTheme.textMuted50, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1));
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Total Students", "124", Icons.groups_outlined)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard("Attendance", "98%", Icons.how_to_reg_outlined)),
        SizedBox(width: 12),
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
          SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppTheme.textMuted50, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildClassroomList(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: context.read<ErpRepository>().getClassrooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        final rooms = snapshot.data ?? [];
        if (rooms.isEmpty) return const Text("No classrooms assigned.", style: TextStyle(color: AppTheme.textMuted50));

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
                      Text("Section ${room['section']}", style: const TextStyle(color: AppTheme.textMuted50, fontSize: 12)),
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

  Widget _buildCourseTestCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/erp/tests'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.limeLight.withOpacity(0.15),
              AppTheme.blueVibrant.withOpacity(0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.limeLight.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.limeLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_outlined,
                  color: AppTheme.limeLight, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage Course Tests',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Create tests, enter scores & view rankings',
                      style: TextStyle(
                          color: AppTheme.textMuted50, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppTheme.limeLight, size: 16),
          ],
        ),
      ),
    );
  }
}
