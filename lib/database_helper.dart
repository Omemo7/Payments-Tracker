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
      version: 1,
      onCreate: _createDB,
    );
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
  Future<double> getCummulativeBalanceByTransactionId(int id) async {
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
  Future<double> getCurrentBalance() async {
    final db = await database;

    final result = await db.rawQuery('''
    SELECT SUM(amount) as balance
    FROM transactions ''');

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
}
