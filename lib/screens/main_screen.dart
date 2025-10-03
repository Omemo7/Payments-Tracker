import 'package:flutter/material.dart';
import 'package:payments_tracker_flutter/global_variables/chosen_account.dart';
import 'package:payments_tracker_flutter/widgets/monthly_or_daily_details_card.dart';

import 'add_edit_transaction_screen.dart';
import 'transactions_log_screen.dart';
import 'monthly_summary_screen.dart';
import '../database/tables/transaction_table.dart';
import '../global_variables/app_colors.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: const Center(child: Text('Details Screen')),
    );
  }
}

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Operation')),
      body: Center(child: Text('Add Screen')),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Future<Map<String, double>> _monthlySummaryFuture;
  Map<String, double>? _lastSummary; // cache last good data
  DateTime selectedMonthDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMonthlySummary();
  }

  void _loadMonthlySummary() => _refreshMonthlySummary();

  void _refreshMonthlySummary() {
    final accountId = ChosenAccount().account?.id;
    final future = TransactionTable
        .getMonthlySummary(accountId, selectedMonthDate)
        .then((data) {
      _lastSummary = data; // keep cached copy
      return data;
    });

    setState(() {
      _monthlySummaryFuture = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountName = ChosenAccount().account?.name ?? 'Account';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(accountName),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 8),

            // ===== Top balance (uses cached data to prevent flicker) =====
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<Map<String, double>>(
                future: _monthlySummaryFuture,
                builder: (context, snapshot) {
                  final hasLive = snapshot.hasData;
                  final data = hasLive ? snapshot.data! : (_lastSummary ?? {});

                  if (!hasLive && _lastSummary == null) {
                    // first-ever load: keep height stable
                    return const SizedBox(
                      height: 56, // match final row height
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final balance = (data['overallBalance'] ?? 0.0);
                  final color = balance >= 0
                      ? AppColors.incomeGreen
                      : AppColors.expenseRed;

                  return SizedBox(
                    height: 56,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Row(
                        key: ValueKey<double>(balance),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: color,
                            size: 36,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            balance.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ===== Actions =====
            ElevatedButton.icon(
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('Transactions Log'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 24.0),
                shape: const StadiumBorder(),
                minimumSize: const Size(275, 60),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.purple,
                side: BorderSide(
                  color: AppColors.purple.withOpacity(.4),
                  width: 1,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionsLogScreen(),
                  ),
                ).then((_) => _loadMonthlySummary());
              },
            ),
            const SizedBox(height: 15),

            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: const Text('Monthly Summary'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 24.0),
                shape: const StadiumBorder(),
                minimumSize: const Size(275, 60),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.purple,
                side: BorderSide(
                  color: AppColors.purple.withOpacity(.4),
                  width: 1,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MonthlySummaryScreen(),
                  ),
                ).then((_) => _loadMonthlySummary());
              },
            ),
            const SizedBox(height: 15),

            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Transaction'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 24.0),
                shape: const StadiumBorder(),
                minimumSize: const Size(275, 60),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.purple,
                side: BorderSide(
                  color: AppColors.purple.withOpacity(.4),
                  width: 1,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditTransactionScreen(),
                  ),
                ).then((_) => _loadMonthlySummary());
              },
            ),

            const SizedBox(height: 70),

            // ===== Monthly details (uses cached data + stable height on first load) =====
            FutureBuilder<Map<String, double>>(
              future: _monthlySummaryFuture,
              builder: (context, snapshot) {
                final hasLive = snapshot.hasData;
                final data = hasLive ? snapshot.data! : (_lastSummary ?? {});

                if (!hasLive && _lastSummary == null) {
                  return const SizedBox(
                    height: 140, // approximate final card height
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final income = data['income'] ?? 0.0;
                final expense = data['expense'] ?? 0.0;
                final overallBalance = data['overallBalance'] ?? 0.0;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: MonthlyOrDailyDetailsCard(
                    key: ValueKey<String>(
                        '${income.toStringAsFixed(2)}-'
                            '${expense.toStringAsFixed(2)}-'
                            '${overallBalance.toStringAsFixed(2)}-'
                            '${selectedMonthDate.year}${selectedMonthDate.month}'),
                    selectedDateTime: selectedMonthDate,
                    income: income,
                    expense: expense,
                    overallBalanceEndOfMonthOrDay: overallBalance,
                    isMonthly: true,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
