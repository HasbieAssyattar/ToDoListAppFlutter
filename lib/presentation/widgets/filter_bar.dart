import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/core/constants/app_colors.dart';
import 'package:todolist_app/data/models/task_model.dart';
import 'package:todolist_app/presentation/providers/filter_provider.dart';

class FilterBarWidget extends StatefulWidget {
  const FilterBarWidget({super.key});

  @override
  State<FilterBarWidget> createState() => _FilterBarWidgetState();
}

class _FilterBarWidgetState extends State<FilterBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  bool _isAdvancedFilterOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<FilterProvider>();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. General Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) => filter.setSearchQuery(val),
            decoration: InputDecoration(
              hintText: 'Cari judul tugas...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        filter.setSearchQuery('');
                      },
                    )
                  : IconButton(
                      icon: Icon(
                        _isAdvancedFilterOpen ? Icons.filter_list_off : Icons.tune,
                        color: filter.hasActiveFilter ? AppColors.primary : AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isAdvancedFilterOpen = !_isAdvancedFilterOpen;
                        });
                      },
                    ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Status Chips (All, Blank, Active, Complete)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(filter, 'all', 'Semua'),
                const SizedBox(width: 8),
                _buildStatusChip(filter, 'active', 'Aktif', color: AppColors.statusActive),
                const SizedBox(width: 8),
                _buildStatusChip(filter, 'blank', 'Draft', color: AppColors.statusBlank),
                const SizedBox(width: 8),
                _buildStatusChip(filter, 'complete', 'Selesai', color: AppColors.statusComplete),
              ],
            ),
          ),

          // 3. Expandable Advanced Filter (Category textfield & Difficulty)
          if (_isAdvancedFilterOpen) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),

            // Category Filter Input Textfield
            Text(
              'Filter Berdasarkan Kategori',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _categoryController,
              onChanged: (val) => filter.setCategoryQuery(val),
              decoration: InputDecoration(
                hintText: 'Ketik kategori (misal: Kerja, Kuliah)...',
                prefixIcon: const Icon(Icons.label_outline, size: 20, color: AppColors.textSecondary),
                suffixIcon: _categoryController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _categoryController.clear();
                          filter.setCategoryQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Difficulty Filter
            Text(
              'Filter Berdasarkan Kesulitan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDifficultyChip(filter, null, 'Semua Kesulitan'),
                  const SizedBox(width: 8),
                  _buildDifficultyChip(filter, TaskDifficulty.low, 'Mudah', AppColors.difficultyLow),
                  const SizedBox(width: 8),
                  _buildDifficultyChip(filter, TaskDifficulty.medium, 'Sedang', AppColors.difficultyMedium),
                  const SizedBox(width: 8),
                  _buildDifficultyChip(filter, TaskDifficulty.high, 'Sulit', AppColors.difficultyHigh),
                ],
              ),
            ),

            if (filter.hasActiveFilter) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _categoryController.clear();
                    filter.resetFilters();
                  },
                  icon: const Icon(Icons.refresh, size: 16, color: AppColors.deleteSwipe),
                  label: const Text('Reset Semua Filter', style: TextStyle(color: AppColors.deleteSwipe, fontSize: 12)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(FilterProvider filter, String statusKey, String label, {Color? color}) {
    final isSelected = filter.statusFilter == statusKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => filter.setStatusFilter(statusKey),
      selectedColor: color?.withValues(alpha: 0.15) ?? AppColors.primaryLight,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? (color ?? AppColors.primary) : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? (color ?? AppColors.primary) : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildDifficultyChip(FilterProvider filter, TaskDifficulty? diff, String label, [Color? color]) {
    final isSelected = filter.difficultyFilter == diff;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => filter.setDifficultyFilter(diff),
      selectedColor: color?.withValues(alpha: 0.15) ?? AppColors.primaryLight,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? (color ?? AppColors.primary) : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? (color ?? AppColors.primary) : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
