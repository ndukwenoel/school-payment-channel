import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../dashboard/data/dashboard_repository.dart';

class ChildAcademicView extends StatelessWidget {
  final dynamic student;

  const ChildAcademicView({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: Text("${student.fullName}'s Academics"),
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryBlue,
            tabs: [
              Tab(text: "Attendance"),
              Tab(text: "Test Results"),
              Tab(text: "Grade Records"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AttendanceTab(),
            _TestResultsTab(),
            _GradeRecordsTab(),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context) {
    // Mock historical attendance
    final mockAttendance = [
      {"date": "2026-07-15", "status": "present", "remarks": ""},
      {"date": "2026-07-14", "status": "late", "remarks": "Traffic"},
      {"date": "2026-07-13", "status": "absent", "remarks": "Sick"},
      {"date": "2026-07-12", "status": "present", "remarks": ""},
      {"date": "2026-07-11", "status": "present", "remarks": ""},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockAttendance.length,
      itemBuilder: (context, index) {
        final record = mockAttendance[index];
        final status = record['status'] as String;
        Color statusColor;
        switch (status) {
          case 'present': statusColor = Colors.green; break;
          case 'late': statusColor = Colors.orange; break;
          case 'absent': statusColor = Colors.red; break;
          default: statusColor = Colors.grey;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.event_note, color: statusColor),
            title: Text(record['date'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(record['remarks'] != "" ? record['remarks'] as String : "No remarks"),
            trailing: Chip(
              label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
              backgroundColor: statusColor,
            ),
          ),
        );
      },
    );
  }
}

class _TestResultsTab extends StatelessWidget {
  const _TestResultsTab();

  @override
  Widget build(BuildContext context) {
    final mockResults = [
      {"subject": "Mathematics", "test": "Mid-Term CA", "score": 85, "max": 100},
      {"subject": "English", "test": "Mid-Term CA", "score": 72, "max": 100},
      {"subject": "Science", "test": "Mid-Term CA", "score": 90, "max": 100},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockResults.length,
      itemBuilder: (context, index) {
        final res = mockResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(res['subject'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(res['test'] as String),
            trailing: Text("${res['score']}/${res['max']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          ),
        );
      },
    );
  }
}

class _GradeRecordsTab extends StatelessWidget {
  const _GradeRecordsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No final grade records published yet for this term.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
