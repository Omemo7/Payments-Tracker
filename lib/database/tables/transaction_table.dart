




import 'package:sqflite/sqflite.dart';
import 'package:payments_tracker_flutter/models/transaction_model.dart';
import '../database_helper.dart';
import 'package:intl/intl.dart';

class TransactionTable {
  static const table = DatabaseHelper.tableTransactions;

  // ---------------- CRUD METHODS ----------------

  /// Insert transaction
  static Future<int> insertTransaction(TransactionModel txn) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(table, txn.toMap());
  }

  /// Get all transactions (ordered by newest first)
  static Future<List<TransactionModel>> getAllTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(table, orderBy: 'createdAt DESC');
    return result.map((row) => TransactionModel.fromMap(row)).toList();
  }

  static Future<int> getTransactionsCountForAccount(int? accountId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(table, where: 'accountId = ?', whereArgs: [accountId]);
    return result.length;
  }

  /// Get single transaction by id
  static Future<TransactionModel?> getTransactionById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return TransactionModel.fromMap(result.first);
    }
    return null;
  }

  /// Get balance until a specific transaction
  static Future<double> getBalanceUntilTransactionByTransactionIdForAccount(int transactionId,int? accountId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as balance
      FROM $table
      WHERE accountId = ? AND id <= ?
    ''', [accountId,transactionId]);

    if (result.isNotEmpty && result.first['balance'] != null) {
      return result.first['balance'] as double;
    }
    return 0.0;
  }

  /// Get total balance for a specific account
  static Future<double> getTotalBalanceForAccount(int? accountId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as balance
      FROM $table
      WHERE accountId = ?
    ''', [accountId]);

    if (result.isNotEmpty && result.first['balance'] != null) {
      return result.first['balance'] as double;
    }
    return 0.0;
  }


  /// Get today's balance
  static Future<double> getTodayBalanceForAccount(int? accountId) async {

    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    final result = await db.rawQuery('''
      SELECT SUM(amount) as balance
      FROM $table
      WHERE accountId = ? AND DATE(createdAt) = ?
    ''', [accountId, today]);

    if (result.isNotEmpty && result.first['balance'] != null) {
      return result.first['balance'] as double;
    }
    return 0.0;
  }

  /// Update transaction
  static Future<int> updateTransaction(TransactionModel txn) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      table,
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  /// Delete transaction
  static Future<int> deleteTransaction(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // ---- Methods for Day-by-Day Pagination ----

  /// Fetches a list of unique dates that have transactions, sorted.
  static Future<List<DateTime>> getUniqueTransactionDates({bool descending = true}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT DISTINCT DATE(createdAt) as transactionDate '
            'FROM $table '
            'ORDER BY transactionDate ${descending ? 'DESC' : 'ASC'}'
    );

    if (maps.isEmpty) return [];

    return maps.map((row) => DateTime.parse(row['transactionDate'] as String)).toList();
  }

  /// Fetches a list of unique dates that have transactions for a specific account, sorted.
  static Future<List<DateTime>> getUniqueTransactionDatesForAccount(int? accountId, {bool descending = true}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT DISTINCT DATE(createdAt) as transactionDate '
            'FROM $table '
            'WHERE accountId = ? '
            'ORDER BY transactionDate ${descending ? 'DESC' : 'ASC'}',
        [accountId]);

    if (maps.isEmpty) return [];

    return maps.map((row) => DateTime.parse(row['transactionDate'] as String)).toList();
  }

  /// Fetches all transactions for a specific date and account.
  static Future<List<TransactionModel>> getTransactionsForDateAndAccount(DateTime date, int? accountId) async {
    final db = await DatabaseHelper.instance.database;
    final dateString = date.toIso8601String().substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'DATE(createdAt) = ? AND accountId = ?',
      whereArgs: [dateString, accountId],
      orderBy: 'createdAt DESC',
    );

    if (maps.isEmpty) return [];

    return maps.map((row) => TransactionModel.fromMap(row)).toList();
  }
  /// Fetches all transactions for a specific date.
  static Future<List<TransactionModel>> getTransactionsForDate(DateTime date) async {
    final db = await DatabaseHelper.instance.database;
    final dateString = date.toIso8601String().substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'DATE(createdAt) = ?',
      whereArgs: [dateString],
      orderBy: 'createdAt DESC',
    );

    if (maps.isEmpty) return [];

    return maps.map((row) => TransactionModel.fromMap(row)).toList();
  }
}
