import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../repositories/repository_provider.dart';
import '../services/sms/sms_listener.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _todayIncome = 0;
  double _todayExpenses = 0;
  double _weekIncome = 0;
  double _weekExpenses = 0;
  double _monthIncome = 0;
  double _monthExpenses = 0;
  double _totalOwed = 0;
  List<Transaction> _recentTransactions = [];
  List<MapEntry<DateTime, double>> _dailyIncome = [];
  List<MapEntry<DateTime, double>> _dailyExpenses = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<void>? _smsSub;
  int _selectedPeriod = 0; // 0=Today, 1=Week, 2=Month

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
      final startOfWeek = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Fetch all periods in parallel
      final results = await Future.wait([
        RepositoryProvider.transaction.getTotalIncome(startOfDay, now),
        RepositoryProvider.transaction.getTotalExpenses(startOfDay, now),
        RepositoryProvider.transaction.getTotalIncome(startOfWeek, now),
        RepositoryProvider.transaction.getTotalExpenses(startOfWeek, now),
        RepositoryProvider.transaction.getTotalIncome(startOfMonth, now),
        RepositoryProvider.transaction.getTotalExpenses(startOfMonth, now),
        RepositoryProvider.debt.getOpen(),
        RepositoryProvider.transaction.getThisWeek(),
      ]);

      final debts = results[6] as List;
      final owed = debts.fold<double>(0, (sum, d) => sum + (d as dynamic).amount);

      // Load last 7 days for chart
      final now7 = DateTime.now();
      final sevenDaysAgo = DateTime(now7.year, now7.month, now7.day - 6);
      final weekTx = await RepositoryProvider.transaction.getByDateRange(
        sevenDaysAgo,
        now7.add(const Duration(hours: 23, minutes: 59)),
      );

      final dailyIncome = <DateTime, double>{};
      final dailyExpenses = <DateTime, double>{};
      for (int i = 0; i < 7; i++) {
        final day = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day + i);
        dailyIncome[day] = 0;
        dailyExpenses[day] = 0;
      }
      for (final tx in weekTx) {
        final day = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
        if (dailyIncome.containsKey(day)) {
          if (tx.direction == 'income') {
            dailyIncome[day] = dailyIncome[day]! + tx.amount;
          } else {
            dailyExpenses[day] = dailyExpenses[day]! + tx.amount;
          }
        }
      }

      if (mounted) {
        setState(() {
          _todayIncome = results[0] as double;
          _todayExpenses = results[1] as double;
          _weekIncome = results[2] as double;
          _weekExpenses = results[3] as double;
          _monthIncome = results[4] as double;
          _monthExpenses = results[5] as double;
          _totalOwed = owed;
          _recentTransactions = results[7] as List<Transaction>;
          _dailyIncome = dailyIncome.entries.toList();
          _dailyExpenses = dailyExpenses.entries.toList();
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
        title: Text(AppLocalizations.of(context).t('myMoneyRecord')),
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
                            const Text(
                              'Could not load data',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: Text(AppLocalizations.of(context).t('retry')),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfitCard(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSummaryCard(
                          AppLocalizations.of(context).t('income').toUpperCase(),
                          'Br${_selectedIncome.toStringAsFixed(0)}',
                          const Color(0xFF0A8E48),
                          Icons.arrow_upward,
                        ),
                        const SizedBox(width: 10),
                        _buildSummaryCard(
                          AppLocalizations.of(context).t('expenses').toUpperCase(),
                          'Br${_selectedExpenses.toStringAsFixed(0)}',
                          const Color(0xFFE53935),
                          Icons.arrow_downward,
                        ),
                        const SizedBox(width: 10),
                        _buildSummaryCard(
                          AppLocalizations.of(context).t('owed').toUpperCase(),
                          'Br${_totalOwed.toStringAsFixed(0)}',
                          const Color(0xFFFF8F00),
                          Icons.people,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildChart(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          AppLocalizations.of(context).t('recentTransactions'),
                          style: TextStyle(
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
                                AppLocalizations.of(context).t('noTransactionsYet'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context).t('bankSmsWillAppear'),
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
                        final date = tx.timestamp;
                        final now = DateTime.now();
                        String dateLabel;
                        if (date.year == now.year &&
                            date.month == now.month &&
                            date.day == now.day) {
                          dateLabel =
                              'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                        } else if (date.year == now.year &&
                            date.month == now.month &&
                            date.day == now.day - 1) {
                          dateLabel = 'Yesterday';
                        } else {
                          dateLabel =
                              '${date.day}/${date.month}/${date.year}';
                        }

                        return _buildTransactionTile(
                          tx.source.toUpperCase(),
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
  }

  double get _selectedIncome {
    switch (_selectedPeriod) {
      case 0: return _todayIncome;
      case 1: return _weekIncome;
      case 2: return _monthIncome;
      default: return _todayIncome;
    }
  }

  double get _selectedExpenses {
    switch (_selectedPeriod) {
      case 0: return _todayExpenses;
      case 1: return _weekExpenses;
      case 2: return _monthExpenses;
      default: return _todayExpenses;
    }
  }

  String get _periodLabel {
    final loc = AppLocalizations.of(context);
    switch (_selectedPeriod) {
      case 0: return loc.t('today');
      case 1: return loc.t('thisWeek');
      case 2: return loc.t('thisMonth');
      default: return loc.t('today');
    }
  }

  Widget _buildProfitCard() {
    final income = _selectedIncome;
    final expenses = _selectedExpenses;
    final profit = income - expenses;
    final isProfit = profit >= 0;
    final profitColor = isProfit ? const Color(0xFF0A8E48) : const Color(0xFFE53935);
    final profitIcon = isProfit ? Icons.trending_up : Icons.trending_down;
    final loc = AppLocalizations.of(context);
    final profitLabel = (() {
      switch (_selectedPeriod) {
        case 0: return isProfit ? loc.t('todayProfit') : loc.t('todayLoss');
        case 1: return isProfit ? loc.t('thisWeekProfit') : loc.t('thisWeekLoss');
        case 2: return isProfit ? loc.t('thisMonthProfit') : loc.t('thisMonthLoss');
        default: return isProfit ? loc.t('todayProfit') : loc.t('todayLoss');
      }
    })();

    final total = income + expenses;
    final incomePercent = total > 0 ? income / total : 0.0;
    final expensePercent = total > 0 ? expenses / total : 0.0;

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
            'Br${profit.abs().toStringAsFixed(0)}',
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
              _buildProfitDetail('Income', income, Icons.arrow_upward),
              const SizedBox(width: 24),
              _buildProfitDetail('Expenses', expenses, Icons.arrow_downward),
            ],
          ),
          const SizedBox(height: 12),
          // Period selector
          Row(
            children: [
              _buildPeriodChip(0, AppLocalizations.of(context).t('today')),
              const SizedBox(width: 6),
              _buildPeriodChip(1, AppLocalizations.of(context).t('thisWeek')),
              const SizedBox(width: 6),
              _buildPeriodChip(2, AppLocalizations.of(context).t('thisMonth')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_dailyIncome.isEmpty) return const SizedBox.shrink();

    final maxY = [
      ..._dailyIncome.map((e) => e.value),
      ..._dailyExpenses.map((e) => e.value),
    ].fold<double>(0, (a, b) => a > b ? a : b);

    final chartMaxY = maxY > 0 ? maxY * 1.2 : 1000.0;

    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            AppLocalizations.of(context).t('last7Days'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(width: 12, height: 12, color: const Color(0xFF0A8E48)),
              const SizedBox(width: 4),
              const Text('Income', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 12),
              Container(width: 12, height: 12, color: const Color(0xFFE53935)),
              const SizedBox(width: 4),
              const Text('Expenses', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final incomeH = chartMaxY > 0
                    ? (_dailyIncome[i].value / chartMaxY) * 140
                    : 0.0;
                final expenseH = chartMaxY > 0
                    ? (_dailyExpenses[i].value / chartMaxY) * 140
                    : 0.0;
                final day = _dailyIncome[i].key;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 10,
                            height: incomeH.clamp(2, 140),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0A8E48),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 10,
                            height: expenseH.clamp(2, 140),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dayName(day),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _dayName(DateTime day) => _dayNames[(day.weekday - 1) % 7];

  Widget _buildProfitDetail(String label, double amount, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          '$label: Br${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(int index, String label) {
    final isSelected = _selectedPeriod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.7),
          ),
        ),
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
    final label = isIncome ? 'Income' : 'Expense';

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
                '${isIncome ? '+' : '-'}Br${amount.toStringAsFixed(0)}',
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
