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
  final TransactionModel? transactionToEdit;

  const AddEditTransactionScreen({
    super.key,
    required this.transactionType,
    required this.mode,
    this.transactionToEdit,
  }) : assert(mode == ScreenMode.edit ? transactionToEdit != null : true,
            'transactionToEdit cannot be null in edit mode');

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  late DateTime _currentDateTime; // Initialized in initState

  @override
  void initState() {
    super.initState();
    if (widget.mode == ScreenMode.edit && widget.transactionToEdit != null) {
      _notesController.text = widget.transactionToEdit!.note ?? '';
      _amountController.text = widget.transactionToEdit!.amount.abs().toStringAsFixed(2);
      _currentDateTime = widget.transactionToEdit!.createdAt;
    } else {
      // Add mode: always use current date and time
      _currentDateTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addTransaction() async {

    double unsignedAmount = double.parse(_amountController.text);
    TransactionModel txn = TransactionModel(
      amount: widget.transactionType == TransactionType.income ? unsignedAmount : -1 * unsignedAmount,
      note: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: _currentDateTime, // This is DateTime.now() for add mode
    );

    final int addedTransactionId = await DatabaseHelper.instance.insertTransaction(txn);
    if (addedTransactionId > 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction added successfully')),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding transaction')),
        );
      }
    }
  }

  Future<void> _editTransaction() async {
    double unsignedAmount = double.parse(_amountController.text);
    TransactionModel updatedTxn = TransactionModel(
      id: widget.transactionToEdit!.id,
      amount: widget.transactionType == TransactionType.income ? unsignedAmount : -1 * unsignedAmount,
      note: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: _currentDateTime, // This is the original createdAt for edit mode
    );

    final int rowsAffected = await DatabaseHelper.instance.updateTransaction(updatedTxn);
    if (rowsAffected > 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating transaction or no changes made')),
        );
      }
    }
  }

  Future<void> onAddEditButtonPressed() async {
    if (_amountController.text.isEmpty) { // Notes field check removed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the amount.')), // Updated message
      );
      return;
    }
    try {
      double.parse(_amountController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount format')),
      );
      return;
    }

    switch (widget.mode) {
      case ScreenMode.add:
        await _addTransaction();
        break;
      case ScreenMode.edit:
        await _editTransaction();
        break;
    }
  }
  
  // _selectDate and _selectTime methods are kept but not called from UI.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _currentDateTime) {
      setState(() {
        _currentDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _currentDateTime.hour,
          _currentDateTime.minute,
          _currentDateTime.second,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_currentDateTime),
    );
    if (picked != null) {
      setState(() {
        _currentDateTime = DateTime(
          _currentDateTime.year,
          _currentDateTime.month,
          _currentDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = widget.mode == ScreenMode.add ? 'Add' : 'Edit';
    appBarTitle += ' Transaction';

    final currentEffectiveType = widget.mode == ScreenMode.edit 
        ? (widget.transactionToEdit!.amount >= 0 ? TransactionType.income : TransactionType.expense)
        : widget.transactionType;
    
    appBarTitle += (currentEffectiveType == TransactionType.income ? ' (Income)' : ' (Expense)');
    
    final String buttonText = widget.mode == ScreenMode.add ? 'Add' : 'Save Changes';
    final Color iconColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.calendar_today_outlined, color: iconColor),
                title: Text('Date: ${DateFormat.yMd().format(_currentDateTime)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                contentPadding: EdgeInsets.zero,
                dense: true,
                onTap: null, // Not editable
              ),
              const SizedBox(height: 12.0),
              ListTile(
                leading: Icon(Icons.access_time_outlined, color: iconColor),
                title: Text('Time: ${DateFormat.jm().format(_currentDateTime)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                contentPadding: EdgeInsets.zero,
                dense: true,
                onTap: null, // Not editable
              ),
              const SizedBox(height: 24.0),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24.0),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: const OutlineInputBorder(),
                  prefixText: currentEffectiveType == TransactionType.income ? '+ ' : '- ',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 30.0),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: onAddEditButtonPressed,
                  child: Text(buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
