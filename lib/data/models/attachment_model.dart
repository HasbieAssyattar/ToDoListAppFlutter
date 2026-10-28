class AttachmentModel {
  final String id;
  final String taskId;
  final String filePath;
  final String fileName;
  final String fileType; // 'image' or 'file'
  final int fileSize;
  final DateTime createdAt;

  const AttachmentModel({
    required this.id,
    required this.taskId,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'file_path': filePath,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      fileType: map['file_type'] as String,
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  bool get isImage => fileType == 'image';
}
