import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/core/constants/app_colors.dart';
import 'package:todolist_app/core/utils/date_formatter.dart';
import 'package:todolist_app/core/utils/file_helper.dart';
import 'package:todolist_app/data/models/attachment_model.dart';
import 'package:todolist_app/data/models/task_model.dart';
import 'package:todolist_app/presentation/providers/task_provider.dart';
import 'package:todolist_app/presentation/screens/form/task_form_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    // Search in active or archived
    final task = taskProvider.activeTasks.cast<TaskModel?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => taskProvider.archivedTasks.cast<TaskModel?>().firstWhere(
                (t) => t?.id == taskId,
                orElse: () => null,
              ),
        );

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tugas')),
        body: const Center(child: Text('Tugas tidak ditemukan atau telah dihapus.')),
      );
    }

    final isOverdue = DateFormatter.isOverdue(task.dueDate) && !task.isComplete;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        actions: [
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Tugas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskFormScreen(existingTask: task),
                ),
              );
            },
          ),
          // More Menu (Archive, Delete)
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'archive') {
                if (task.isArchived) {
                  await taskProvider.unarchiveTask(task.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tugas dipulihkan dari Arsip')),
                    );
                  }
                } else {
                  await taskProvider.archiveTask(task.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tugas dipindahkan ke Arsip')),
                    );
                    Navigator.pop(context);
                  }
                }
              } else if (val == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Tugas?'),
                    content: Text('Yakin ingin menghapus tugas "${task.title}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
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
                      const SnackBar(content: Text('Tugas berhasil dihapus')),
                    );
                    Navigator.pop(context);
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(task.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(task.isArchived ? 'Pulihkan dari Arsip' : 'Arsipkan Tugas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.deleteSwipe, size: 20),
                    SizedBox(width: 8),
                    Text('Hapus Tugas', style: TextStyle(color: AppColors.deleteSwipe)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Status Bar & Cycle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusPill(task.status),
              OutlinedButton.icon(
                onPressed: () => taskProvider.cycleTaskStatus(task.id),
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Ubah Status', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Title
          Text(
            task.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: task.isComplete ? AppColors.textMuted : AppColors.textPrimary,
              decoration: task.isComplete ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 16),

          // 3. Metadata Card (Kesulitan, Kategori, Tenggat Waktu)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildMetaRow(
                  icon: Icons.speed_outlined,
                  label: 'Kesulitan',
                  valueWidget: _buildDifficultyBadge(task.difficulty),
                ),
                const Divider(height: 20, color: AppColors.borderLight),
                _buildMetaRow(
                  icon: Icons.label_outline,
                  label: 'Kategori',
                  valueWidget: Text(
                    task.category?.isNotEmpty == true ? task.category! : 'Tanpa Kategori',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                const Divider(height: 20, color: AppColors.borderLight),
                _buildMetaRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Tenggat Waktu',
                  valueWidget: Text(
                    task.dueDate != null ? DateFormatter.formatFull(task.dueDate) : 'Tidak diatur',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isOverdue ? AppColors.difficultyHigh : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (task.isArchived && task.archiveFolder != null) ...[
                  const Divider(height: 20, color: AppColors.borderLight),
                  _buildMetaRow(
                    icon: Icons.folder_outlined,
                    label: 'Folder Arsip',
                    valueWidget: Text(
                      task.archiveFolder!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Deskripsi
          const Text(
            'Deskripsi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              task.description?.isNotEmpty == true
                  ? task.description!
                  : 'Tidak ada deskripsi tambahan.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: task.description?.isNotEmpty == true ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 5. Lampiran Gambar & File
          const Text(
            'Lampiran File & Foto',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          if (task.attachments.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Tidak ada file atau gambar yang dilampirkan.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            )
          else ...[
            // Photo Gallery Section
            if (task.attachments.any((a) => a.isImage)) ...[
              const Text('Foto / Gambar:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: task.attachments.where((a) => a.isImage).map((att) {
                    final file = File(att.filePath);
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showFullscreenImage(context, att),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: file.existsSync()
                              ? Image.file(file, width: 110, height: 110, fit: BoxFit.cover)
                              : Container(
                                  width: 110,
                                  height: 110,
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Files Section
            if (task.attachments.any((a) => !a.isImage)) ...[
              const Text('Dokumen & File:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Column(
                children: task.attachments.where((a) => !a.isImage).map((att) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary),
                      title: Text(att.fileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(FileHelper.formatFileSize(att.fileSize), style: const TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textSecondary),
                      onTap: () => FileHelper.openFile(att.filePath),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMetaRow({required IconData icon, required String label, required Widget valueWidget}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        valueWidget,
      ],
    );
  }

  Widget _buildStatusPill(TaskStatus status) {
    Color bg;
    Color fg;
    IconData icon;
    switch (status) {
      case TaskStatus.blank:
        bg = AppColors.statusBlankBg;
        fg = AppColors.statusBlank;
        icon = Icons.radio_button_unchecked;
        break;
      case TaskStatus.active:
        bg = AppColors.statusActiveBg;
        fg = AppColors.statusActive;
        icon = Icons.play_circle_fill;
        break;
      case TaskStatus.complete:
        bg = AppColors.statusCompleteBg;
        fg = AppColors.statusComplete;
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(status.displayName, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        diff.displayName,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, AttachmentModel att) {
    final file = File(att.filePath);
    if (!file.existsSync()) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(file),
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
