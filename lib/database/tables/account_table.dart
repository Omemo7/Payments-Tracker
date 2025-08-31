
import 'package:payments_tracker_flutter/database/database_helper.dart';
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
