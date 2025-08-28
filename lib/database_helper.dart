import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart'; // Added for DateFormat, though not strictly necessary for query construction if using ISO strings
import 'transaction_model.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const String _databaseName = 'payment_tracker.db';

  // Define table names as constants
  static const String tableTransactions = 'transactions';
  static const String tableDailyClosingInfo = 'daily_closing_info';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // --- Start Added Logging ---
    print('DatabaseHelper: Initializing database at path: $path');
    try {
      final exists = await databaseExists(path);
      print('DatabaseHelper: Database file exists at path? $exists');
    } catch (e) {
      print('DatabaseHelper: Error checking if database exists: $e');
    }
    // --- End Added Logging ---

    return await openDatabase(
      path,
      version: 2, // <- incremented from 1 to 2
      onCreate: (Database db, int version) async {
        // --- Added Logging ---
        print('DatabaseHelper: onCreate called. Version: $version. Creating tables...');
        await _createDB(db, version);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // --- Added Logging ---
        print('DatabaseHelper: onUpgrade called. Old Version: $oldVersion, New Version: $newVersion. Upgrading schema...');
        await _onUpgrade(db, oldVersion, newVersion);
      },
      onOpen: (Database db) {
        // --- Added Logging ---
        print('DatabaseHelper: onOpen called. Database is open.');
      },
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
    '''); // Removed isLocked as it was not in the original user schema from previous interaction context. Add if needed.

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
    return await db.insert(tableTransactions, txn.toMap());
  }

  // Get all transactions (ordered by newest first)
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query(tableTransactions, orderBy: 'createdAt DESC');
    return result.map((row) => TransactionModel.fromMap(row)).toList();
  }

  // Get single transaction by id
  Future<TransactionModel?> getTransactionById(int id) async {
    final db = await instance.database;
    final result = await db.query(tableTransactions, where: 'id = ?', whereArgs: [id]);
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
      tableTransactions,
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  // Delete transaction
  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(tableTransactions, where: 'id = ?', whereArgs: [id]);
  }

  // ---- Methods for Day-by-Day Pagination in TransactionsLogScreen ----

  /// Fetches a list of unique dates that have transactions, sorted.
  Future<List<DateTime>> getUniqueTransactionDates({bool descending = true}) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT DATE(createdAt) as transactionDate FROM $tableTransactions ORDER BY transactionDate ${descending ? 'DESC' : 'ASC'}'
    );

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      // transactionDate is a string like 'YYYY-MM-DD'
      return DateTime.parse(maps[i]['transactionDate'] as String);
    });
  }

  /// Fetches all transactions for a specific date.
  Future<List<TransactionModel>> getTransactionsForDate(DateTime date) async {
    final db = await instance.database;
    // Format the date to 'YYYY-MM-DD' for the SQL query
    // Using substring to avoid dependency on intl for this core DB function if not strictly needed
    // and to match existing style in closeDayForDate (e.g. .substring(0,10))
    String dateString = date.toIso8601String().substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: 'DATE(createdAt) = ?',
      whereArgs: [dateString],
      orderBy: 'createdAt DESC', // Optional: order transactions within the day, newest first
    );

    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  // ---- End of Day-by-Day Pagination Methods ----


  Future<void> autoCloseDay() async {
    final db = await DatabaseHelper.instance.database;
    DateTime today = DateTime.now(); // Get today's date

    // Get last closing date
    final lastClosing = await db.query(
      tableDailyClosingInfo,
      orderBy: 'closing_date DESC',
      limit: 1,
    );

    DateTime lastClosedDate;
    if (lastClosing.isNotEmpty) {
      lastClosedDate = DateTime.parse(lastClosing.first['closing_date'] as String);
    } else {
      // If no closing info exists (e.g., after a reset or first run),
      // we don't want to backfill from an ancient date.
      // Start from 2 days ago relative to today's date components
      // to ensure the loop correctly processes up to yesterday if needed.
      lastClosedDate = DateTime(today.year, today.month, today.day - 2);
    }

    // Fill missing days up to yesterday
    // The loop condition ensures it processes days strictly *before* (today - 1 day)
    DateTime targetDateForLoop = DateTime(today.year, today.month, today.day - 1);
    while (lastClosedDate.isBefore(targetDateForLoop)) {
      final nextDay = lastClosedDate.add(const Duration(days: 1));
      final nextDayStr = nextDay.toIso8601String().split("T")[0];

      // Get transactions for this day
      final txns = await db.query(
        tableTransactions,
        where: "DATE(createdAt) = ?",
        whereArgs: [nextDayStr],
        orderBy: "id DESC", // Assuming higher ID means later transaction for closing
      );

      if (txns.isNotEmpty) {
        final lastTxn = txns.first;

        final prevClosingForAuto = await db.query(
          tableDailyClosingInfo,
          orderBy: 'closing_date DESC',
          where: 'closing_date < ?',
          whereArgs: [nextDayStr],
          limit: 1,
        );
        double prevBalanceForAuto = prevClosingForAuto.isNotEmpty
            ? prevClosingForAuto.first['closing_balance'] as double
            : 0.0;

        final sumForDay = await db.rawQuery(
            'SELECT SUM(amount) as dailyTotal FROM $tableTransactions WHERE DATE(createdAt) = ?',
            [nextDayStr]
        );
        double dailyTotal = (sumForDay.first['dailyTotal'] ?? 0.0) as double;
        double closingBalanceForDay = prevBalanceForAuto + dailyTotal;

        await db.insert(tableDailyClosingInfo, {
          'closing_date': nextDayStr,
          'closing_balance': closingBalanceForDay,
          'closing_txn_id': lastTxn['id'],
        },
            conflictAlgorithm: ConflictAlgorithm.replace
        );

      } else {
        // If no transactions, carry forward the previous day's balance
        final prevClosingForAuto = await db.query(
          tableDailyClosingInfo,
          orderBy: 'closing_date DESC',
          where: 'closing_date < ?',
          whereArgs: [nextDayStr],
          limit: 1,
        );
        double prevBalanceForAuto = prevClosingForAuto.isNotEmpty
            ? prevClosingForAuto.first['closing_balance'] as double
            : 0.0;
        await db.insert(tableDailyClosingInfo, {
          'closing_date': nextDayStr,
          'closing_balance': prevBalanceForAuto,
          'closing_txn_id': 0,
        },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      lastClosedDate = nextDay;
    }
  }


  Future<void> closeDayForDate(DateTime day) async {
    final db = await instance.database;
    final dayStr = day.toIso8601String().substring(0, 10);

    final lastTxnQuery = await db.query(
      tableTransactions,
      where: 'date(createdAt) = ?',
      whereArgs: [dayStr],
      orderBy: 'id DESC', 
      limit: 1,
    );

    if (lastTxnQuery.isEmpty) {
        final prevClosing = await db.query(
          tableDailyClosingInfo,
          orderBy: 'closing_date DESC',
          where: 'closing_date < ?',
          whereArgs: [dayStr],
          limit: 1,
        );
        final prevBalance = prevClosing.isNotEmpty
            ? prevClosing.first['closing_balance'] as double
            : 0.0;
        
        await db.insert(tableDailyClosingInfo, {
          'closing_date': dayStr,
          'closing_balance': prevBalance, 
          'closing_txn_id': 0, 
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
        return; 
    }

    final lastTxnId = lastTxnQuery.first['id'] as int;

    final prevClosing = await db.query(
      tableDailyClosingInfo,
      orderBy: 'closing_date DESC',
      where: 'closing_date < ?', 
      whereArgs: [dayStr],
      limit: 1,
    );
    final prevBalance = prevClosing.isNotEmpty
        ? prevClosing.first['closing_balance'] as double
        : 0.0; 

    final sumResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $tableTransactions WHERE date(createdAt) = ?',
      [dayStr],
    );
    final todayTotal = (sumResult.first['total'] ?? 0.0) as double;


    final closingBalance = prevBalance + todayTotal;

    await db.insert(
      tableDailyClosingInfo,
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

    final lastClosing = await db.query(
      tableDailyClosingInfo,
      where: 'closing_date < ?',
      whereArgs: [todayStr],
      orderBy: 'closing_date DESC',
      limit: 1,
    );
    final lastBalance = lastClosing.isNotEmpty
        ? lastClosing.first['closing_balance'] as double
        : 0.0;

    final sumResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $tableTransactions WHERE date(createdAt) = ?',
      [todayStr],
    );
    final todayTotal = (sumResult.first['total'] ?? 0.0) as double;

    return lastBalance + todayTotal;
  }

  Future<void> resetDatabase() async {
    final db = await instance.database;
    final batch = db.batch();

    // Clear all data from the tables
    batch.delete(tableTransactions);
    batch.delete(tableDailyClosingInfo);

    // Reset auto-increment counters for the tables
    // This makes the next ID inserted into these tables start from 1.
    batch.rawUpdate("UPDATE sqlite_sequence SET seq = 0 WHERE name = '$tableTransactions';");
    batch.rawUpdate("UPDATE sqlite_sequence SET seq = 0 WHERE name = '$tableDailyClosingInfo';");
    // Note: If a table was empty and never had an auto-incremented ID,
    // its entry might not be in sqlite_sequence. This is generally fine.
    // The command won't error; it just won't update anything for that table.

    await batch.commit(noResult: true);
    // --- Modified Logging ---
    print('DatabaseHelper: resetDatabase EXECUTED. Tables cleared, sequences reset. DB file should NOT have been deleted by this operation.');
  }

}
