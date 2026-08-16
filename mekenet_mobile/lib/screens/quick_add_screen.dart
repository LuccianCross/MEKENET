import 'package:flutter/material.dart';

class QuickAddScreen extends StatelessWidget {
  const QuickAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Add'),
        backgroundColor: const Color(0xFF0A8E48),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Quick Add Screen\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}