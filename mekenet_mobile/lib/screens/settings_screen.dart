import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF0A8E48),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.08),
                    spreadRadius: 1,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield,
                        color: const Color(0xFF0A8E48),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Your data stays on your device',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your financial records are 100% private. '
                    'All SMS processing happens securely on your phone '
                    'without sending details to any server.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Access allowed! (Mock)'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A8E48),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Allow Access'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Not now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.lock_outline, color: Color(0xFF0A8E48)),
                    title: Text('Privacy'),
                    subtitle: Text('Your data stays on your device'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.cloud_off, color: Color(0xFF0A8E48)),
                    title: Text('Offline Mode'),
                    subtitle: Text('Works without internet'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.upload_file, color: Color(0xFF0A8E48)),
                    title: const Text('Export Data'),
                    subtitle: const Text('Send report to bank'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.info_outline, color: Color(0xFF0A8E48)),
                    title: Text('Version'),
                    subtitle: Text('Mekenet v0.1.0'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}