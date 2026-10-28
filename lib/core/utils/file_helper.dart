import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileHelper {
  static Future<String> saveFileLocally(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(docsDir.path, 'attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath);
    final uniqueName = '${const Uuid().v4()}$ext';
    final targetPath = p.join(attachmentsDir.path, uniqueName);

    final sourceFile = File(sourcePath);
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  static Future<OpenResult> openFile(String filePath) async {
    return await OpenFilex.open(filePath);
  }

  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static bool isImageFile(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(ext);
  }
}
