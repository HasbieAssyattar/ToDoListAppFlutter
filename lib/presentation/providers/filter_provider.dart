import 'package:flutter/material.dart';
import 'package:todolist_app/data/models/task_model.dart';

class FilterProvider extends ChangeNotifier {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'blank', 'active', 'complete'
  String _categoryQuery = '';
  TaskDifficulty? _difficultyFilter;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get categoryQuery => _categoryQuery;
  TaskDifficulty? get difficultyFilter => _difficultyFilter;

  bool get hasActiveFilter =>
      _searchQuery.isNotEmpty ||
      _statusFilter != 'all' ||
      _categoryQuery.isNotEmpty ||
      _difficultyFilter != null;

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void setStatusFilter(String status) {
    if (_statusFilter != status) {
      _statusFilter = status;
      notifyListeners();
    }
  }

  void setCategoryQuery(String category) {
    if (_categoryQuery != category) {
      _categoryQuery = category;
      notifyListeners();
    }
  }

  void setDifficultyFilter(TaskDifficulty? difficulty) {
    if (_difficultyFilter != difficulty) {
      _difficultyFilter = difficulty;
      notifyListeners();
    }
  }

  void resetFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    _categoryQuery = '';
    _difficultyFilter = null;
    notifyListeners();
  }

  List<TaskModel> applyFilter(List<TaskModel> tasks) {
    return tasks.where((task) {
      // 1. General Search (Title and description)
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(q);
        final matchesDesc = (task.description ?? '').toLowerCase().contains(q);
        if (!matchesTitle && !matchesDesc) return false;
      }

      // 2. Status Filter
      if (_statusFilter != 'all') {
        if (task.status.name != _statusFilter) return false;
      }

      // 3. Category Filter via Textfield
      if (_categoryQuery.trim().isNotEmpty) {
        final catQ = _categoryQuery.trim().toLowerCase();
        final taskCat = (task.category ?? '').trim().toLowerCase();
        if (!taskCat.contains(catQ)) return false;
      }

      // 4. Difficulty Filter
      if (_difficultyFilter != null) {
        if (task.difficulty != _difficultyFilter) return false;
      }

      return true;
    }).toList();
  }
}
