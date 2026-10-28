import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/core/constants/app_colors.dart';
import 'package:todolist_app/core/utils/date_formatter.dart';
import 'package:todolist_app/data/models/task_model.dart';
import 'package:todolist_app/presentation/providers/task_provider.dart';
import 'package:todolist_app/presentation/screens/detail/task_detail_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String? _selectedFolder; // null means 'Semua'

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Folder / Label Arsip'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama folder (misal: Kuliah, Project X)...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await context.read<TaskProvider>().createFolder(name);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  void _showMoveToFolderDialog(BuildContext context, TaskModel task) {
    final taskProvider = context.read<TaskProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Pindahkan ke Folder / Label', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.folder_off_outlined),
                title: const Text('Tanpa Folder'),
                onTap: () {
                  taskProvider.moveArchivedTaskToFolder(task.id, null);
                  Navigator.pop(ctx);
                },
              ),
              ...taskProvider.folders.map((f) {
                return ListTile(
                  leading: const Icon(Icons.folder_outlined, color: AppColors.primary),
                  title: Text(f.name),
                  trailing: task.archiveFolder == f.name ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    taskProvider.moveArchivedTaskToFolder(task.id, f.name);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final folders = taskProvider.folders;

    // Filter by selected folder
    final archivedTasks = taskProvider.archivedTasks.where((t) {
      if (_selectedFolder == null) return true;
      return t.archiveFolder == _selectedFolder;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arsip Tugas'),
        actions: [
          IconButton(
            tooltip: 'Tambah Folder',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _showCreateFolderDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Folder / Label Filter Chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Semua Arsip'),
                    selected: _selectedFolder == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedFolder = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...folders.map((folder) {
                    final isSelected = _selectedFolder == folder.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        label: Text(folder.name),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedFolder = isSelected ? null : folder.name;
                          });
                        },
                        onDeleted: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Hapus Folder?'),
                              content: Text('Yakin ingin menghapus folder "${folder.name}"? Tugas di dalamnya tidak akan terhapus.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            if (_selectedFolder == folder.name) {
                              setState(() {
                                _selectedFolder = null;
                              });
                            }
                            await taskProvider.deleteFolder(folder.name);
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // 2. Archived Tasks List
          Expanded(
            child: archivedTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.archive_outlined, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFolder != null
                              ? 'Folder "$_selectedFolder" masih kosong'
                              : 'Tidak ada tugas yang diarsipkan',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Geser kartu tugas ke kanan di layar utama untuk mengarsipkan.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: archivedTasks.length,
                    itemBuilder: (context, index) {
                      final task = archivedTasks[index];
                      return Card(
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
                                const Icon(Icons.archive, color: AppColors.archiveSwipe, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      if (task.description != null && task.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          task.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (task.archiveFolder != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryLight,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '📁 ${task.archiveFolder}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          if (task.category != null && task.category!.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceVariant,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                task.category!,
                                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                              ),
                                            ),
                                          if (task.dueDate != null)
                                            Text(
                                              DateFormatter.formatShort(task.dueDate),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Action Menu (Restore, Move Folder, Delete)
                                PopupMenuButton<String>(
                                  onSelected: (val) async {
                                    if (val == 'restore') {
                                      await taskProvider.unarchiveTask(task.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Tugas "${task.title}" dipulihkan ke Beranda')),
                                        );
                                      }
                                    } else if (val == 'folder') {
                                      _showMoveToFolderDialog(context, task);
                                    } else if (val == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Hapus Permanen?'),
                                          content: Text('Hapus tugas "${task.title}" selamanya dari arsip?'),
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
                                      }
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'restore',
                                      child: Row(
                                        children: [
                                          Icon(Icons.unarchive_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Pulihkan ke Beranda'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'folder',
                                      child: Row(
                                        children: [
                                          Icon(Icons.drive_file_move_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Pindahkan Folder'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 18, color: AppColors.deleteSwipe),
                                          SizedBox(width: 8),
                                          Text('Hapus Permanen', style: TextStyle(color: AppColors.deleteSwipe)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
