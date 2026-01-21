import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/notification_repository.dart';
import '../data/notification_models.dart';

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notification History")),
      body: FutureBuilder<List<NotificationLog>>(
        future: context.read<NotificationRepository>().getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) return const Center(child: Text("No notifications sent."));

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                leading: const Icon(Icons.email),
                title: Text(log.subject),
                subtitle: Text("To: ${log.recipientEmail}\n${log.sentAt.toString()}"),
                isThreeLine: true,
                trailing: Text(log.status),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.send),
        onPressed: () {
          // Trigger a test notification
          context.read<NotificationRepository>().sendNotification("test@parent.com", "Test Alert", "This is a test notification.");
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Test Notification Sent")));
        },
      ),
    );
  }
}
