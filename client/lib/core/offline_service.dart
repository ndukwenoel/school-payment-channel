import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/erp/data/erp_repository.dart';

class OfflineAction {
  final String type; // e.g., 'attendance', 'upload'
  final Map<String, dynamic> data;
  final DateTime timestamp;

  OfflineAction({required this.type, required this.data, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
    type: json['type'],
    data: json['data'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class OfflineService {
  static const String _queueKey = 'offline_action_queue';
  final SharedPreferences prefs;

  OfflineService(this.prefs);

  Future<void> queueAction(String type, Map<String, dynamic> data) async {
    final List<String> currentQueue = prefs.getStringList(_queueKey) ?? [];
    final action = OfflineAction(type: type, data: data, timestamp: DateTime.now());
    currentQueue.add(jsonEncode(action.toJson()));
    await prefs.setStringList(_queueKey, currentQueue);
  }

  Future<List<OfflineAction>> getQueue() async {
    final List<String> currentQueue = prefs.getStringList(_queueKey) ?? [];
    return currentQueue.map((e) => OfflineAction.fromJson(jsonDecode(e))).toList();
  }

  Future<void> clearQueue() async {
    await prefs.remove(_queueKey);
  }

  Future<int> getQueueSize() async {
    final List<String> currentQueue = prefs.getStringList(_queueKey) ?? [];
    return currentQueue.length;
  }

  Future<void> syncPendingActions(ErpRepository repository) async {
    final queue = await getQueue();
    if (queue.isEmpty) return;

    final List<OfflineAction> failedActions = [];

    for (final action in queue) {
      bool success = false;
      try {
        if (action.type == 'attendance') {
           await repository.markAttendance(action.data);
           success = true;
        } else if (action.type == 'upload') {
           await repository.uploadResource(action.data);
           success = true;
        }
      } catch (e) {
        print("Failed to sync action ${action.type}: $e");
        success = false;
      }
      
      if (!success) {
        failedActions.add(action);
      }
    }
    
    // Update queue to only contain failed actions
    if (failedActions.isEmpty) {
      await clearQueue();
    } else {
      final List<String> encoded = failedActions.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_queueKey, encoded); 
      // If some failed, throw exception so UI knows sync wasn't perfect
      throw Exception("${failedActions.length} actions failed to sync.");
    }
  }
}
