import 'package:flutter/material.dart';
import 'package:payments_tracker_flutter/global_variables/chosen_account.dart';
import 'package:payments_tracker_flutter/models/account_model.dart';
import 'package:payments_tracker_flutter/widgets/account_card.dart';
// TODO: Import your database helper here
// import 'package:payments_tracker_flutter/database/database_helper.dart';

class ChooseAccountScreen extends StatefulWidget {
  const ChooseAccountScreen({Key? key}) : super(key: key);

  @override
  State<ChooseAccountScreen> createState() => _ChooseAccountScreenState();
}

class _ChooseAccountScreenState extends State<ChooseAccountScreen> {
  // TODO: Replace this with actual data from your database
  final List<AccountModel> _accounts = [
    AccountModel(id: 1, name: 'Account 1'), // Assuming balance is part of your model
    AccountModel(id: 2, name: 'Account 2'),
    AccountModel(id: 3, name: 'Account 3'),
  ];

  // final DatabaseHelper _dbHelper = DatabaseHelper(); // TODO: Initialize your database helper
  final TextEditingController _accountNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _loadAccounts(); // TODO: Load accounts from database
  }

  // Future<void> _loadAccounts() async {
  //   // TODO: Fetch accounts from your database and update the state
  //   // final accounts = await _dbHelper.getAllAccounts();
  //   // setState(() {
  //   //   _accounts = accounts;
  //   // });
  // }

  void _onAccountTap(AccountModel account) {
    ChosenAccount().account = account;
    // TODO: Navigate to the desired screen after choosing an account
    Navigator.pop(context);
  }

  Future<void> _showAddAccountDialog() async {
    _accountNameController.clear(); // Clear previous input
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Account'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _accountNameController,
                  decoration: const InputDecoration(hintText: "Account Name"),
                  autofocus: true,
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
              child: const Text('Add'),
              onPressed: () {
                final String name = _accountNameController.text.trim();
                if (name.isNotEmpty) {
                  // TODO: Save the new account to your database
                  // For example: final newAccountId = await _dbHelper.insertAccount(AccountModel(name: name, balance: 0.0));
                  // Then, create the AccountModel with the id returned from the database and an initial balance.
                  final newAccount = AccountModel(
                    id: _accounts.length + 1, // Placeholder ID, replace with DB generated ID
                    name: name,

                  );
                  setState(() {
                    _accounts.add(newAccount);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Account'),
      ),
      body: ListView.builder(
        itemCount: _accounts.length,
        itemBuilder: (context, index) {
          final account = _accounts[index];
          return AccountCard(
            account: account,
            onTap: () => _onAccountTap(account),
            onEditPressed: () {
              // TODO: Implement edit functionality
            },
            onDeletePressed: () {
              // TODO: Implement delete functionality
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
      ),
    );
  }
}
