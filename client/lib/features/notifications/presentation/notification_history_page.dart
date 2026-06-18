import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/notification_repository.dart';
import '../data/notification_models.dart';
import '../../../core/theme.dart';

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.voidBlack,
      appBar: AppBar(title: const Text("NOTIFICATIONS")),
      body: FutureBuilder<List<NotificationLog>>(
        future: context.read<NotificationRepository>().getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(
              child: Text("No records available.", style: TextStyle(color: AppTheme.textMuted.withOpacity(0.5))),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.bluePale.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.mail_outline, color: AppTheme.bluePale, size: 20),
                  ),
                  title: Text(log.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    "To: ${log.recipientEmail}\n${log.sentAt.day}/${log.sentAt.month} ${log.sentAt.hour}:${log.sentAt.minute}",
                    style: const TextStyle(color: AppTheme.textMuted.withOpacity(0.5), fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: log.status == 'sent' ? AppTheme.limeLight.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.status.toUpperCase(),
                      style: TextStyle(
                        color: log.status == 'sent' ? AppTheme.limeLight : Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.blueVibrant,
        child: const Icon(Icons.send_rounded, color: AppTheme.textDark),
        onPressed: () {
          context.read<NotificationRepository>().sendNotification("test@parent.com", "Channel Update", "Your payment portal has been updated to the latest standard.");
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Test Alert Dispatched")));
        },
      ),
    );
  }
}
