import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transaction_repository.dart';

// Provides a singleton instance of the TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// A FutureProvider that initializes the DB and returns the ready repository
final databaseInitProvider = FutureProvider<TransactionRepository>((ref) async {
  final repo = ref.read(transactionRepositoryProvider);
  await repo.init();
  return repo;
});
