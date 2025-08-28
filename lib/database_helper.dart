import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'transaction_model.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('payment_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // <- incremented from 1 to 2
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // <- add this
    );

  }
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2 adds dailyClosingInfo table
      await db.execute('''
      CREATE TABLE daily_closing_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        closing_balance REAL NOT NULL,
        closing_txn_id INTEGER NOT NULL,
        closing_date TEXT NOT NULL UNIQUE,
        FOREIGN KEY (closing_txn_id) REFERENCES transactions(id)
      )
    ''');
    }

    // You can handle future upgrades here:
    // if (oldVersion < 3) { ... }
  }


  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
    CREATE TABLE daily_closing_info (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      closing_balance REAL NOT NULL,
      closing_txn_id INTEGER NOT NULL,
      closing_date TEXT NOT NULL UNIQUE,
      FOREIGN KEY (closing_txn_id) REFERENCES transactions(id)
    )
  ''');
  }

  // ---------------- CRUD METHODS ----------------

  // Insert transaction
  Future<int> insertTransaction(TransactionModel txn) async {
    final db = await instance.database;
    return await db.insert('transactions', txn.toMap());
  }

  // Get all transactions (ordered by newest first)
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'createdAt DESC');
    return result.map((row) => TransactionModel.fromMap(row)).toList();
  }

  // Get single transaction by id
  Future<TransactionModel?> getTransactionById(int id) async {
    final db = await instance.database;
    final result = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return TransactionModel.fromMap(result.first);
    } else {
      return null;
    }
  }
  Future<double> getBalanceUntilTransactionByTransactionId(int id) async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT SUM(amount) as balance
    FROM transactions
    WHERE id <= ?
  ''', [id]);

    if (result.isNotEmpty && result.first['balance'] != null) {
      return result.first['balance'] as double;
    }
    return 0.0;
  }


  // Update transaction
  Future<int> updateTransaction(TransactionModel txn) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  // Delete transaction
  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> autoCloseDay() async {
    final db = await DatabaseHelper.instance.database;

    final lastClosing = await db.query(
      'daily_closing_info',
      orderBy: 'closing_date DESC',
      limit: 1,
    );

    DateTime lastClosedDate = lastClosing.isNotEmpty
        ? DateTime.parse(lastClosing.first['closing_date'] as String)
        : DateTime(2000); // some early default

    DateTime today = DateTime.now();

    // If last closed date < yesterday, close all missing days
    while (lastClosedDate.isBefore(DateTime(today.year, today.month, today.day - 1))) {
      final nextDay = lastClosedDate.add(const Duration(days: 1));
      await closeDayForDate(nextDay);
      lastClosedDate = nextDay;
    }
  }
  Future<void> closeDayForDate(DateTime day) async {
    final db = await instance.database;
    final dayStr = day.toIso8601String().substring(0, 10);

    final lastTxn = await db.query(
      'transactions',
      where: 'date(createdAt) = ?',
      whereArgs: [dayStr],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (lastTxn.isEmpty) return; // no transactions → skip

    final lastTxnId = lastTxn.first['id'] as int;

    final prevClosing = await db.query(
      'daily_closing_info',
      orderBy: 'closing_date DESC',
      limit: 1,
    );
    final prevBalance = prevClosing.isNotEmpty
        ? prevClosing.first['closing_balance'] as double
        : 0.0;

    final sumResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE date(createdAt) = ?',
      [dayStr],
    );
    final todayTotal = sumResult.first['total'] ?? 0.0;

    final closingBalance = prevBalance + (todayTotal as double);

    await db.insert(
      'daily_closing_info',
      {
        'closing_balance': closingBalance,
        'closing_txn_id': lastTxnId,
        'closing_date': dayStr,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  Future<double> getTodayBalance() async {
    final db = await instance.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // Get last closing before today
    final lastClosing = await db.query(
      'daily_closing_info',
      orderBy: 'closing_date DESC',
      limit: 1,
    );
    final lastBalance = lastClosing.isNotEmpty
        ? lastClosing.first['closing_balance'] as double
        : 0.0;

    // Sum today's transactions
    final sumResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE date(createdAt) = ?',
      [todayStr],
    );
    final todayTotal = sumResult.first['total'] ?? 0.0;

    return lastBalance + (todayTotal as double);
  }


}
