import 'package:todolist_app/data/models/attachment_model.dart';

enum TaskStatus {
  blank,
  active,
  complete;

  String get displayName {
    switch (this) {
      case TaskStatus.blank:
        return 'Draft';
      case TaskStatus.active:
        return 'Aktif';
      case TaskStatus.complete:
        return 'Selesai';
    }
  }

  static TaskStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return TaskStatus.active;
      case 'complete':
      case 'completed':
        return TaskStatus.complete;
      case 'blank':
      default:
        return TaskStatus.blank;
    }
  }
}

enum TaskDifficulty {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case TaskDifficulty.low:
        return 'Mudah';
      case TaskDifficulty.medium:
        return 'Sedang';
      case TaskDifficulty.high:
        return 'Sulit';
    }
  }

  static TaskDifficulty fromString(String value) {
    switch (value.toLowerCase()) {
      case 'medium':
        return TaskDifficulty.medium;
      case 'high':
        return TaskDifficulty.high;
      case 'low':
      default:
        return TaskDifficulty.low;
    }
  }
}

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskDifficulty difficulty;
  final String? category;
  final DateTime? dueDate;
  final bool isArchived;
  final String? archiveFolder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AttachmentModel> attachments;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.status = TaskStatus.active,
    this.difficulty = TaskDifficulty.low,
    this.category,
    this.dueDate,
    this.isArchived = false,
    this.archiveFolder,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'difficulty': difficulty.name,
      'category': category,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'is_archived': isArchived ? 1 : 0,
      'archive_folder': archiveFolder,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, {List<AttachmentModel> attachments = const []}) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: TaskStatus.fromString(map['status'] as String? ?? 'active'),
      difficulty: TaskDifficulty.fromString(map['difficulty'] as String? ?? 'low'),
      category: map['category'] as String?,
      dueDate: map['due_date'] != null ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int) : null,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      archiveFolder: map['archive_folder'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      attachments: attachments,
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskDifficulty? difficulty,
    String? category,
    DateTime? dueDate,
    bool? isArchived,
    String? archiveFolder,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AttachmentModel>? attachments,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isArchived: isArchived ?? this.isArchived,
      archiveFolder: archiveFolder ?? this.archiveFolder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
    );
  }

  bool get isComplete => status == TaskStatus.complete;
  bool get isActive => status == TaskStatus.active;
  bool get isBlank => status == TaskStatus.blank;
}
