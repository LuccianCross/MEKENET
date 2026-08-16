import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF0A8E48),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.lock, color: Color(0xFF0A8E48)),
            title: Text('Privacy'),
            subtitle: Text('Your data stays on your device'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.cloud_off, color: Color(0xFF0A8E48)),
            title: Text('Offline Mode'),
            subtitle: Text('Works without internet'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_file, color: Color(0xFF0A8E48)),
            title: const Text('Export Data'),
            subtitle: const Text('Send report to bank'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export coming soon')),
              );
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info, color: Color(0xFF0A8E48)),
            title: Text('Version'),
            subtitle: Text('Mekenet v0.1.0'),
          ),
        ],
      ),
    );
  }
}