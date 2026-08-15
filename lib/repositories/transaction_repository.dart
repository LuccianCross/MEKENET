// This file defines a "contract" - a list of functions
// that ANY repository must have

import '../models/transaction.dart';

// 'abstract' means this is just a blueprint, not a real thing yet
abstract class TransactionRepository {
  // Any repository must have these 4 functions:
  
  // 1. Get all transactions (returns a list)
  Future<List<Transaction>> getTransactions();
  
  // 2. Add a new transaction (doesn't return anything)
  Future<void> addTransaction(Transaction transaction);
  
  // 3. Calculate total income between two dates (returns a number)
  Future<double> getTotalIncome(DateTime start, DateTime end);
  
  // 4. Get only debts (returns a list)
  Future<List<Transaction>> getDebts();
}