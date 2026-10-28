import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:todolist_app/core/constants/app_constants.dart';
import 'package:todolist_app/data/models/archive_folder_model.dart';
import 'package:todolist_app/data/models/attachment_model.dart';
import 'package:todolist_app/data/models/task_model.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onConfigure: _configureDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tasks Table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTasks} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        category TEXT,
        due_date INTEGER,
        is_archived INTEGER NOT NULL DEFAULT 0,
        archive_folder TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 2. Attachments Table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableAttachments} (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_type TEXT NOT NULL,
        file_size INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (task_id) REFERENCES ${AppConstants.tableTasks} (id) ON DELETE CASCADE
      )
    ''');

    // 3. Archive Folders Table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableArchiveFolders} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL
      )
    ''');

    // Indices for performance
    await db.execute('CREATE INDEX idx_tasks_status ON ${AppConstants.tableTasks} (status)');
    await db.execute('CREATE INDEX idx_tasks_archived ON ${AppConstants.tableTasks} (is_archived)');
    await db.execute('CREATE INDEX idx_tasks_category ON ${AppConstants.tableTasks} (category)');
    await db.execute('CREATE INDEX idx_attachments_task_id ON ${AppConstants.tableAttachments} (task_id)');
  }

  // --- CRUD TASKS ---

  Future<void> insertTask(TaskModel task) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        AppConstants.tableTasks,
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final att in task.attachments) {
        await txn.insert(
          AppConstants.tableAttachments,
          att.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> updateTask(TaskModel task) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        AppConstants.tableTasks,
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );

      // Re-sync attachments: delete existing, insert current
      await txn.delete(
        AppConstants.tableAttachments,
        where: 'task_id = ?',
        whereArgs: [task.id],
      );

      for (final att in task.attachments) {
        await txn.insert(
          AppConstants.tableAttachments,
          att.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      AppConstants.tableTasks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TaskModel>> getTasks({required bool isArchived, String? archiveFolder}) async {
    final db = await database;
    String whereClause = 'is_archived = ?';
    List<dynamic> whereArgs = [isArchived ? 1 : 0];

    if (isArchived && archiveFolder != null && archiveFolder.isNotEmpty) {
      whereClause += ' AND archive_folder = ?';
      whereArgs.add(archiveFolder);
    }

    final taskMaps = await db.query(
      AppConstants.tableTasks,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    final List<TaskModel> result = [];
    for (final map in taskMaps) {
      final taskId = map['id'] as String;
      final attMaps = await db.query(
        AppConstants.tableAttachments,
        where: 'task_id = ?',
        whereArgs: [taskId],
      );
      final attachments = attMaps.map((a) => AttachmentModel.fromMap(a)).toList();
      result.add(TaskModel.fromMap(map, attachments: attachments));
    }

    return result;
  }

  Future<TaskModel?> getTaskById(String id) async {
    final db = await database;
    final taskMaps = await db.query(
      AppConstants.tableTasks,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (taskMaps.isEmpty) return null;

    final attMaps = await db.query(
      AppConstants.tableAttachments,
      where: 'task_id = ?',
      whereArgs: [id],
    );
    final attachments = attMaps.map((a) => AttachmentModel.fromMap(a)).toList();
    return TaskModel.fromMap(taskMaps.first, attachments: attachments);
  }

  Future<void> setArchivedStatus(String id, bool isArchived, {String? folderName}) async {
    final db = await database;
    await db.update(
      AppConstants.tableTasks,
      {
        'is_archived': isArchived ? 1 : 0,
        'archive_folder': isArchived ? folderName : null,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateStatus(String id, TaskStatus status) async {
    final db = await database;
    await db.update(
      AppConstants.tableTasks,
      {
        'status': status.name,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getAllCategories() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM ${AppConstants.tableTasks} WHERE category IS NOT NULL AND category != ""',
    );
    return result.map((r) => r['category'] as String).toList();
  }

  // --- ARCHIVE FOLDERS ---

  Future<List<ArchiveFolderModel>> getArchiveFolders() async {
    final db = await database;
    final maps = await db.query(AppConstants.tableArchiveFolders, orderBy: 'name ASC');
    return maps.map((m) => ArchiveFolderModel.fromMap(m)).toList();
  }

  Future<void> insertArchiveFolder(ArchiveFolderModel folder) async {
    final db = await database;
    await db.insert(
      AppConstants.tableArchiveFolders,
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> deleteArchiveFolder(String name) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        AppConstants.tableArchiveFolders,
        where: 'name = ?',
        whereArgs: [name],
      );
      // Unassign folder from tasks in that folder
      await txn.update(
        AppConstants.tableTasks,
        {'archive_folder': null},
        where: 'archive_folder = ?',
        whereArgs: [name],
      );
    });
  }
}
