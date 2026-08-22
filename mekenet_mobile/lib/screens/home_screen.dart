import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/transaction.dart';
import '../repositories/repository_provider.dart';
import '../services/sms/sms_listener.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _totalIncome = 0;
  double _totalExpenses = 0;
  double _totalOwed = 0;
  List<Transaction> _recentTransactions = [];
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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final income = await RepositoryProvider.transaction
          .getTotalIncome(startOfDay, now);
      final expenses = await RepositoryProvider.transaction
          .getTotalExpenses(startOfDay, now);
      final debts = await RepositoryProvider.debt.getOpen();
      final owed = debts.fold<double>(0, (sum, d) => sum + d.amount);
      final recent = await RepositoryProvider.transaction.getThisWeek();

      if (mounted) {
        setState(() {
          _totalIncome = income;
          _totalExpenses = expenses;
          _totalOwed = owed;
          _recentTransactions = recent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(L10n.instance.t('home_title')),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 50, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(
                              L10n.instance.t('could_not_load_data'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: Text(L10n.instance.t('btn_retry')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfitCard(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSummaryCard(
                          L10n.instance.t('summary_income'),
                          L10n.instance.formatCurrency(_totalIncome),
                          const Color(0xFF0A8E48),
                          Icons.arrow_upward,
                        ),
                        const SizedBox(width: 10),
                        _buildSummaryCard(
                          L10n.instance.t('summary_expenses'),
                          L10n.instance.formatCurrency(_totalExpenses),
                          const Color(0xFFE53935),
                          Icons.arrow_downward,
                        ),
                        const SizedBox(width: 10),
                        _buildSummaryCard(
                          L10n.instance.t('summary_owed'),
                          L10n.instance.formatCurrency(_totalOwed),
                          const Color(0xFFFF8F00),
                          Icons.people,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          L10n.instance.t('recent_transactions'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_recentTransactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                L10n.instance.t('no_transactions_yet'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                L10n.instance.t('sms_appear_automatically'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._recentTransactions.take(10).map((tx) {
                        final isIncome = tx.direction == 'income';
                        final dateLabel = L10n.instance.formatDateLabel(tx.timestamp);

                        return _buildTransactionTile(
                          L10n.instance.translateSource(tx.source),
                          dateLabel,
                          tx.amount,
                          isIncome,
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }Widget _buildProfitCard() {
    final profit = _totalIncome - _totalExpenses;
    final isProfit = profit >= 0;
    final profitColor = isProfit ? const Color(0xFF0A8E48) : const Color(0xFFE53935);
    final profitIcon = isProfit ? Icons.trending_up : Icons.trending_down;
    final profitLabel = isProfit
        ? L10n.instance.t('todays_profit')
        : L10n.instance.t('todays_loss');

    final total = _totalIncome + _totalExpenses;
    final incomePercent = total > 0 ? _totalIncome / total : 0.0;
    final expensePercent = total > 0 ? _totalExpenses / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [const Color(0xFF0A8E48), const Color(0xFF1B6B3A)]
              : [const Color(0xFFE53935), const Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: profitColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(profitIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                profitLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            L10n.instance.formatCurrency(profit.abs()),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (incomePercent * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (expensePercent > 0)
                  Expanded(
                    flex: (expensePercent * 100).toInt(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildProfitDetail(
                L10n.instance.t('label_income'),
                _totalIncome,
                Icons.arrow_upward,
              ),
              const SizedBox(width: 24),
              _buildProfitDetail(
                L10n.instance.t('label_expenses'),
                _totalExpenses,
                Icons.arrow_downward,
              ),
            ],
          ),
        ],
      ),
    );
  }Widget _buildProfitDetail(String label, double amount, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          '$label: ${L10n.instance.formatCurrency(amount)}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
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

  Widget _buildTransactionTile(
    String title,
    String date,
    double amount,
    bool isIncome,
  ) {
    final color =
        isIncome ? const Color(0xFF0A8E48) : const Color(0xFFE53935);
    final icon =
        isIncome ? Icons.arrow_upward : Icons.arrow_downward;
    final label = isIncome
        ? L10n.instance.t('label_income')
        : L10n.instance.t('label_expense');return Container(
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  date,
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
                '${isIncome ? '+' : '-'}${L10n.instance.formatCurrency(amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
}