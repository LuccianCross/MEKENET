import 'package:flutter/material.dart';
import '../repositories/transaction_repository.dart';
import '../models/transaction.dart';

class DebtsScreen extends StatefulWidget {
  final TransactionRepository? repository;

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

  double get _totalOwed {
    return _debts.fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Who Owes Me'),
        backgroundColor: const Color(0xFF0A8E48),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.08),
                        spreadRadius: 1,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Outstanding Owed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Br${_totalOwed.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A8E48),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _debts.isEmpty
                      ? const Center(
                          child: Text(
                            'No debts recorded',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _debts.length,
                          itemBuilder: (context, index) {
                            final d = _debts[index];
                            final isPaid = index % 2 == 0;
                            return _buildDebtorTile(d, isPaid, index);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDebtorTile(Transaction d, bool isPaid, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPaid
            ? Border.all(color: const Color(0xFF0A8E48), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isPaid
                ? const Color(0xFF0A8E48).withValues(alpha: 0.1)
                : const Color(0xFFFF8F00).withValues(alpha: 0.1),
            child: Icon(
              isPaid ? Icons.check : Icons.person,
              color: isPaid ? const Color(0xFF0A8E48) : const Color(0xFFFF8F00),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.sender ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isPaid ? 'Paid' : 'Due in ${index + 2} days',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPaid ? const Color(0xFF0A8E48) : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Br${d.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isPaid ? const Color(0xFF0A8E48) : const Color(0xFFFF8F00),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFF0A8E48).withValues(alpha: 0.1)
                      : const Color(0xFFE53935).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPaid ? 'Paid' : 'Unpaid',
                  style: TextStyle(
                    fontSize: 10,
                    color: isPaid ? const Color(0xFF0A8E48) : const Color(0xFFE53935),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}