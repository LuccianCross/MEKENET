import 'package:flutter/material.dart';

import '../models/debt.dart';
import '../repositories/debt_repository.dart';

class DebtsScreen extends StatefulWidget {
  final DebtRepository debtRepository;

  const DebtsScreen({
    super.key,
    required this.debtRepository,
  });

  @override
  State<DebtsScreen> createState() =>
      _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Debt> _debts = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final debts =
          await widget.debtRepository.getAll();

      if (!mounted) return;

      setState(() {
        _debts = debts;
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

  @override
  Widget build(BuildContext context) {
    final outstanding =
        _debts
            .where((debt) => debt.status == 'open')
            .fold<double>(
              0,
              (total, debt) =>
                  total + debt.amount,
            );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Who Owes Me',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor:
            const Color(0xFF0A8E48),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDebts,
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: Color(0xFF0A8E48),
                ),
              )
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 50,
                                color: Colors.red,
                              ),
                              const SizedBox(
                                  height: 12),
                              const Text(
                                'Could not load debts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                  height: 8),
                              Text(
                                _error!,
                                textAlign:
                                    TextAlign.center,
                              ),
                              const SizedBox(
                                  height: 20),
                              ElevatedButton(
                                onPressed:
                                    _loadDebts,
                                child:
                                    const Text(
                                  'Retry',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        margin:
                            const EdgeInsets.all(16),
                        padding:
                            const EdgeInsets.all(18),
                        decoration:
                            BoxDecoration(
                          gradient:
                              const LinearGradient(
                            colors: [
                              Color(0xFF0A8E48),
                              Color(0xFF1B6B3A),
                            ],
                            begin:
                                Alignment.topLeft,
                            end:
                                Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                                  16),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text(
                              'Total Outstanding Owed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w500,
                                color:
                                    Colors.white,
                              ),
                            ),
                            Text(
                              'Br${outstanding.toStringAsFixed(0)}',
                              style:
                                  const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: _debts.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(
                                      height: 80),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons
                                              .people_outline,
                                          size: 50,
                                          color:
                                              Colors.grey,
                                        ),
                                        SizedBox(
                                            height: 12),
                                        Text(
                                          'No debts recorded',
                                          style:
                                              TextStyle(
                                            fontSize:
                                                16,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 16,
                                ),
                                itemCount:
                                    _debts.length,
                                itemBuilder:
                                    (context, index) {
                                  return _buildDebtorTile(
                                    _debts[index],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDebtorTile(Debt debt) {
    final isPaid =
        debt.status == 'paid';

    final color = isPaid
        ? const Color(0xFF0A8E48)
        : const Color(0xFFFF8F00);

    final icon =
        isPaid ? Icons.check : Icons.person;

    final statusText =
        isPaid ? 'Paid' : 'Unpaid';

    final statusColor = isPaid
        ? const Color(0xFF0A8E48)
        : const Color(0xFFE53935);

    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: isPaid
            ? Border.all(
                color:
                    const Color(0xFF0A8E48),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(
              alpha: 0.04,
            ),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                color.withValues(alpha: 0.12),
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
                  debt.customerName,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPaid
                      ? 'Paid'
                      : 'Open debt',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPaid
                        ? const Color(
                            0xFF0A8E48)
                        : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                'Br${debt.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration:
                    BoxDecoration(
                  color: statusColor
                      .withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight:
                        FontWeight.w600,
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