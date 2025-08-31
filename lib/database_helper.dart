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
  // static const String tableDailyClosingInfo = 'daily_closing_info'; // Removed

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
      version: 3, // <- incremented from 2 to 3
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
    // if (oldVersion < 2) { // Removed block for creating daily_closing_info
    // }

    if (oldVersion < 3) {

      await db.execute('DROP TABLE IF EXISTS daily_closing_info');
      print('DatabaseHelper: Upgraded to V3 - Dropped daily_closing_info table');
    }

    // You can handle future upgrades here:
    // if (oldVersion < 4) { ... }
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

    // Removed creation of daily_closing_info table
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

  Future<double> getTodayBalance() async {
    final db = await instance.database;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final result = await db.rawQuery('''
    SELECT SUM(amount) as balance
    FROM transactions
    WHERE DATE(createdAt) = ?
  ''', [today]);
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
    String dateString = date.toIso8601String().substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.query(
      tableTransactions,
      where: 'DATE(createdAt) = ?',
      whereArgs: [dateString],
      orderBy: 'createdAt DESC', 
    );

    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  // ---- End of Day-by-Day Pagination Methods ----

  // Methods related to daily_closing_info (autoCloseDay, closeDayForDate, getTodayBalance) have been removed.

  Future<void> resetDatabase() async {
    final db = await instance.database;
    final batch = db.batch();

    // Clear all data from the tables
    batch.delete(tableTransactions);
    // batch.delete(tableDailyClosingInfo); // Removed

    // Reset auto-increment counters for the tables
    batch.rawUpdate("UPDATE sqlite_sequence SET seq = 0 WHERE name = '$tableTransactions';");
    // batch.rawUpdate("UPDATE sqlite_sequence SET seq = 0 WHERE name = '$tableDailyClosingInfo';"); // Removed
    
    await batch.commit(noResult: true);
    print('DatabaseHelper: resetDatabase EXECUTED. Tables cleared, sequences reset.');
  }

}
