import '../models/debt.dart';

abstract class DebtRepository {
  Future<void> save(Debt debt);

  Future<List<Debt>> getAll();

  Future<Debt?> getById(String id);

  Future<void> update(Debt debt);

  Future<void> delete(String id);
}