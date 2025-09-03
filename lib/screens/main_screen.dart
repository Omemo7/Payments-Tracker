import 'package:flutter/material.dart';
import 'package:payments_tracker_flutter/database/database_helper.dart';
import 'package:payments_tracker_flutter/global_variables/chosen_account.dart';
import 'add_edit_transaction_screen.dart';
import 'transactions_log_screen.dart';
import 'monthly_summary_screen.dart';
import '../database/tables/transaction_table.dart';

// Placeholder screen for Details
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

// Placeholder screen for Add operation
class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Operation')),
      body: const Center(child: Text('Add Screen')),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}
Future<double> getTotalBalanceForChosenAccount(){
  return TransactionTable.getTotalBalanceForAccount(ChosenAccount().account?.id);
}
class _MainScreenState extends State<MainScreen> {
  Future<double> _currentBalanceFuture = getTotalBalanceForChosenAccount();

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() {
      _currentBalanceFuture = getTotalBalanceForChosenAccount();
    });
  }



  @override
  void dispose() {

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('${ChosenAccount().account?.name}'),
        centerTitle: true,

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Total Balance',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              FutureBuilder<double>(
                future: _currentBalanceFuture,
                builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final balance = snapshot.data ?? 0.0;
                      final color = balance >= 0 ? Colors.green.shade700 : Colors.red.shade700;
                      return Text(
                        '${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 36, 
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      );
                    }
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('Transactions Log'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
                  shape: const StadiumBorder(),
                  minimumSize: const Size(250, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransactionsLogScreen()),
                  ).then((_) => _loadBalance());
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: const Text('Monthly Summary'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
                  shape: const StadiumBorder(),
                  minimumSize: const Size(250, 50),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.orangeAccent,
                    content: Text("Monthly Summary: Not implemented yet."),
                  ));
                },
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Income'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
                      shape: const StadiumBorder(),
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(135, 50),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddEditTransactionScreen(transactionType: TransactionType.income, mode: ScreenMode.add)),
                      ).then((_) => _loadBalance());
                    },
                  ),
                  const SizedBox(width: 20), 
                  ElevatedButton.icon(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    label: const Text('Expense'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
                      shape: const StadiumBorder(),
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(135, 50),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddEditTransactionScreen(transactionType: TransactionType.expense, mode: ScreenMode.add)),
                      ).then((_) => _loadBalance());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
