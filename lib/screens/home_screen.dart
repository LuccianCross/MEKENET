// This is the HOME screen - shows weekly income and recent transactions

import 'package:flutter/material.dart';
import '../repositories/transaction_repository.dart';
import '../models/transaction.dart';

// 'StatefulWidget' because this screen loads data (it has state that changes)
class HomeScreen extends StatefulWidget {
  final TransactionRepository repository; // Needs a repository to get data

  const HomeScreen({super.key, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // These variables store the data shown on screen
  List<Transaction> _transactions = [];  // List of all transactions
  double _weeklyIncome = 0;              // Total income this week
  bool _loading = true;                  // Are we loading data?

  // This runs when the screen is first created
  @override
  void initState() {
    super.initState();
    _loadData();  // Load the data
  }

  // This function loads data from the repository
  Future<void> _loadData() async {
    setState(() => _loading = true);  // Show loading spinner
    
    // Get all transactions
    final transactions = await widget.repository.getTransactions();
    
    // Calculate weekly income (last 7 days)
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final income = await widget.repository.getTotalIncome(weekAgo, now);
    
    // Update the UI with new data
    setState(() {
      _transactions = transactions;
      _weeklyIncome = income;
      _loading = false;  // Hide loading spinner
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar at the top
      appBar: AppBar(
        title: const Text('መቀነት'),  // App name in Amharic
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      
      // Main body of the screen
      body: RefreshIndicator(
        // Pull down to refresh
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator()) // Loading spinner
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Income Card - shows weekly income
                    Card(
                      elevation: 4, // Shadow effect
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
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Recent Transactions section
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    // List of transactions (shows only first 5)
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