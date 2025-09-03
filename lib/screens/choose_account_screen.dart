import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart'; // Commented out as per previous request
import 'dart:io'; // Kept for general file operations if needed elsewhere, can be removed if not used

import 'package:payments_tracker_flutter/database/tables/account_table.dart';
import 'package:payments_tracker_flutter/database/tables/transaction_table.dart';
import 'package:payments_tracker_flutter/global_variables/chosen_account.dart';
import 'package:payments_tracker_flutter/models/account_model.dart';
import 'package:payments_tracker_flutter/widgets/account_card.dart';
import 'package:payments_tracker_flutter/screens/main_screen.dart';
import 'package:payments_tracker_flutter/database/database_helper.dart';

class ChooseAccountScreen extends StatefulWidget {
  const ChooseAccountScreen({Key? key}) : super(key: key);

  @override
  State<ChooseAccountScreen> createState() => _ChooseAccountScreenState();
}

class _ChooseAccountScreenState extends State<ChooseAccountScreen> {
  // Store accounts with their balances
  List<Map<String, dynamic>> _accountsData = [];
  final TextEditingController _resetConfirmController = TextEditingController();

  final TextEditingController _editAccountNameController =
      TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();

  bool _isInitiallyLoading = true; // Corrected typo and ensures initial loading state

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    if (mounted) {
      setState(() {
        _isInitiallyLoading = true; // Show main loader
      });
    }

    final accountsFromDb = await AccountTable.getAll();
    List<Map<String, dynamic>> newAccountsData = [];

    for (var account in accountsFromDb) {
      double balance = 0.0; // Default balance
      if (account.id != null) {
        try {
          balance = await TransactionTable.getTotalBalanceForAccount(account.id!);
        } catch (e) {
          print("Error fetching balance for account ${account.name} (ID: ${account.id}): $e");
          // Optionally, set a specific error state for this account's balance
        }
      }
      newAccountsData.add({'account': account, 'balance': balance});
    }

    if (mounted) {
      setState(() {
        _accountsData = newAccountsData;
        _isInitiallyLoading = false; // Hide main loader, data is ready
      });
    }
  }

  void _onAccountTap(AccountModel account) {
    ChosenAccount().account = account;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    ).then((_) {
      _loadAccounts(); // This will now reload accounts and their balances
    });
  }

  Future<void> _showAddAccountDialog() async {
    _accountNameController.clear();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
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
              onPressed: () async {
                final String name = _accountNameController.text.trim();
                if (name.isNotEmpty) {
                  final newAccountModel = AccountModel(name: name);
                  await AccountTable.insert(newAccountModel);
                  // No need to pop navigator before _loadAccounts if it handles mounted check
                  _loadAccounts(); // Reload accounts and balances
                  if (mounted) Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditAccountDialog(AccountModel account) async {
    _editAccountNameController.text = account.name;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Account Name'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _editAccountNameController,
                  decoration:
                      const InputDecoration(hintText: "New Account Name"),
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
              child: const Text('Save'),
              onPressed: () async {
                final String newName = _editAccountNameController.text.trim();
                if (newName.isNotEmpty && newName != account.name) {
                  // Assuming AccountModel does not store balance directly,
                  // or if it does, it's not managed here directly for editing.
                  // The balance is fetched in _loadAccounts.
                  final updatedAccount = AccountModel(
                      id: account.id, name: newName); 
                  await AccountTable.update(updatedAccount);
                   _loadAccounts(); // Reload accounts and balances
                  if (mounted) Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pop(); // Pop if no change or empty
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCreateBackup() async {
    print('Create Backup: FilePicker functionality disabled.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create Backup feature is currently disabled.')),
      );
    }
    /*
    // FilePicker logic commented out
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Database Backup',
        fileName:
            'payments_tracker_backup_\${DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-')}.db',
        type: FileType.custom,
        allowedExtensions: ['.db'],
      );

      if (outputFile != null) {
        if (!outputFile.toLowerCase().endsWith('.db')) {
          outputFile += '.db';
        }
        final success = await _dbHelper.createBackup(outputFile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(success
                    ? 'Backup created successfully at \\n\$outputFile'
                    : 'Backup failed.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup operation cancelled.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating backup: \$e')),
        );
      }
      print('Error during backup creation: \$e');
    }
    */
  }

  Future<void> _handleRestoreBackup() async {
    print('Restore Backup: FilePicker functionality disabled.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore Backup feature is currently disabled.')),
      );
    }
    /*
    // FilePicker logic commented out
    final bool? confirmRestore = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Restore'),
          content: const Text(
              'Restoring from a backup will overwrite all current data. This action cannot be undone. Are you sure?'),
          actions: <Widget>[
            TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false)),
            TextButton(
                child: const Text('Restore',
                    style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    );

    if (confirmRestore == true) {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['.db', '.sqlite', '.sqlite3'],
        );

        if (result != null && result.files.single.path != null) {
          final String backupPath = result.files.single.path!;
          final success = await _dbHelper.restoreBackup(backupPath);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(success
                      ? 'Restore successful! Application will refresh data.'
                      : 'Restore failed.')),
            );
            if (success) {
              await _loadAccounts(); // Reload accounts and balances
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('No backup file selected or path is invalid.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error restoring backup: \$e')),
          );
        }
        print('Error during backup restoration: \$e');
      }
    }
    */
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
                    Navigator.of(context).pop(); // Pop confirmation dialog
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
        _loadAccounts(); // Refresh the account list (it should be empty)
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
    _accountNameController.dispose();
    _editAccountNameController.dispose();
    _resetConfirmController.dispose(); // Dispose reset controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Account'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'create_backup') {
                _handleCreateBackup();
              } else if (value == 'restore_backup') {
                _handleRestoreBackup();
              } else if (value == 'reset') {
                _showResetConfirmationDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'create_backup',
                child: Text('Create Backup'),
              ),
              const PopupMenuItem<String>(
                value: 'restore_backup',
                child: Text('Restore Backup'),
              ),
              const PopupMenuItem<String>(
                value: 'reset',
                child: Text('Reset Database'),
              ),
            ],
          ),
        ],
      ),
      body: _isInitiallyLoading
          ? const Center(child: CircularProgressIndicator())
          : _accountsData.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No accounts yet.\nTap the + button to add your first one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _accountsData.length,
                  itemBuilder: (context, index) {
                    final accountData = _accountsData[index];
                    final AccountModel account = accountData['account'] as AccountModel;
                    final double balance = accountData['balance'] as double;

                    return AccountCard(
                      account: account,
                      balance: balance, // Use pre-fetched balance
                      onTap: () => _onAccountTap(account),
                      onEditPressed: () => _showEditAccountDialog(account),
                      onDeletePressed: () async {
                        final bool? confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: Text(
                                  'Are you sure you want to delete account ${account.name}?'),
                              actions: <Widget>[
                                TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false)),
                                TextButton(
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true)),
                              ],
                            );
                          },
                        );

                        if (confirmDelete == true) {
                          if (account.id == null) { // Safety check
                             if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot delete account without an ID.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            return;
                          }
                          bool accountHasTransactions = await TransactionTable
                                  .getTransactionsCountForAccount(account.id!) > 0;
                          if (accountHasTransactions) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Account ${account.name} cannot be deleted because it has transactions. Please delete all transactions first.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            await AccountTable.delete(account.id!);
                            if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Account ${account.name} deleted successfully.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                            _loadAccounts(); // Refresh list
                          }
                        }
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add New Account',
      ),
    );
  }
}
