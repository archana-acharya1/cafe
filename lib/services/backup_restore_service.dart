import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// If your app saves item images inside app documents, put them in this folder.
/// We'll include/extract it in backups. If you don't use images, you can leave it null.
const String? kImagesFolderName = 'images';

class BackupRestoreService {
  /// Creates a ZIP containing:
  /// - every *.hive file under the app documents directory
  /// - the optional /images folder (if it exists)
  /// Writes it to .../Documents/backups/deskgoo_cafe_backup_YYYYMMDD_HHMMSS.zip
  /// Returns the backup File.
  static Future<File> backupAllHive({bool shareAfterCreate = true}) async {

    await _flushAllOpenBoxes();

    final docsDir = await getApplicationDocumentsDirectory();
    final backupsDir = Directory(p.join(docsDir.path, 'backups'));
    if (!backupsDir.existsSync()) backupsDir.createSync(recursive: true);

    final timestamp = _yyyymmddHhmmss(DateTime.now());
    final backupName = 'deskgoo_cafe_backup_$timestamp.zip';
    final backupFile = File(p.join(backupsDir.path, backupName));


    final archive = Archive();


    final allFiles = docsDir
        .listSync(recursive: false, followLinks: false)
        .whereType<File>()
        .toList();

    for (final f in allFiles) {
      if (f.path.endsWith('.hive')) {
        final bytes = await f.readAsBytes();
        final relativePath = 'hive/${p.basename(f.path)}';
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      }
    }

    if (kImagesFolderName != null) {
      final imagesDir = Directory(p.join(docsDir.path, kImagesFolderName));
      if (imagesDir.existsSync()) {
        for (final entity in imagesDir.listSync(recursive: true)) {
          if (entity is File) {
            final rel = p.relative(entity.path, from: docsDir.path);
            final bytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(rel, bytes.length, bytes));
          }
        }
      }
    }

    final zipBytes = ZipEncoder().encode(archive)!;
    await backupFile.writeAsBytes(zipBytes, flush: true);

    if (shareAfterCreate) {
      await Share.shareXFiles([XFile(backupFile.path)],
          text: 'deskgoo_cafe backup ($timestamp)');
    }

    return backupFile;
  }

  /// Restores from a previously exported ZIP.
  /// Steps:
  /// 1) Prompt user to pick a .zip
  /// 2) Close Hive (releases file locks)
  /// 3) Extract into a temp dir
  /// 4) Overwrite current .hive files (and images dir if present in backup)
  /// 5) Reopen boxes if you want (optional, depends on your app flow)
  static Future<void> restoreFromZip({
    List<String> boxesToReopen = const [],
  }) async {

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.single.path == null) {
      debugPrint('Restore cancelled by user.');
      return;
    }
    final zipFile = File(result.files.single.path!);

    await Hive.close();

    final docsDir = await getApplicationDocumentsDirectory();
    final tempDir = await _createTempChildDir('restore_${DateTime.now().millisecondsSinceEpoch}');

    final zipBytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes, verify: true);
    for (final entry in archive) {
      if (entry.isFile) {
        final outPath = p.join(tempDir.path, entry.name);
        final outFile = File(outPath);
        outFile.parent.createSync(recursive: true);
        await outFile.writeAsBytes(entry.content as List<int>, flush: true);
      } else {
        Directory(p.join(tempDir.path, entry.name)).createSync(recursive: true);
      }
    }

    final hiveTempDir = Directory(p.join(tempDir.path, 'hive'));
    if (hiveTempDir.existsSync()) {
      for (final f in hiveTempDir.listSync().whereType<File>()) {
        if (f.path.endsWith('.hive')) {
          final dest = File(p.join(docsDir.path, p.basename(f.path)));
          await f.copy(dest.path);
        }
      }
    }

    if (kImagesFolderName != null) {
      final imagesTempDir = Directory(p.join(tempDir.path, kImagesFolderName));
      if (imagesTempDir.existsSync()) {
        final imagesDestDir = Directory(p.join(docsDir.path, kImagesFolderName));
        if (!imagesDestDir.existsSync()) {
          imagesDestDir.createSync(recursive: true);
        }
        await _copyDirectory(imagesTempDir, imagesDestDir);
      }
    }

    for (final name in boxesToReopen) {
      try {
        await Hive.openBox(name);
      } catch (e) {
        debugPrint('Failed to reopen box $name: $e');
      }
    }

    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}

    debugPrint('✅ Restore completed.');
  }

  static Future<void> _flushAllOpenBoxes() async {
    final List<String> boxNames = ['users','items','areas','tables','orders','settings'];
    for (final name in boxNames ){
      if (Hive.isBoxOpen(name)) {
        try{
          final box = Hive.box(name);
          await box.flush();
          await box.compact();
        } catch (_) {}
      }
    }
  }


  static Future<Directory> _createTempChildDir(String name) async {
    final temp = await getTemporaryDirectory();
    final dir = Directory(p.join(temp.path, name));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<void> _copyDirectory(Directory source, Directory dest) async {
    await for (final entity in source.list(recursive: false, followLinks: false)) {
      if (entity is Directory) {
        final newDir = Directory(p.join(dest.path, p.basename(entity.path)));
        if (!newDir.existsSync()) newDir.createSync(recursive: true);
        await _copyDirectory(entity, newDir);
      } else if (entity is File) {
        final newFile = File(p.join(dest.path, p.basename(entity.path)));
        await entity.copy(newFile.path);
      }
    }
  }

  static String _yyyymmddHhmmss(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}_${two(dt.hour)}${two(dt.minute)}${two(dt.second)}';
  }
}
