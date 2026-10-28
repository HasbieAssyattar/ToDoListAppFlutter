import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/core/constants/app_colors.dart';
import 'package:todolist_app/core/constants/app_constants.dart';
import 'package:todolist_app/presentation/providers/filter_provider.dart';
import 'package:todolist_app/presentation/providers/task_provider.dart';
import 'package:todolist_app/presentation/screens/archive/archive_screen.dart';
import 'package:todolist_app/presentation/screens/form/task_form_screen.dart';
import 'package:todolist_app/presentation/widgets/filter_bar.dart';
import 'package:todolist_app/presentation/widgets/task_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final filterProvider = context.watch<FilterProvider>();

    final filteredTasks = filterProvider.applyFilter(taskProvider.activeTasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          // Archive Button with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Buka Arsip',
                icon: const Icon(Icons.archive_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ArchiveScreen()),
                  );
                },
              ),
              if (taskProvider.archivedTasks.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${taskProvider.archivedTasks.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Hapus Tugas Selesai',
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: taskProvider.totalCompleteCount > 0
                ? () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Bersihkan Tugas Selesai?'),
                        content: Text(
                          'Yakin ingin menghapus ${taskProvider.totalCompleteCount} tugas yang telah selesai?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Bersihkan'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await taskProvider.clearCompletedTasks();
                    }
                  }
                : null,
          ),
        ],
      ),
      body: taskProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Progress Summary Header
                _buildProgressSummary(taskProvider),

                // 2. Filter Bar (Search + Multi criteria)
                const FilterBarWidget(),

                // 3. Task List
                Expanded(
                  child: filteredTasks.isEmpty
                      ? _buildEmptyState(filterProvider.hasActiveFilter)
                      : RefreshIndicator(
                          onRefresh: () => taskProvider.loadData(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              return TaskCard(task: filteredTasks[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah Tugas',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildProgressSummary(TaskProvider provider) {
    final activeCount = provider.totalActiveCount;
    final completeCount = provider.totalCompleteCount;
    final blankCount = provider.totalBlankCount;
    final progress = provider.progressPercentage;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres Hari Ini',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              Text(
                '${(progress * 100).toInt()}% Selesai',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Aktif', '$activeCount', AppColors.statusActive),
              _buildStatItem('Draft', '$blankCount', AppColors.statusBlank),
              _buildStatItem('Selesai', '$completeCount', AppColors.statusComplete),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool hasFilter) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilter ? Icons.search_off : Icons.check_circle_outline,
              size: 72,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'Tidak ada tugas yang cocok'
                  : 'Belum ada tugas!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Coba sesuaikan kata kunci atau reset filter pencarian.'
                  : 'Ketuk tombol "+" di bawah untuk mencatat tugas pertamamu.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
