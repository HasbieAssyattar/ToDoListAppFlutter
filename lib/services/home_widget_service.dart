import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:todolist_app/core/constants/app_constants.dart';
import 'package:todolist_app/data/models/task_model.dart';

class HomeWidgetService {
  static Future<void> syncTasks(List<TaskModel> activeTasks) async {
    try {
      await HomeWidget.setAppGroupId(AppConstants.appGroupId);

      // Total count
      final activeCount = activeTasks.where((t) => t.status == TaskStatus.active).length;
      final totalCount = activeTasks.length;
      await HomeWidget.saveWidgetData<int>('active_count', activeCount);
      await HomeWidget.saveWidgetData<int>('total_count', totalCount);

      // First 3 tasks summary for simple widget preview
      final previewList = activeTasks.take(3).map((t) {
        return {
          'id': t.id,
          'title': t.title,
          'status': t.status.displayName,
          'difficulty': t.difficulty.displayName,
        };
      }).toList();

      await HomeWidget.saveWidgetData<String>('tasks_json', jsonEncode(previewList));
      if (activeTasks.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('top_task_title', activeTasks.first.title);
        await HomeWidget.saveWidgetData<String>('top_task_status', activeTasks.first.status.displayName);
      } else {
        await HomeWidget.saveWidgetData<String>('top_task_title', 'Semua tugas telah beres! 🎉');
        await HomeWidget.saveWidgetData<String>('top_task_status', 'Bagus!');
      }

      // Request native widget update
      await HomeWidget.updateWidget(
        androidName: AppConstants.androidWidgetProvider,
      );
    } catch (_) {
      // Ignore widget sync failures if running on unsupported platform or simulator
    }
  }
}
