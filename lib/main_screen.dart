import 'package:flutter/material.dart';
import 'add_edit_transaction_screen.dart';
import 'transaction_details_screen.dart';
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

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Total amount', // We can make this dynamic later
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
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
                    MaterialPageRoute(builder: (context) => const TransactionDetailsScreen()),
                  );
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
                      );
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
                      );
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
