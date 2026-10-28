import 'package:flutter/material.dart';
import 'package:todolist_app/data/models/archive_folder_model.dart';
import 'package:todolist_app/data/models/task_model.dart';
import 'package:todolist_app/data/repositories/task_repository.dart';
import 'package:todolist_app/services/home_widget_service.dart';
import 'package:uuid/uuid.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository;

  List<TaskModel> _activeTasks = [];
  List<TaskModel> _archivedTasks = [];
  List<ArchiveFolderModel> _folders = [];
  List<String> _categories = [];
  bool _isLoading = true;

  // Undo delete cache
  TaskModel? _recentlyDeletedTask;

  TaskProvider({TaskRepository? repository}) : _repository = repository ?? TaskRepositoryImpl() {
    loadData();
  }

  List<TaskModel> get activeTasks => _activeTasks;
  List<TaskModel> get archivedTasks => _archivedTasks;
  List<ArchiveFolderModel> get folders => _folders;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  TaskModel? get recentlyDeletedTask => _recentlyDeletedTask;

  // Counts
  int get totalActiveCount => _activeTasks.where((t) => t.status == TaskStatus.active).length;
  int get totalCompleteCount => _activeTasks.where((t) => t.status == TaskStatus.complete).length;
  int get totalBlankCount => _activeTasks.where((t) => t.status == TaskStatus.blank).length;

  double get progressPercentage {
    if (_activeTasks.isEmpty) return 0.0;
    return totalCompleteCount / _activeTasks.length;
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activeTasks = await _repository.getActiveTasks();
      _archivedTasks = await _repository.getArchivedTasks();
      _folders = await _repository.getArchiveFolders();
      _categories = await _repository.getAllCategories();
      await HomeWidgetService.syncTasks(_activeTasks);
    } catch (_) {
      // Fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(TaskModel task) async {
    await _repository.addTask(task);
    _activeTasks.insert(0, task);
    if (task.category != null && task.category!.isNotEmpty && !_categories.contains(task.category)) {
      _categories.add(task.category!);
    }
    await HomeWidgetService.syncTasks(_activeTasks);
    notifyListeners();
  }

  Future<void> updateTask(TaskModel task) async {
    await _repository.updateTask(task);
    final index = _activeTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _activeTasks[index] = task;
    } else {
      final archIndex = _archivedTasks.indexWhere((t) => t.id == task.id);
      if (archIndex != -1) {
        _archivedTasks[archIndex] = task;
      }
    }
    if (task.category != null && task.category!.isNotEmpty && !_categories.contains(task.category)) {
      _categories.add(task.category!);
    }
    await HomeWidgetService.syncTasks(_activeTasks);
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    final taskIndex = _activeTasks.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      _recentlyDeletedTask = _activeTasks[taskIndex];
      _activeTasks.removeAt(taskIndex);
    } else {
      final archIndex = _archivedTasks.indexWhere((t) => t.id == id);
      if (archIndex != -1) {
        _recentlyDeletedTask = _archivedTasks[archIndex];
        _archivedTasks.removeAt(archIndex);
      }
    }

    await _repository.deleteTask(id);
    await HomeWidgetService.syncTasks(_activeTasks);
    notifyListeners();
  }

  Future<void> undoDelete() async {
    if (_recentlyDeletedTask != null) {
      final taskToRestore = _recentlyDeletedTask!;
      await _repository.addTask(taskToRestore);
      if (taskToRestore.isArchived) {
        _archivedTasks.insert(0, taskToRestore);
      } else {
        _activeTasks.insert(0, taskToRestore);
      }
      _recentlyDeletedTask = null;
      await HomeWidgetService.syncTasks(_activeTasks);
      notifyListeners();
    }
  }

  Future<void> archiveTask(String id, {String? folderName}) async {
    final index = _activeTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _activeTasks.removeAt(index);
      final archivedTask = task.copyWith(isArchived: true, archiveFolder: folderName);
      _archivedTasks.insert(0, archivedTask);
      await _repository.setArchivedStatus(id, true, folderName: folderName);
      await HomeWidgetService.syncTasks(_activeTasks);
      notifyListeners();
    }
  }

  Future<void> unarchiveTask(String id) async {
    final index = _archivedTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _archivedTasks.removeAt(index);
      final unarchivedTask = task.copyWith(isArchived: false, archiveFolder: null);
      _activeTasks.insert(0, unarchivedTask);
      await _repository.setArchivedStatus(id, false);
      await HomeWidgetService.syncTasks(_activeTasks);
      notifyListeners();
    }
  }

  Future<void> changeTaskStatus(String id, TaskStatus newStatus) async {
    final index = _activeTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final updated = _activeTasks[index].copyWith(status: newStatus, updatedAt: DateTime.now());
      _activeTasks[index] = updated;
      await _repository.updateStatus(id, newStatus);
      await HomeWidgetService.syncTasks(_activeTasks);
      notifyListeners();
    }
  }

  Future<void> cycleTaskStatus(String id) async {
    final index = _activeTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final current = _activeTasks[index].status;
      TaskStatus next;
      switch (current) {
        case TaskStatus.blank:
          next = TaskStatus.active;
          break;
        case TaskStatus.active:
          next = TaskStatus.complete;
          break;
        case TaskStatus.complete:
          next = TaskStatus.blank;
          break;
      }
      await changeTaskStatus(id, next);
    }
  }

  Future<void> clearCompletedTasks() async {
    final completedList = _activeTasks.where((t) => t.status == TaskStatus.complete).toList();
    for (final task in completedList) {
      await deleteTask(task.id);
    }
  }

  // --- Folder Management ---

  Future<void> createFolder(String name) async {
    final folder = ArchiveFolderModel(
      id: const Uuid().v4(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    await _repository.addArchiveFolder(folder);
    _folders.add(folder);
    notifyListeners();
  }

  Future<void> deleteFolder(String name) async {
    await _repository.deleteArchiveFolder(name);
    _folders.removeWhere((f) => f.name == name);
    // Refresh archived tasks to reflect unassigned folder
    _archivedTasks = await _repository.getArchivedTasks();
    notifyListeners();
  }

  Future<void> moveArchivedTaskToFolder(String taskId, String? folderName) async {
    final index = _archivedTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updated = _archivedTasks[index].copyWith(archiveFolder: folderName);
      _archivedTasks[index] = updated;
      await _repository.setArchivedStatus(taskId, true, folderName: folderName);
      notifyListeners();
    }
  }
}
