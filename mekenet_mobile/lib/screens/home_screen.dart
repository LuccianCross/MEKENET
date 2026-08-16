import 'package:flutter/material.dart';
import '../repositories/transaction_repository.dart';
import '../models/transaction.dart';

class HomeScreen extends StatefulWidget {
  final TransactionRepository repository;

  const HomeScreen({super.key, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  double _weeklyIncome = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    final transactions = await widget.repository.getTransactions();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final income = await widget.repository.getTotalIncome(weekAgo, now);
    
    setState(() {
      _transactions = transactions;
      _weeklyIncome = income;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Money Record'),
        backgroundColor: const Color(0xFF0A8E48),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Income Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'This Week\'s Income',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_weeklyIncome.toStringAsFixed(0)} Br',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A8E48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _transactions.length > 5 ? 5 : _transactions.length,
                        itemBuilder: (context, index) {
                          final t = _transactions[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: t.type == 'income' 
                                  ? Colors.green.shade100 
                                  : Colors.red.shade100,
                              child: Icon(
                                t.type == 'income' 
                                    ? Icons.arrow_downward 
                                    : Icons.arrow_upward,
                                color: t.type == 'income' 
                                    ? Colors.green 
                                    : Colors.red,
                                size: 20,
                              ),
                            ),
                            title: Text(t.sender ?? 'Unknown'),
                            subtitle: Text(
                              '${t.timestamp.day}/${t.timestamp.month}',
                            ),
                            trailing: Text(
                              '${t.type == 'income' ? '+' : '-'}${t.amount.toStringAsFixed(0)} Br',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: t.type == 'income' ? Colors.green : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}