import 'package:flutter_test/flutter_test.dart';
import 'package:todolist_app/data/models/task_model.dart';

void main() {
  test('TaskModel serialization test', () {
    final now = DateTime.now();
    final task = TaskModel(
      id: 'test-1',
      title: 'Belajar Flutter SDD',
      description: 'Latihan membuat aplikasi to-do list',
      status: TaskStatus.active,
      difficulty: TaskDifficulty.medium,
      category: 'Kuliah',
      createdAt: now,
      updatedAt: now,
    );

    final map = task.toMap();
    expect(map['title'], 'Belajar Flutter SDD');
    expect(map['status'], 'active');
    expect(map['difficulty'], 'medium');
    expect(map['category'], 'Kuliah');

    final reconstructed = TaskModel.fromMap(map);
    expect(reconstructed.id, 'test-1');
    expect(reconstructed.title, 'Belajar Flutter SDD');
    expect(reconstructed.status, TaskStatus.active);
    expect(reconstructed.difficulty, TaskDifficulty.medium);
  });
}
