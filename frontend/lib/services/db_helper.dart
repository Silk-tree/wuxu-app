import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'database_factory_initializer.dart';

class DbHelper {
  static const String _databaseName = 'wuxu.db';
  static const int _databaseVersion = 1;

  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    initializeDatabaseFactory();
    final path = usesWebDatabaseFactory
        ? _databaseName
        : join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // 创建 items 表
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit TEXT NOT NULL DEFAULT '',
        expiry_date TEXT NOT NULL,
        storage_location TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'safe',
        notes TEXT NOT NULL DEFAULT '',
        device_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 创建 categories 表
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT '📦',
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 插入默认分类
    await _insertDefaultCategories(db);
  }

  static Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      {'id': 'cat_food', 'name': '食品', 'icon': '🍎', 'sort_order': 1},
      {'id': 'cat_daily', 'name': '日用品', 'icon': '🧴', 'sort_order': 2},
      {'id': 'cat_medicine', 'name': '药品', 'icon': '💊', 'sort_order': 3},
      {'id': 'cat_other', 'name': '其他', 'icon': '📦', 'sort_order': 4},
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
