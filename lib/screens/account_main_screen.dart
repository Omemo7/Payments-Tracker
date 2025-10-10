import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:payments_tracker_flutter/global_variables/chosen_account.dart';
import 'package:payments_tracker_flutter/widgets/monthly_or_daily_details_card.dart';
import 'package:payments_tracker_flutter/widgets/utility.dart';


import '../widgets/basic/safe_scaffold.dart';
import 'add_edit_transaction_screen.dart';
import 'transactions_log_screen.dart';
import 'monthly_summary_screen.dart';
import '../database/tables/transaction_table.dart';
import '../global_variables/app_colors.dart';






class AccountMainScreen extends StatefulWidget {
  const AccountMainScreen({super.key});
  @override
  State<AccountMainScreen> createState() => _AccountMainScreenState();
}

class _AccountMainScreenState extends State<AccountMainScreen> {
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
        .getMonthlySummary( selectedMonthDate,accountId)
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
    return SafeScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(accountName),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // ===== Top balance (FutureBuilder wrapped with Expanded) =====
              Flexible(
                fit: FlexFit.loose,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                  child: FutureBuilder<Map<String, double>>(
                    future: _monthlySummaryFuture,
                    builder: (context, snapshot) {
                      final hasLive = snapshot.hasData;
                      final data = hasLive ? snapshot.data! : (_lastSummary ?? {});

                      if (!hasLive && _lastSummary == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final balance = (data['overallBalance'] ?? 0.0);
                      final color =
                      balance >= 0 ? AppColors.incomeGreen : AppColors.expenseRed;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined,
                                  color: color, size: 34),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 220),
                                child: Utility.handleNumberAppearanceForOverflow(
                                  number: balance,
                                  color: color,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w600,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ===== Actions =====
              ElevatedButton.icon(
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('Transactions Log'),
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
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
                  padding:
                  const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
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
                  padding:
                  const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
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

              const SizedBox(height: 20),

              // ===== Monthly details =====
              FutureBuilder<Map<String, double>>(
                future: _monthlySummaryFuture,
                builder: (context, snapshot) {
                  final hasLive = snapshot.hasData;
                  final data = hasLive ? snapshot.data! : (_lastSummary ?? {});

                  if (!hasLive && _lastSummary == null) {
                    return const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final income = data['income'] ?? 0.0;
                  final expense = data['expense'] ?? 0.0;
                  final overallBalance = data['overallBalance'] ?? 0.0;

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: MonthlyOrDailyDetailsCard(
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
      ),
    );
  }

}
