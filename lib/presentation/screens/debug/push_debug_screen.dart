import 'package:flutter/material.dart';
import '../../../domain/services/notification_service.dart';

class PushDebugScreen extends StatefulWidget {
  const PushDebugScreen({super.key});

  @override
  State<PushDebugScreen> createState() => _PushDebugScreenState();
}

class _PushDebugScreenState extends State<PushDebugScreen> {
  bool _loading = false;
  bool? _areEnabled;
  int? _nextRandomizedMs;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final enabled = await NotificationService().areNotificationsEnabled();
      final next = await NotificationService().getNextRandomizedReminder();
      setState(() {
        _areEnabled = enabled;
        _nextRandomizedMs = next;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendTest() async {
    setState(() => _loading = true);
    try {
      await NotificationService().sendTestNotification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send test: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      if (mounted) await _refresh();
    }
  }

  Future<void> _scheduleRandomized() async {
    setState(() => _loading = true);
    try {
      await NotificationService().scheduleRandomizedReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Randomized reminders scheduled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      if (mounted) await _refresh();
    }
  }

  Future<void> _cancelRandomized() async {
    setState(() => _loading = true);
    try {
      await NotificationService().cancelRandomizedReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Randomized reminders cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      if (mounted) await _refresh();
    }
  }

  String _formatNext(int? ms) {
    if (ms == null) return '<not scheduled>';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ms.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ElevatedButton(onPressed: _sendTest, child: const Text('Send Test Notification')),
                      const SizedBox(width: 12),
                      ElevatedButton(onPressed: _refresh, child: const Text('Refresh')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Permissions: ${_areEnabled == null ? "unknown" : (_areEnabled! ? "Enabled" : "Disabled")}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text('Next randomized reminder: ${_formatNext(_nextRandomizedMs)}', style: const TextStyle(fontFamily: 'monospace')),
                  const SizedBox(height: 20),
                  Row(children: [
                    ElevatedButton(onPressed: _scheduleRandomized, child: const Text('Schedule Randomized')),
                    const SizedBox(width: 12),
                    OutlinedButton(onPressed: _cancelRandomized, child: const Text('Cancel Randomized')),
                  ]),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Randomized reminders are scheduled locally on-device. If you want server push status, use the Push Targets tool on your backend.'),
                ],
              ),
            ),
    );
  }
}
