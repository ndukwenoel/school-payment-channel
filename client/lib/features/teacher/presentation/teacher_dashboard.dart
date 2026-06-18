import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/offline_service.dart';
import '../../erp/data/erp_repository.dart';
import '../../auth/presentation/auth_bloc.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _queueSize = 0;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _refreshQueue();
  }

  void _refreshQueue() async {
    final size = await context.read<OfflineService>().getQueueSize();
    if (mounted) setState(() => _queueSize = size);
  }

  void _syncNow() async {
    setState(() => _syncing = true);
    try {
      await context.read<OfflineService>().syncPendingActions(context.read<ErpRepository>());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sync complete!")));
        _refreshQueue();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sync failed: $e")));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(
        title: const Text("TEACHER OFFLINE APP"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshQueue)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSyncCard(),
            const SizedBox(height: 32),
            _buildActionGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _queueSize > 0 ? Colors.orangeAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _queueSize > 0 ? Colors.orangeAccent : Colors.greenAccent),
      ),
      child: Row(
        children: [
          Icon(
            _queueSize > 0 ? Icons.cloud_off : Icons.cloud_done,
            size: 32,
            color: _queueSize > 0 ? Colors.orangeAccent : Colors.greenAccent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _queueSize > 0 ? "$_queueSize ACTIONS PENDING" : "ALL SYNCED",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _queueSize > 0 ? Colors.orangeAccent : Colors.greenAccent,
                  ),
                ),
                Text(
                  _queueSize > 0 ? "Connect to internet to sync." : "You are up to date.",
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_queueSize > 0)
            ElevatedButton(
              onPressed: _syncing ? null : _syncNow,
              child: _syncing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("SYNC"),
            )
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildCard("Classrooms", Icons.class_outlined, () => context.push('/academic')),
        _buildCard("Upload Resource", Icons.upload_file, () => context.push('/upload')),
        _buildCard("Attendance", Icons.how_to_reg, () => context.push('/academic')), // Leads to same place for now
        _buildCard("Logout", Icons.logout, () => context.read<AuthBloc>().add(AuthLogout())),
      ],
    );
  }

  Widget _buildCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.blueVibrant),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
