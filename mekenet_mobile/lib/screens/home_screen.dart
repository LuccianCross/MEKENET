import 'dart:async';

import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/debt_repository.dart';
import '../repositories/repository_provider.dart';
import '../services/sms/sms_listener.dart';

class HomeScreen extends StatefulWidget {
  final TransactionRepository transactionRepository;
  final DebtRepository debtRepository;

  const HomeScreen({
    super.key,
    required this.transactionRepository,
    required this.debtRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];

  double _income = 0;
  double _expenses = 0;
  double _owed = 0;

  bool _isLoading = true;
  String? _error;
  StreamSubscription<void>? _smsSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _smsSub = SmsListener.instance.onTransactionAdded.listen((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _smsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final now = DateTime.now();

      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final endOfDay = startOfDay.add(
        const Duration(days: 1),
      );

      final transactions =
          await widget.transactionRepository.getToday();

      final income =
          await widget.transactionRepository.getTotalIncome(
        startOfDay,
        endOfDay,
      );

      final expenses =
          await widget.transactionRepository.getTotalExpenses(
        startOfDay,
        endOfDay,
      );

      final openDebts =
          await widget.debtRepository.getOpen();

      final owed = openDebts.fold<double>(
        0,
        (total, debt) => total + debt.amount,
      );

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _income = income;
        _expenses = expenses;
        _owed = owed;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final transactionDay = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference = today.difference(transactionDay).inDays;

    if (difference == 0) {
      final hour = date.hour > 12
          ? date.hour - 12
          : date.hour == 0
              ? 12
              : date.hour;

      final minute = date.minute.toString().padLeft(2, '0');

      final period = date.hour >= 12 ? 'PM' : 'AM';

      return 'Today, $hour:$minute $period';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    if (difference > 1) {
      return '$difference days ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Money Record',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: const Color(0xFF0A8E48),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0A8E48),
                ),
              )
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 50,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Could not load transactions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          _buildSummaryCard(
                            'INCOME',
                            'Br${_formatAmount(_income)}',
                            const Color(0xFF0A8E48),
                            Icons.arrow_upward,
                          ),
                          const SizedBox(width: 10),
                          _buildSummaryCard(
                            'EXPENSES',
                            'Br${_formatAmount(_expenses)}',
                            const Color(0xFFE53935),
                            Icons.arrow_downward,
                          ),
                          const SizedBox(width: 10),
                          _buildSummaryCard(
                            'OWED TO YOU',
                            'Br${_formatAmount(_owed)}',
                            const Color(0xFFFF8F00),
                            Icons.people,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildWeeklyCard(),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: _loadData,
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  const Color(0xFF0A8E48),
                            ),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (_transactions.isEmpty)
                        _buildEmptyState()
                      else
                        ..._transactions
                            .map(_buildTransactionTile)
                            .toList(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildWeeklyCard() {
    return FutureBuilder<List<Transaction>>(
      future: widget.transactionRepository.getThisWeek(),
      builder: (context, snapshot) {
        final weeklyIncome = snapshot.hasData
            ? snapshot.data!
                .where((t) => t.direction == 'income')
                .fold<double>(
                  0,
                  (total, t) => total + t.amount,
                )
            : 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0A8E48),
                Color(0xFF1B6B3A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You made Br${weeklyIncome.toStringAsFixed(0)} this week',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your real transaction data from SQLite.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 50,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Add an expense to see it here.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.06),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final isIncome = transaction.direction == 'income';

    final color = isIncome
        ? const Color(0xFF0A8E48)
        : const Color(0xFFE53935);

    final icon =
        isIncome ? Icons.arrow_upward : Icons.arrow_downward;

    final label = isIncome ? 'Income' : 'Expense';

    final title = transaction.counterpartyMasked.isNotEmpty
        ? transaction.counterpartyMasked
        : transaction.category ?? transaction.source;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.04),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            radius: 22,
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (transaction.category != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.category!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}Br${transaction.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
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
}