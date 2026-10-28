import 'package:todolist_app/data/database/app_database.dart';
import 'package:todolist_app/data/models/archive_folder_model.dart';
import 'package:todolist_app/data/models/task_model.dart';

abstract class TaskRepository {
  Future<List<TaskModel>> getActiveTasks();
  Future<List<TaskModel>> getArchivedTasks({String? folderName});
  Future<TaskModel?> getTaskById(String id);
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<void> setArchivedStatus(String id, bool isArchived, {String? folderName});
  Future<void> updateStatus(String id, TaskStatus status);
  Future<List<String>> getAllCategories();
  Future<List<ArchiveFolderModel>> getArchiveFolders();
  Future<void> addArchiveFolder(ArchiveFolderModel folder);
  Future<void> deleteArchiveFolder(String name);
}

class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _db;

  TaskRepositoryImpl({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  @override
  Future<List<TaskModel>> getActiveTasks() async {
    return await _db.getTasks(isArchived: false);
  }

  @override
  Future<List<TaskModel>> getArchivedTasks({String? folderName}) async {
    return await _db.getTasks(isArchived: true, archiveFolder: folderName);
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    return await _db.getTaskById(id);
  }

  @override
  Future<void> addTask(TaskModel task) async {
    await _db.insertTask(task);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await _db.updateTask(task);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
  }

  @override
  Future<void> setArchivedStatus(String id, bool isArchived, {String? folderName}) async {
    await _db.setArchivedStatus(id, isArchived, folderName: folderName);
  }

  @override
  Future<void> updateStatus(String id, TaskStatus status) async {
    await _db.updateStatus(id, status);
  }

  @override
  Future<List<String>> getAllCategories() async {
    return await _db.getAllCategories();
  }

  @override
  Future<List<ArchiveFolderModel>> getArchiveFolders() async {
    return await _db.getArchiveFolders();
  }

  @override
  Future<void> addArchiveFolder(ArchiveFolderModel folder) async {
    await _db.insertArchiveFolder(folder);
  }

  @override
  Future<void> deleteArchiveFolder(String name) async {
    await _db.deleteArchiveFolder(name);
  }
}
