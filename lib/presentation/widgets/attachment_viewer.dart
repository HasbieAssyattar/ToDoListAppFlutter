import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:todolist_app/core/constants/app_colors.dart';
import 'package:todolist_app/core/utils/file_helper.dart';
import 'package:todolist_app/data/models/attachment_model.dart';
import 'package:uuid/uuid.dart';

class AttachmentViewerWidget extends StatelessWidget {
  final List<AttachmentModel> attachments;
  final ValueChanged<List<AttachmentModel>> onAttachmentsChanged;
  final bool isEditable;

  const AttachmentViewerWidget({
    super.key,
    required this.attachments,
    required this.onAttachmentsChanged,
    this.isEditable = true,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        final localPath = await FileHelper.saveFileLocally(picked.path);
        final file = File(localPath);
        final size = await file.length();
        final fileName = picked.name.isNotEmpty ? picked.name : 'Foto_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final newAttachment = AttachmentModel(
          id: const Uuid().v4(),
          taskId: '',
          filePath: localPath,
          fileName: fileName,
          fileType: 'image',
          fileSize: size,
          createdAt: DateTime.now(),
        );

        onAttachmentsChanged([...attachments, newAttachment]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final files = await FilePicker.pickFiles();
      if (files.isNotEmpty && files.first.path != null) {
        final path = files.first.path!;
        final localPath = await FileHelper.saveFileLocally(path);
        final file = File(localPath);
        final size = await file.length();
        final name = files.first.name;
        final isImg = FileHelper.isImageFile(name);

        final newAttachment = AttachmentModel(
          id: const Uuid().v4(),
          taskId: '',
          filePath: localPath,
          fileName: name,
          fileType: isImg ? 'image' : 'file',
          fileSize: size,
          createdAt: DateTime.now(),
        );

        onAttachmentsChanged([...attachments, newAttachment]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih file: $e')),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    final updated = List<AttachmentModel>.from(attachments)..removeAt(index);
    onAttachmentsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditable) ...[
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showImageSourceDialog(context),
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Foto', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _pickFile(context),
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Dokumen / File', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        if (attachments.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(attachments.length, (index) {
              final att = attachments[index];
              return _buildAttachmentChip(context, att, index);
            }),
          )
        else if (!isEditable)
          const Text(
            'Tidak ada lampiran file/gambar.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildAttachmentChip(BuildContext context, AttachmentModel att, int index) {
    final file = File(att.filePath);
    final exists = file.existsSync();

    return Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              if (exists) {
                FileHelper.openFile(att.filePath);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File tidak ditemukan di storage lokal')),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (att.isImage && exists)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      file,
                      height: 70,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 70,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      att.isImage ? Icons.broken_image : Icons.insert_drive_file,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  att.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  FileHelper.formatFileSize(att.fileSize),
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (isEditable)
            Positioned(
              top: -6,
              right: -6,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
                onPressed: () => _removeAttachment(index),
              ),
            ),
        ],
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
