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
  double _weeklyExpenses = 0;
  double _totalOwed = 0;
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

    double expenses = 0;
    double debts = 0;
    for (var t in transactions) {
      if (t.type == 'expense') expenses += t.amount;
      if (t.type == 'debt') debts += t.amount;
    }

    setState(() {
      _transactions = transactions;
      _weeklyIncome = income;
      _weeklyExpenses = expenses;
      _totalOwed = debts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildSummaryCard(
                          'INCOME',
                          'Br${_weeklyIncome.toStringAsFixed(0)}',
                          const Color(0xFF0A8E48),
                          Icons.arrow_upward,
                        ),
                        const SizedBox(width: 10),
                        _buildSummaryCard(
                          'EXPENSES',
                          'Br${_weeklyExpenses.toStringAsFixed(0)}',
                          const Color(0xFFE53935),
                          Icons.arrow_downward,
                        ),
                        const SizedBox(width: 10),
                        _buildSummaryCard(
                          'OWED TO YOU',
                          'Br${_totalOwed.toStringAsFixed(0)}',
                          const Color(0xFFFF8F00),
                          Icons.people,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You made Br${_weeklyIncome.toStringAsFixed(0)} this week',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A8E48),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Great job! Your sales are up 12% compared to last week.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length > 5 ? 5 : _transactions.length,
                      itemBuilder: (context, index) {
                        final t = _transactions[index];
                        return _buildTransactionTile(t);
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction t) {
    final isIncome = t.type == 'income';
    final isDebt = t.type == 'debt';
    Color color;
    IconData icon;
    String label;

    if (isIncome) {
      color = const Color(0xFF0A8E48);
      icon = Icons.arrow_upward;
      label = 'Sale';
    } else if (isDebt) {
      color = const Color(0xFFFF8F00);
      icon = Icons.people;
      label = 'Debt';
    } else {
      color = const Color(0xFFE53935);
      icon = Icons.arrow_downward;
      label = 'Expense';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            backgroundColor: color.withValues(alpha: 0.1),
            radius: 18,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.sender ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDate(t.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}Br${t.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
    } else if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
      return 'Yesterday';
    } else {
      return '${date.day} ${_getMonth(date.month)} ${date.year}';
    }
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}