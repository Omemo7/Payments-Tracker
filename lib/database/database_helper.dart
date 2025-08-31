import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart'; // Added for DateFormat, though not strictly necessary for query construction if using ISO strings
import '../models/transaction_model.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const String _databaseName = 'payment_tracker.db';


  static const String tableTransactions = 'transactions';
  static const String tableAccounts = 'accounts';

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
      version: 4,
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

    if (oldVersion < 3) {

      await db.execute('DROP TABLE IF EXISTS daily_closing_info');
      print('DatabaseHelper: Upgraded to V3 - Dropped daily_closing_info table');
    }


    if (oldVersion < 4) {
      // Create new accounts table
      await db.execute('''
        CREATE TABLE $tableAccounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');


      await db.execute('ALTER TABLE $tableTransactions RENAME TO ${tableTransactions}_old');

      await db.execute('''
      CREATE TABLE $tableTransactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      note TEXT,
      createdAt TEXT NOT NULL,
      accountId INTEGER NOT NULL,
      FOREIGN KEY (accountId) REFERENCES accounts(id) ON DELETE RESTRICT
    )
  ''');


      final List<Map<String, Object?>> defaultAccountCheck = await db.query(
        'accounts',
        where: 'name = ?',
        whereArgs: ['Default Account'],
      );

      int defaultAccountId;
      if (defaultAccountCheck.isEmpty) {
        defaultAccountId = await db.insert('accounts', {
          'name': 'Default Account',
        });
      } else {
        defaultAccountId = defaultAccountCheck.first['id'] as int;
      }


      await db.execute('''
    INSERT INTO $tableTransactions (id, amount, note, createdAt, accountId)
    SELECT id, amount, note, createdAt, $defaultAccountId
    FROM ${tableTransactions}_old
  ''');


      await db.execute('DROP TABLE ${tableTransactions}_old');
    }
  }


  Future _createDB(Database db, int version) async {

    await db.execute('''
      CREATE TABLE $tableAccounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');


    await db.execute('''
      CREATE TABLE $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        accountId INTEGER NOT NULL,
        FOREIGN KEY (accountId) REFERENCES $tableAccounts(id) ON DELETE RESTRICT
      )
    ''');

    await db.insert(tableAccounts, {'name': 'Default Account'});
  }



  Future<void> resetDatabase() async {
    final db = await instance.database;

    // Get all table names except sqlite internal tables
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';"
    );

    final batch = db.batch();

    for (var tableMap in tables) {
      final tableName = tableMap['name'] as String;

      // Skip any tables you might want to preserve (optional)
      if (tableName == 'some_table_to_preserve') continue;

      // Delete all rows
      batch.delete(tableName);

      // Reset auto-increment sequence
      batch.rawUpdate("UPDATE sqlite_sequence SET seq = 0 WHERE name = '$tableName';");
    }

    await batch.commit(noResult: true);

    print('DatabaseHelper: resetDatabase EXECUTED. All tables cleared, sequences reset.');
  }


}
