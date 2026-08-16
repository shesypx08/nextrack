import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _chatAlerts = true;
  bool _deadlineReminders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B1B1D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E0854)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MASTER CONTROLS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5C5468), letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            _buildToggleCard(
              title: 'Push Notifications',
              subtitle: 'Receive alerts on your device',
              value: _pushEnabled,
              onChanged: (val) => setState(() => _pushEnabled = val),
            ),
            _buildToggleCard(
              title: 'Email Notifications',
              subtitle: 'Weekly activity reports',
              value: _emailEnabled,
              onChanged: (val) => setState(() => _emailEnabled = val),
            ),
            const SizedBox(height: 32),
            const Text(
              'SPECIFIC ALERTS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5C5468), letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE4E2E4)),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Team Chat',
                    subtitle: 'New message alerts',
                    value: _chatAlerts,
                    onChanged: (val) => setState(() => _chatAlerts = val),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildSwitchTile(
                    title: 'Deadlines',
                    subtitle: 'Upcoming project dates',
                    value: _deadlineReminders,
                    onChanged: (val) => setState(() => _deadlineReminders = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Note: Master controls override specific alerts. If Push Notifications are off, you won\'t receive any mobile alerts.',
              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E2E4)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF4B0AAA),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF4B0AAA),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    );
  }
}
