import 'package:flutter/material.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

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
      body: Column(
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
                const Text(
                  'Br800',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A8E48),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) {
                final debtors = [
                  {'name': 'Abebe', 'amount': 300, 'due': '2 days', 'paid': false},
                  {'name': 'Sara', 'amount': 200, 'due': '5 days', 'paid': true},
                  {'name': 'Dawit', 'amount': 300, 'due': '3 days', 'paid': false},
                ];
                final d = debtors[index];
                return _buildDebtorTile(
                  d['name'] as String,
                  d['amount'] as int,
                  d['due'] as String,
                  d['paid'] as bool,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtorTile(String name, int amount, String due, bool isPaid) {
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isPaid ? 'Paid' : 'Due in $due',
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
                'Br$amount',
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