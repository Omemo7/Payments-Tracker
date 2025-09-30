
import 'package:payments_tracker_flutter/database/database_helper.dart';
import 'package:payments_tracker_flutter/database/tables/transaction_table.dart';
import 'package:payments_tracker_flutter/models/account_model.dart';

class AccountTable {
  static const table = DatabaseHelper.tableAccounts;

  static Future<int> insert(AccountModel account) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(table, account.toMap());
  }

  static Future<List<AccountModel>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(table);
    return maps.map((e) => AccountModel.fromMap(e)).toList();
  }

  static Future<List<Map<String,dynamic>>> getAllAccountsWithBalances() async {
    final db = await DatabaseHelper.instance.database;
    //get all columns from accounts table and sum of amount from transactions table for each account
    final maps = await db.rawQuery('''
      SELECT
        "$table".*,
        COALESCE(SUM("${TransactionTable.table}".amount), 0.0) as balance
      FROM $table
      LEFT JOIN ${TransactionTable.table} ON $table.id = ${TransactionTable.table}.accountId
      GROUP BY $table.id
    ''');
    return maps.map((map) {
      final account = AccountModel.fromMap(map);
      final balance = map['balance'] as num; // Assuming balance is a numeric type
      return {'account': account, 'balance': balance};
    }).toList();
  }

  static Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> update(AccountModel account) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      table,
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }
}
