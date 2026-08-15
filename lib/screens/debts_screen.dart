// This screen shows all the people who owe you money

import 'package:flutter/material.dart';
import '../repositories/transaction_repository.dart';
import '../models/transaction.dart';

class DebtsScreen extends StatefulWidget {
  final TransactionRepository? repository; // ? means optional

  const DebtsScreen({super.key, this.repository});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Transaction> _debts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    // If no repository provided, show empty state
    if (widget.repository == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    
    setState(() => _loading = true);
    final debts = await widget.repository!.getDebts();
    setState(() {
      _debts = debts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Who Owes Me'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _debts.isEmpty
              ? const Center(
                  child: Text(
                    'No debts recorded',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _debts.length,
                  itemBuilder: (context, index) {
                    final d = _debts[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(d.sender ?? 'Unknown'),
                        subtitle: Text(d.note ?? 'No note'),
                        trailing: Text(
                          '${d.amount.toStringAsFixed(0)} Br',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}