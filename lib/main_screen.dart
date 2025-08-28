import 'package:flutter/material.dart';
import 'package:payments_tracker_flutter/database_helper.dart';
import 'add_edit_transaction_screen.dart';
import 'transactions_log_screen.dart';
import 'monthly_summary_screen.dart';

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

class _MainScreenState extends State<MainScreen> {
  Future<double> _currentBalanceFuture = DatabaseHelper.instance.getTodayBalance();
  final TextEditingController _resetConfirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() {
      _currentBalanceFuture = DatabaseHelper.instance.getTodayBalance();
    });
  }

  Future<void> _showResetConfirmationDialog() async {
    _resetConfirmController.clear();
    bool isButtonEnabled = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return StatefulBuilder( 
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Confirm Reset'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text('This action is irreversible and will delete all data.'),
                    const Text('Please type "I am sure" to confirm.'),
                    TextField(
                      controller: _resetConfirmController,
                      decoration: const InputDecoration(hintText: 'I am sure'),
                      onChanged: (text) {
                        setStateDialog(() {
                          isButtonEnabled = text == 'I am sure';
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: isButtonEnabled
                      ? () {
                          Navigator.of(context).pop(); 
                          _performFullReset();
                        }
                      : null, 
                  child: const Text('Confirm Reset'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performFullReset() async {
    try {
      await DatabaseHelper.instance.resetDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database has been reset successfully!')),
        );
        _loadBalance(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting database: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _resetConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments Tracker'),
        centerTitle: true,
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                _showResetConfirmationDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reset All Data'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Current Balance', 
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
