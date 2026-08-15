// This file creates FAKE transaction data for testing
// The UI uses this to show data without waiting for a real database

import '../models/transaction.dart';
import 'transaction_repository.dart';

// 'implements' means this class promises to have ALL the functions
// that TransactionRepository defined
class MockTransactionRepository implements TransactionRepository {
  
  // This is our "fake database" - a list of fake transactions
  final List<Transaction> _transactions = [
    // Each item is a fake transaction using our .mock() helper
    
    // Fake Income 1: Tigist paid 500 Br
    Transaction.mock(
      amount: 500,
      sender: 'Tigist',
      type: 'income',
    ),
    
    // Fake Income 2: Abebe paid 1200 Br
    Transaction.mock(
      amount: 1200,
      sender: 'Abebe',
      type: 'income',
    ),
    
    // Fake Income 3: Meron paid 300 Br
    Transaction.mock(
      amount: 300,
      sender: 'Meron',
      type: 'income',
    ),
    
    // Fake Expense: Spent 150 Br on inventory
    Transaction.mock(
      amount: 150,
      type: 'expense',
      note: 'Bought inventory',
    ),
    
    // Fake Debt: Kebede owes 1000 Br
    Transaction.mock(
      amount: 1000,
      sender: 'Kebede',
      type: 'debt',
      note: 'Owes me for goods',
    ),
  ];

  // 1. Get all transactions
  // @override means we're using the function from the interface
  @override
  Future<List<Transaction>> getTransactions() async {
    // 'await Future.delayed' simulates a slow database
    // This makes the app show a loading spinner (good for testing!)
    await Future.delayed(const Duration(milliseconds: 300));
    return _transactions; // Return our fake list
  }

  // 2. Add a new transaction
  @override
  Future<void> addTransaction(Transaction transaction) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _transactions.add(transaction); // Add to our fake list
  }

  // 3. Calculate total income between two dates
  @override
  Future<double> getTotalIncome(DateTime start, DateTime end) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // This finds all income transactions between the dates and adds them up
    // Let me break this down:
    // 1. _transactions.where(...) - look at all transactions
    // 2. Keep only those that are 'income' AND between the dates
    // 3. .fold(0.0, ...) - add up all the amounts
    final income = _transactions
        .where((t) => 
            t.type == 'income' &&       // Only income transactions
            t.timestamp.isAfter(start) && // After the start date
            t.timestamp.isBefore(end))    // Before the end date
        .fold(0.0, (sum, t) => sum + t.amount); // Add all amounts
    
    return income;
  }

  // 4. Get only debt transactions
  @override
  Future<List<Transaction>> getDebts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Return only transactions where type == 'debt'
    return _transactions.where((t) => t.type == 'debt').toList();
  }
}