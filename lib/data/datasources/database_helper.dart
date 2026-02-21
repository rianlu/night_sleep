import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:night_sleep/core/constants/app_constants.dart';
import 'package:night_sleep/data/models/category_item.dart';
import 'package:night_sleep/data/models/video_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
    try {
      await _ensureSchema(db);
    } catch (_) {
      // Keep startup resilient if migration check fails in edge environments.
    }
    return db;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableVideos} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        coverUrl TEXT NOT NULL,
        duration INTEGER NOT NULL,
        skipEnd INTEGER NOT NULL,
        startTime INTEGER NOT NULL DEFAULT 0,
        endTime INTEGER,
        filePath TEXT,
        cid TEXT,
        page INTEGER,
        category TEXT,
        addedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sortOrder INTEGER NOT NULL
      )
    ''');

    // 插入默认分类
    final defaultCategories = ["默认", "电台", "白噪音", "科普", "有声书", "冥想"];
    for (int i = 0; i < defaultCategories.length; i++) {
        await db.insert('categories', {
          'id': DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          'name': defaultCategories[i],
          'sortOrder': i,
        });
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加开始时间列，默认为0
      await db.execute('ALTER TABLE ${AppConstants.tableVideos} ADD COLUMN startTime INTEGER NOT NULL DEFAULT 0');
      // 添加结束时间列，可以为空（模型中会默认为总时长）
      await db.execute('ALTER TABLE ${AppConstants.tableVideos} ADD COLUMN endTime INTEGER');
      // 添加CID列，用于加速音频解析
      await db.execute('ALTER TABLE ${AppConstants.tableVideos} ADD COLUMN cid TEXT');
      // 添加分P页码
      await db.execute('ALTER TABLE ${AppConstants.tableVideos} ADD COLUMN page INTEGER');
      // 添加Category列
      await db.execute('ALTER TABLE ${AppConstants.tableVideos} ADD COLUMN category TEXT');
    }

    if (oldVersion < 3) {
       await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          sortOrder INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> _ensureSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sortOrder INTEGER NOT NULL
      )
    ''');

    // 防御性迁移：处理旧版本安装（数据库版本未更新但字段变更的情况）
    final columns = await db.rawQuery('PRAGMA table_info(${AppConstants.tableVideos})');
    final columnNames = columns.map((c) => c['name'] as String).toSet();

    if (!columnNames.contains('startTime')) {
      await db.execute('ALTER TABLE ${AppConstants.tableVideos} ADD COLUMN startTime INTEGER NOT NULL DEFAULT 0');
    }
    if (!columnNames.contains('endTime')) {
      await db.execute('ALTER TABLE ${AppConstants.tableVideos} ADD COLUMN endTime INTEGER');
    }
    if (!columnNames.contains('cid')) {
      await db.execute('ALTER TABLE ${AppConstants.tableVideos} ADD COLUMN cid TEXT');
    }
    if (!columnNames.contains('page')) {
      await db.execute('ALTER TABLE ${AppConstants.tableVideos} ADD COLUMN page INTEGER');
    }
    if (!columnNames.contains('category')) {
      await db.execute('ALTER TABLE ${AppConstants.tableVideos} ADD COLUMN category TEXT');
    }

    // 确保默认分类存在
    final existing = await db.query('categories', columns: ['name'], where: 'name = ?', whereArgs: ['默认']);
    if (existing.isEmpty) {
      await db.insert('categories', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': '默认',
        'sortOrder': 0,
      });
    }

    // --- 数据重灾区修复：迁移 NULL 或 孤立的分类 ---
    // 1. 将所有 NULL 或 空字符串分类归为 "默认"
    await db.update(
      AppConstants.tableVideos,
      {'category': '默认'},
      where: 'category IS NULL OR category = ?',
      whereArgs: [''],
    );

    // 2. 将之前可能存在的 "全部" 分类迁移为 "默认"
    await db.update(
      AppConstants.tableVideos,
      {'category': '默认'},
      where: 'category = ?',
      whereArgs: ['全部'],
    );
    
    // 3. 移除旧版本的“全部”分类（如果存在）
    await db.delete('categories', where: 'name = ?', whereArgs: ['全部']);
  }

  Future<VideoItem> create(VideoItem video) async {
    final db = await database;
    await db.insert(
      AppConstants.tableVideos, 
      video.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return video;
  }

  Future<VideoItem?> read(String id) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableVideos,
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return VideoItem.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<VideoItem>> readAllVideos() async {
    final db = await database;
    final orderBy = 'addedAt DESC'; // 最近添加的排在前面
    final result = await db.query(AppConstants.tableVideos, orderBy: orderBy);

    return result.map((json) => VideoItem.fromMap(json)).toList();
  }

  Future<int> update(VideoItem video) async {
    final db = await database;
    return await db.update(
      AppConstants.tableVideos,
      video.toMap(),
      where: 'id = ?',
      whereArgs: [video.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await database;
    return await db.delete(
      AppConstants.tableVideos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 分类相关方法
  Future<List<CategoryItem>> readAllCategories() async {
    final db = await database;
    final result = await db.query(AppConstants.tableCategories, orderBy: 'sortOrder ASC');
    return result.map((json) => CategoryItem.fromMap(json)).toList();
  }

  Future<int> updateCategory(CategoryItem category) async {
    final db = await database;
    return await db.update(
      AppConstants.tableCategories,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> renameCategory(CategoryItem category, String oldName) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Update category name
      await txn.update(
        AppConstants.tableCategories,
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
      // 2. Update all videos belonging to this category
      await txn.update(
        AppConstants.tableVideos,
        {'category': category.name},
        where: 'category = ?',
        whereArgs: [oldName],
      );
    });
  }

  Future<void> deleteCategory(String id, String categoryName) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Move items to "默认"
      await txn.update(
        AppConstants.tableVideos,
        {'category': '默认'},
        where: 'category = ?',
        whereArgs: [categoryName],
      );
      // 2. Delete the category
      await txn.delete(
        AppConstants.tableCategories,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> createCategory(CategoryItem category) async {
    final db = await database;
    await db.insert(AppConstants.tableCategories, category.toMap());
  }

  Future<void> updateCategoryOrder(List<CategoryItem> categories) async {
    final db = await database;
    await db.transaction((txn) async {
      for (int i = 0; i < categories.length; i++) {
        await txn.update(
          AppConstants.tableCategories,
          {'sortOrder': i},
          where: 'id = ?',
          whereArgs: [categories[i].id],
        );
      }
    });
  }

  Future<List<VideoItem>> readVideosByCategory(String categoryName) async {
    final db = await database;
    final result = await db.query(
      AppConstants.tableVideos,
      where: 'category = ?',
      whereArgs: [categoryName],
      orderBy: 'addedAt DESC',
    );
    return result.map((json) => VideoItem.fromMap(json)).toList();
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
