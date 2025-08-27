import 'package:flutter/material.dart';
import 'package:payments_tracker_flutter/database_helper.dart';
import 'add_edit_transaction_screen.dart';
import 'transactions_log_screen.dart';
import 'monthly_summary_screen.dart';
import 'database_helper.dart';
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

// Placeholder screen for Subtract operation
class SubtractScreen extends StatelessWidget {
  const SubtractScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subtract Operation')),
      body: const Center(child: Text('Subtract Screen')),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future<double> _currentBalanceFuture = DatabaseHelper.instance.getCurrentBalance();

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() {
      _currentBalanceFuture = DatabaseHelper.instance.getCurrentBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Periodically refresh the balance or use a state management solution
    // for more complex scenarios. For simplicity, we can refresh on build.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder<double>(
                future: _currentBalanceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    final balance = snapshot.data ?? 0.0;
                    final color = balance >= 0 ? Colors.green : Colors.red;
                    return Text(
                      '${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
                  shape: const StadiumBorder(),
                  minimumSize: const Size(220, 50),
                ),
                child: const Text('Details'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransactionsLogScreen()),
                  ).then((_) => _loadBalance()); // Refresh balance after returning
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
                  shape: const StadiumBorder(),
                  minimumSize: const Size(220, 50),
                ),
                child: const Text('Monthly Summary'),
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => const MonthlySummaryScreen()),
                  // );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: Colors.orange,

                    content: Text("Not implemented in this version"),
                  ));
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
                      shape: const StadiumBorder(),
                      minimumSize: const Size(100, 50),
                    ),
                    child: const Text('+'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddEditTransactionScreen(transactionType: TransactionType.income, mode: ScreenMode.add)),
                      ).then((_) => _loadBalance()); // Refresh balance after returning
                    },
                  ),
                  const SizedBox(width: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
                      shape: const StadiumBorder(),
                      minimumSize: const Size(100, 50),
                    ),
                    child: const Text('-'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddEditTransactionScreen(transactionType: TransactionType.expense, mode: ScreenMode.add)),
                      ).then((_) => _loadBalance()); // Refresh balance after returning
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
