import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for input formatters
import 'package:intl/intl.dart'; // For date formatting
import 'package:payments_tracker_flutter/transaction_model.dart';
import 'database_helper.dart';

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
  Future<void> _addTransaction() async {
    double unsignedAmount=double.parse(_amountController.text);
    TransactionModel txn = TransactionModel(
      amount: widget.transactionType==TransactionType.income? unsignedAmount : -1*unsignedAmount, // Use tryParse to handle potential errors
      note: _notesController.text.trim(), // Trim whitespace from notes
      createdAt: _currentDateTime,
    );


      final int addedTransactionId=await DatabaseHelper.instance.insertTransaction(txn);
      if(addedTransactionId > 0){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction $addedTransactionId added successfully')),
        );
        Navigator.pop(context);
      }else
        {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error adding transaction')),
          );
        }



  }
  Future<void> _editTransaction() async {

  }
  Future<void> onAddEditButtonPressed() async
  {
    if(_amountController.text.isEmpty || _notesController.text.isEmpty)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }


    switch(widget.mode){
      case ScreenMode.add:
        await _addTransaction();
        break;
      case ScreenMode.edit:
        await _editTransaction();
        break;
    }





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
        title: Text(appBarTitle),
        centerTitle: true, // Centered AppBar title
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
            const SizedBox(height: 8), // Added spacing between Date and Time
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false), // Updated keyboardType
              inputFormatters: <TextInputFormatter>[ // Added inputFormatters
                FilteringTextInputFormatter.allow(RegExp(r'''^\d*\.?\d{0,2}''')),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Full width, 50 height
                  shape: const StadiumBorder(), // Rounded corners
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Button text style
                ),
                onPressed: onAddEditButtonPressed, // Call the method here
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


