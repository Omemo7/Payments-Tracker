import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

// Define Enums
enum TransactionType { income, expense }
enum ScreenMode { add, edit }

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionType transactionType;
  final ScreenMode mode;

  const AddEditTransactionScreen({
    super.key,
    required this.transactionType,
    required this.mode,
  });

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _currentDateTime = DateTime.now();

  // TODO: Use widget.transactionType and widget.mode to further customize UI/logic
  // For example, pre-fill fields if in edit mode.

  @override
  void dispose() {
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the AppBar title and Button text based on mode
    String appBarTitle = widget.mode == ScreenMode.add ? 'Add' : 'Edit';
    appBarTitle += ' Transaction';
    appBarTitle += (widget.transactionType == TransactionType.income ? ' (Income)' : ' (Expense)');
    
    final String buttonText = widget.mode == ScreenMode.add ? 'Add' : 'Save Changes';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle), // Updated AppBar title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Date: ${DateFormat.yMd().format(_currentDateTime)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Time: ${DateFormat.jm().format(_currentDateTime)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: const OutlineInputBorder(),
                prefixText: widget.transactionType == TransactionType.income ? '+ ' : '- ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement add/edit functionality based on widget.mode and widget.transactionType
                  final String notes = _notesController.text;
                  final double? amount = double.tryParse(_amountController.text);
                  if (amount != null) {
                    // Process notes and amount
                    print('Mode: ${widget.mode}');
                    print('Type: ${widget.transactionType}');
                    print('Notes: $notes');
                    print('Amount: $amount');
                    Navigator.pop(context); // Go back after adding/editing
                  } else {
                    // Show error if amount is invalid
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(buttonText), // Updated button text
              ),
            ),
          ],
        ),
      ),
    );
  }
}
