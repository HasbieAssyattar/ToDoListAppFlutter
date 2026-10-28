import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/core/constants/app_colors.dart';
import 'package:todolist_app/core/utils/date_formatter.dart';
import 'package:todolist_app/data/models/task_model.dart';
import 'package:todolist_app/presentation/providers/task_provider.dart';
import 'package:todolist_app/presentation/screens/detail/task_detail_screen.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    final isOverdue = DateFormatter.isOverdue(task.dueDate) && !task.isComplete;

    return Dismissible(
      key: Key(task.id),
      // Geser Kanan: Arsipkan
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.archiveSwipe,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          children: [
            Icon(Icons.archive_outlined, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'Arsipkan',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      // Geser Kiri: Hapus
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.deleteSwipe,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Hapus',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right -> Archive
          await taskProvider.archiveTask(task.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tugas "${task.title}" dipindahkan ke Arsip'),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Buka Arsip',
                  onPressed: () {
                    // Navigate to archive screen handled externally
                  },
                ),
              ),
            );
          }
          return true;
        } else {
          // Swipe Left -> Delete with confirmation
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Hapus Tugas?'),
              content: Text('Yakin ingin menghapus tugas "${task.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.deleteSwipe),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await taskProvider.deleteTask(task.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tugas "${task.title}" telah dihapus'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Undo',
                    textColor: Colors.yellowAccent,
                    onPressed: () => taskProvider.undoDelete(),
                  ),
                ),
              );
            }
            return true;
          }
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status Cycle Icon
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => taskProvider.cycleTaskStatus(task.id),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: _buildStatusIcon(task.status),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Title, Tags, Due Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: task.isComplete ? AppColors.textMuted : AppColors.textPrimary,
                          decoration: task.isComplete ? TextDecoration.lineThrough : null,
                        ),
                      ),

                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            decoration: task.isComplete ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Badges Row (Difficulty, Category, Due date, Attachments)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Kesulitan Badge
                          _buildDifficultyBadge(task.difficulty),

                          // Status Text Badge
                          _buildStatusBadge(task.status),

                          // Custom Category Chip
                          if (task.category != null && task.category!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.label_outline, size: 12, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.category!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Due Date
                          if (task.dueDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isOverdue ? AppColors.difficultyHighBg : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: isOverdue ? AppColors.difficultyHigh : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormatter.formatShort(task.dueDate),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOverdue ? AppColors.difficultyHigh : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Attachments indicator
                          if (task.attachments.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.attach_file, size: 14, color: AppColors.textSecondary),
                                Text(
                                  '${task.attachments.length}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.blank:
        return const Icon(Icons.radio_button_unchecked, color: AppColors.statusBlank, size: 24);
      case TaskStatus.active:
        return const Icon(Icons.play_circle_fill, color: AppColors.statusActive, size: 24);
      case TaskStatus.complete:
        return const Icon(Icons.check_circle, color: AppColors.statusComplete, size: 24);
    }
  }

  Widget _buildStatusBadge(TaskStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case TaskStatus.blank:
        bg = AppColors.statusBlankBg;
        fg = AppColors.statusBlank;
        break;
      case TaskStatus.active:
        bg = AppColors.statusActiveBg;
        fg = AppColors.statusActive;
        break;
      case TaskStatus.complete:
        bg = AppColors.statusCompleteBg;
        fg = AppColors.statusComplete;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.displayName,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildDifficultyBadge(TaskDifficulty diff) {
    Color bg;
    Color fg;
    switch (diff) {
      case TaskDifficulty.low:
        bg = AppColors.difficultyLowBg;
        fg = AppColors.difficultyLow;
        break;
      case TaskDifficulty.medium:
        bg = AppColors.difficultyMediumBg;
        fg = AppColors.difficultyMedium;
        break;
      case TaskDifficulty.high:
        bg = AppColors.difficultyHighBg;
        fg = AppColors.difficultyHigh;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        diff.displayName,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
