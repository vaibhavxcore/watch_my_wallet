import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class LocalDatabase {
  static const databaseName = 'watch_my_wallet.db';
  static const databaseVersion = 1;

  final Database database;

  const LocalDatabase._(this.database);

  static Future<LocalDatabase> open({required String key}) async {
    final directory = await getDatabasesPath();
    final database = await openDatabase(
      join(directory, databaseName),
      password: key,
      version: databaseVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await _createSchema(database);
        await _seedDefaults(database);
      },
    );
    return LocalDatabase._(database);
  }

  Future<void> close() => database.close();

  static Future<void> deleteDatabase() async {
    final directory = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(directory, databaseName));
  }

  static Future<void> _createSchema(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'INR',
        opening_balance REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      )
    ''');
    await database.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced'
      )
    ''');
    await database.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL CHECK (amount > 0),
        type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
        note TEXT NOT NULL DEFAULT '',
        transaction_date TEXT NOT NULL,
        time TEXT,
        attachment_path TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pendingCreate',
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
    await database.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        amount REAL NOT NULL CHECK (amount >= 0),
        month TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pendingCreate'
      )
    ''');
    await database.execute('''
      CREATE TABLE category_budgets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL CHECK (amount >= 0),
        month TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pendingCreate',
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
    await database.execute('''
      CREATE TABLE recurring_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        transaction_id TEXT NOT NULL,
        frequency TEXT NOT NULL,
        next_occurrence TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pendingCreate',
        FOREIGN KEY (transaction_id) REFERENCES transactions (id)
      )
    ''');
    await database.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL CHECK (target_amount > 0),
        current_amount REAL NOT NULL DEFAULT 0,
        target_date TEXT,
        icon TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pendingCreate'
      )
    ''');
    await database.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE sync_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');
    await database.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX transactions_date_index ON transactions (transaction_date)',
    );
    await database.execute(
      'CREATE INDEX transactions_sync_index ON transactions (sync_status)',
    );
  }

  static Future<void> _seedDefaults(DatabaseExecutor database) async {
    final now = DateTime.now().toUtc().toIso8601String();
    const accounts = [
      ['account_cash', 'Cash'],
      ['account_bank', 'Bank Account'],
      ['account_credit_card', 'Credit Card'],
      ['account_wallet', 'Wallet'],
      ['account_savings', 'Savings Account'],
    ];
    const expenseCategories = [
      'Food',
      'Travel',
      'Shopping',
      'Bills',
      'Rent',
      'Entertainment',
      'Health',
      'Education',
      'Subscription',
      'Other',
    ];
    const incomeCategories = [
      'Salary',
      'Freelance',
      'Business',
      'Investment',
      'Gift',
      'Other',
    ];

    for (final account in accounts) {
      await database.insert('accounts', {
        'id': account[0],
        'name': account[1],
        'created_at': now,
        'updated_at': now,
      });
    }
    for (final category in expenseCategories) {
      await database.insert('categories', {
        'id': 'category_expense_${category.toLowerCase()}',
        'name': category,
        'type': 'expense',
        'is_default': 1,
        'created_at': now,
        'updated_at': now,
      });
    }
    for (final category in incomeCategories) {
      await database.insert('categories', {
        'id': 'category_income_${category.toLowerCase()}',
        'name': category,
        'type': 'income',
        'is_default': 1,
        'created_at': now,
        'updated_at': now,
      });
    }
    await database.insert('app_settings', {
      'key': 'base_currency',
      'value': 'INR',
      'updated_at': now,
    });
    await database.insert('sync_metadata', {
      'key': 'last_sync_at',
      'value': '',
    });
  }
}
