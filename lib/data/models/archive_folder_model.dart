class ArchiveFolderModel {
  final String id;
  final String name;
  final DateTime createdAt;

  const ArchiveFolderModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ArchiveFolderModel.fromMap(Map<String, dynamic> map) {
    return ArchiveFolderModel(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
