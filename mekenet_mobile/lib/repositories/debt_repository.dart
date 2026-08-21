import '../models/debt.dart';

abstract class DebtRepository {
  Future<void> save(Debt debt);

  Future<List<Debt>> getAll();

  Future<Debt?> getById(String id);

  Future<void> update(Debt debt);

  Future<void> delete(String id);

  Future<List<Debt>> getOpen();

  Future<List<Debt>> getPaid();

  Future<List<Debt>> getOpenByType(String type);
}