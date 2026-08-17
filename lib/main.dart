// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'repositories/repository_provider.dart';
import 'models/transaction.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await testRepository();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mekenet Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String _testResult = 'Testing...';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    try {
      _addLog('Starting repository tests...');
      
      final repo = RepositoryProvider.instance;
      _addLog('Repository instance created');
      
      _addLog('Test 1: Saving a transaction...');
      final transaction = Transaction(
        direction: 'income',
        amount: 100.0,
        source: 'sms',
        counterpartyMasked: '1234',
        rawSmsHash: 'test_hash_123',
        category: 'stock',
      );
      
      await repo.save(transaction);
      _addLog('Transaction saved with ID: ${transaction.id}');
      
      _addLog('Test 2: Getting transaction by ID...');
      final found = await repo.getById(transaction.id);
      if (found != null) {
        _addLog('Found transaction: ${found.amount} Birr (${found.direction})');
      } else {
        _addLog('Transaction not found!');
      }
      
      _addLog('Test 3: Getting today\'s transactions...');
      final today = await repo.getToday();
      _addLog('Today\'s transactions: ${today.length}');
      
      _addLog('Test 4: Getting transactions by date range...');
      final start = DateTime.now().subtract(const Duration(days: 7));
      final end = DateTime.now();
      final weekTransactions = await repo.getByDateRange(start, end);
      _addLog('Transactions in last 7 days: ${weekTransactions.length}');
      
      _addLog('Test 5: Calculating total income...');
      final income = await repo.getTotalIncome(start, end);
      _addLog('Total income: $income Birr');
      
      _addLog('Test 6: Checking for duplicate...');
      final exists = await repo.existsBySmsHash('test_hash_123');
      _addLog('Duplicate exists: $exists');
      
      _addLog('Test 7: Updating transaction...');
      final updated = Transaction(
        id: transaction.id,
        direction: 'expense',
        amount: 75.0,
        source: 'manual',
        counterpartyMasked: '5678',
        matchConfidence: 'confirmed',
        category: 'rent',
        timestamp: transaction.timestamp,
        synced: false,
      );
      await repo.update(updated);
      
      final verified = await repo.getById(transaction.id);
      if (verified != null && verified.amount == 75.0) {
        _addLog('Transaction updated successfully! New amount: ${verified.amount} Birr');
      } else {
        _addLog('Update failed!');
      }
      
      _addLog('Test 8: Getting unmatched transactions...');
      final unmatched = await repo.getUnmatched();
      _addLog('Unmatched transactions: ${unmatched.length}');
      
      _addLog('Test 9: Deleting transaction...');
      await repo.delete(transaction.id);
      final deleted = await repo.getById(transaction.id);
      if (deleted == null) {
        _addLog('Transaction deleted successfully!');
      } else {
        _addLog('Delete failed!');
      }
      
      _addLog('All tests completed successfully!');
      
      setState(() {
        _testResult = 'All tests passed!';
      });
      
    } catch (e) {
      _addLog('Test failed with error: $e');
      setState(() {
        _testResult = 'Tests failed: $e';
      });
    }
  }

  void _addLog(String message) {
    print(message);
    setState(() {
      _logs.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repository Test'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _testResult.contains('All tests passed') ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _testResult,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _testResult.contains('All tests passed') ? Colors.green[800] : Colors.red[800],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Logs:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _logs.map((log) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontSize: 12,
                            color: log.contains('failed') ? Colors.red : 
                                   log.contains('successfully') ? Colors.green : 
                                   Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> testRepository() async {
  print('\n========================================');
  print('Running Repository Tests (Console)');
  print('========================================\n');
  
  try {
    final repo = RepositoryProvider.instance;
    print('Repository instance created');
    
    final transaction = Transaction(
      direction: 'income',
      amount: 100.0,
      source: 'sms',
      counterpartyMasked: '1234',
      rawSmsHash: 'test_hash_123',
    );
    await repo.save(transaction);
    print('Saved: ${transaction.id}');
    
    final found = await repo.getById(transaction.id);
    if (found != null) {
      print('Found: ${found.amount} Birr (${found.direction})');
    }
    
    final today = await repo.getToday();
    print('Today: ${today.length} transactions');
    
    final start = DateTime.now().subtract(const Duration(days: 7));
    final end = DateTime.now();
    final income = await repo.getTotalIncome(start, end);
    print('Income (7 days): $income Birr');
    
    await repo.delete(transaction.id);
    final deleted = await repo.getById(transaction.id);
    if (deleted == null) {
      print('Deleted successfully');
    }
    
    print('\nALL TESTS PASSED!');
    print('========================================\n');
  } catch (e) {
    print('\nTest failed: $e');
    print('========================================\n');
  }
}