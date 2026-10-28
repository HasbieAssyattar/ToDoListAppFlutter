import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/core/constants/app_colors.dart';
import 'package:todolist_app/core/constants/app_constants.dart';
import 'package:todolist_app/core/utils/date_formatter.dart';
import 'package:todolist_app/data/models/attachment_model.dart';
import 'package:todolist_app/data/models/task_model.dart';
import 'package:todolist_app/presentation/providers/task_provider.dart';
import 'package:todolist_app/presentation/widgets/attachment_viewer.dart';
import 'package:uuid/uuid.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskModel? existingTask;

  const TaskFormScreen({super.key, this.existingTask});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;

  late TaskStatus _selectedStatus;
  late TaskDifficulty _selectedDifficulty;
  DateTime? _selectedDueDate;
  List<AttachmentModel> _attachments = [];

  bool get isEditMode => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _categoryController = TextEditingController(text: task?.category ?? '');
    _selectedStatus = task?.status ?? TaskStatus.active;
    _selectedDifficulty = task?.difficulty ?? TaskDifficulty.low;
    _selectedDueDate = task?.dueDate;
    _attachments = task?.attachments != null ? List.from(task!.attachments) : [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDueDate ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDueDate != null
            ? TimeOfDay(hour: _selectedDueDate!.hour, minute: _selectedDueDate!.minute)
            : const TimeOfDay(hour: 12, minute: 0),
      );

      setState(() {
        if (pickedTime != null) {
          _selectedDueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        } else {
          _selectedDueDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 23, 59);
        }
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final taskProvider = context.read<TaskProvider>();
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final category = _categoryController.text.trim();

    final now = DateTime.now();
    final taskId = isEditMode ? widget.existingTask!.id : const Uuid().v4();

    // Attach taskId to all attachments
    final updatedAttachments = _attachments.map((a) {
      return AttachmentModel(
        id: a.id,
        taskId: taskId,
        filePath: a.filePath,
        fileName: a.fileName,
        fileType: a.fileType,
        fileSize: a.fileSize,
        createdAt: a.createdAt,
      );
    }).toList();

    final task = TaskModel(
      id: taskId,
      title: title,
      description: desc.isNotEmpty ? desc : null,
      status: _selectedStatus,
      difficulty: _selectedDifficulty,
      category: category.isNotEmpty ? category : null,
      dueDate: _selectedDueDate,
      isArchived: widget.existingTask?.isArchived ?? false,
      archiveFolder: widget.existingTask?.archiveFolder,
      createdAt: widget.existingTask?.createdAt ?? now,
      updatedAt: now,
      attachments: updatedAttachments,
    );

    if (isEditMode) {
      await taskProvider.updateTask(task);
    } else {
      await taskProvider.addTask(task);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode ? 'Tugas berhasil diperbarui!' : 'Tugas berhasil ditambahkan!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final allCategorySuggestions = {
      ...AppConstants.defaultCategorySuggestions,
      ...taskProvider.categories,
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Tugas' : 'Tambah Tugas Baru'),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Judul
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Tugas *',
                hintText: 'Apa yang ingin kamu kerjakan?',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Judul tugas tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 2. Deskripsi
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi / Catatan',
                hintText: 'Tambahkan rincian atau catatan tugas...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // 3. Status Tugas (3 Status: Blank, Active, Complete)
            const Text(
              'Status Tugas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusOption(TaskStatus.active, AppColors.statusActive),
                const SizedBox(width: 8),
                _buildStatusOption(TaskStatus.blank, AppColors.statusBlank),
                const SizedBox(width: 8),
                _buildStatusOption(TaskStatus.complete, AppColors.statusComplete),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Kesulitan (Difficulty: Low, Medium, High)
            const Text(
              'Tingkat Kesulitan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDifficultyOption(TaskDifficulty.low, AppColors.difficultyLow),
                const SizedBox(width: 8),
                _buildDifficultyOption(TaskDifficulty.medium, AppColors.difficultyMedium),
                const SizedBox(width: 8),
                _buildDifficultyOption(TaskDifficulty.high, AppColors.difficultyHigh),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Kategori Bebas Ketik (Custom Textfield with Suggestions)
            const Text(
              'Kategori (Bebas Ketik)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                hintText: 'Ketik nama kategori baru atau pilih di bawah...',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allCategorySuggestions.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        setState(() {
                          _categoryController.text = cat;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // 6. Tenggat Waktu (Due Date Picker)
            const Text(
              'Tenggat Waktu (Due Date)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDueDate != null
                            ? DateFormatter.formatFull(_selectedDueDate)
                            : 'Pilih batas waktu pengerjaan...',
                        style: TextStyle(
                          color: _selectedDueDate != null ? AppColors.textPrimary : AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_selectedDueDate != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedDueDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 7. Lampiran Gambar & File pada Deskripsi
            const Text(
              'Lampiran (Gambar & File)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            AttachmentViewerWidget(
              attachments: _attachments,
              onAttachmentsChanged: (updated) {
                setState(() {
                  _attachments = updated;
                });
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(TaskStatus status, Color color) {
    final isSelected = _selectedStatus == status;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(status.displayName)),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedStatus = status;
          });
        },
        selectedColor: color.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          color: isSelected ? color : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        side: BorderSide(color: isSelected ? color : AppColors.border),
      ),
    );
  }

  Widget _buildDifficultyOption(TaskDifficulty diff, Color color) {
    final isSelected = _selectedDifficulty == diff;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(diff.displayName)),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedDifficulty = diff;
          });
        },
        selectedColor: color.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          color: isSelected ? color : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        side: BorderSide(color: isSelected ? color : AppColors.border),
      ),
    );
  }
}
