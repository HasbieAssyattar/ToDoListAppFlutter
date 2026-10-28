class AppConstants {
  static const String appName = 'To-Do List';
  
  // Database
  static const String databaseName = 'todolist_pro.db';
  static const int databaseVersion = 1;

  // Tables
  static const String tableTasks = 'tasks';
  static const String tableAttachments = 'attachments';
  static const String tableArchiveFolders = 'archive_folders';

  // Home Widget
  static const String appGroupId = 'group.com.hasbi.todolist_app';
  static const String androidWidgetProvider = 'TodoWidgetProvider';

  // Default Categories Suggestions
  static const List<String> defaultCategorySuggestions = [
    'Pekerjaan',
    'Pribadi',
    'Kuliah / Belajar',
    'Keluarga',
    'Keuangan',
    'Kesehatan',
    'Proyek',
  ];
}
