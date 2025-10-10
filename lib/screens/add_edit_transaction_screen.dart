import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:payments_tracker_flutter/global_variables/chosen_account.dart';
import 'package:payments_tracker_flutter/models/transaction_model.dart';

import '../database/tables/transaction_table.dart';
import '../widgets/basic/safe_scaffold.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ',';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // If the new value is empty, just return it
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Get the clean number string without separators and with a single decimal point
    String newText = newValue.text.replaceAll(separator, '');
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(newText)) {
      return oldValue;
    }

    String beforeDecimal = newText;
    String? afterDecimal;

    if (newText.contains('.')) {
      final parts = newText.split('.');
      beforeDecimal = parts[0];
      afterDecimal = parts.length > 1 ? parts[1] : null;
    }

    // Add thousands separators to the integer part
    beforeDecimal = beforeDecimal.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}$separator',
    );

    String formattedText = beforeDecimal;
    if (newText.contains('.')) {
      formattedText += '.';
      if (afterDecimal != null) {
        formattedText += afterDecimal;
      }
    }

    return newValue.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length));
  }
}

enum _TransactionType { income, expense } // internal only

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionModel? transactionToEdit; // the ONLY incoming param

  const AddEditTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();

  late bool _isEditMode;
  late DateTime _currentDateTime;
  late _TransactionType _selectedType;

  @override
  void initState() {
    super.initState();

    _isEditMode = widget.transactionToEdit != null;

    if (_isEditMode) {
      final txn = widget.transactionToEdit!;
      _notesController.text = txn.note ?? '';
      _amountController.text =
          NumberFormat('#,##0.00').format(txn.amount.abs());
      _currentDateTime = txn.createdAt;
      _selectedType = txn.amount >= 0 ? _TransactionType.income : _TransactionType.expense;
    } else {
      _currentDateTime = DateTime.now();
      _selectedType = _TransactionType.expense; 
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addTransaction() async {
    final double unsignedAmount = double.parse(_amountController.text.replaceAll(',', ''));

    final txn = TransactionModel(
      amount: _selectedType == _TransactionType.income ? unsignedAmount : -unsignedAmount,
      note: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: _currentDateTime,
      accountId: ChosenAccount().account?.id,
    );

    final int id = await TransactionTable.insertTransaction(txn);
    if (!mounted) return;
    if (id > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding transaction')),
      );
    }
  }

  Future<void> _editTransaction() async {
    final double unsignedAmount = double.parse(_amountController.text.replaceAll(',', ''));

    final updated = TransactionModel(
      id: widget.transactionToEdit!.id,
      amount: _selectedType == _TransactionType.income ? unsignedAmount : -unsignedAmount,
      note: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: _currentDateTime,
      accountId: ChosenAccount().account?.id,
    );

    final int rows = await TransactionTable.updateTransaction(updated);
    if (!mounted) return;
    if (rows > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction updated successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating transaction or no changes made')),
      );
    }
  }

  Future<void> _onSavePressed() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the amount.')),
      );
      return;
    }
    try {
      double.parse(_amountController.text.replaceAll(',', ''));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount format')),
      );
      return;
    }

    if (_isEditMode) {
      await _editTransaction();
    } else {
      await _addTransaction();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleBase = _isEditMode ? 'Edit' : 'Add';
    final titleType = _selectedType == _TransactionType.income ? ' (Income)' : ' (Expense)';
    final String appBarTitle = '$titleBase Transaction$titleType';

    final String buttonText = _isEditMode ? 'Save Changes' : 'Add';
    final Color iconColor = Theme.of(context).colorScheme.primary;

    return SafeScaffold(
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
              // Type selector (user can switch in both add & edit)
              Center(
                child: ToggleButtons(
                  isSelected: [

                    _selectedType == _TransactionType.expense,
                    _selectedType == _TransactionType.income,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedType = index == 0 ? _TransactionType.expense : _TransactionType.income;
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  constraints: const BoxConstraints(minHeight: 40, minWidth: 120),
                  selectedColor: Colors.white,
                  fillColor: Theme.of(context).colorScheme.primary,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Expense'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Income'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40.0),

              Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today_outlined, color: iconColor),
                  const SizedBox(width: 12),
                  Text(
                    'Date: ${DateFormat.yMd().format(_currentDateTime)}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                ],

                ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.access_time_outlined, color: iconColor),
                  const SizedBox(width: 12),
                  Text(
                    'Time: ${DateFormat.jm().format(_currentDateTime)}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                ],

              ),

              const SizedBox(height: 40.0),

              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: const OutlineInputBorder(),
                  prefixText: _selectedType == _TransactionType.income ? '+ ' : '- ',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                inputFormatters: <TextInputFormatter>[
                  ThousandsSeparatorInputFormatter(),
                ],
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

              const SizedBox(height: 30.0),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _onSavePressed,
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
