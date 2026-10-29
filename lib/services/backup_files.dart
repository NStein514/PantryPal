import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Platform side of backups: hand a file to the share sheet, or let the user pick one.
/// Kept separate from [BackupService] so the encoding stays testable and the UI can use a fake.
class BackupFiles {
  /// Writes [json] to a temp file and opens the share sheet (Files, Drive, email…).
  /// [origin] is required on iPad, where the sheet is a popover anchored to the tapped button.
  Future<void> share(String json, String fileName, {Rect? origin}) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'PantryPal backup',
      sharePositionOrigin: origin,
    );
  }

  /// Lets the user choose a backup file. Returns its text, or null if they cancelled.
  Future<String?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final f = result?.files.single;
    if (f == null) return null;
    if (f.bytes != null) return utf8.decode(f.bytes!);
    if (f.path != null) return File(f.path!).readAsString();
    return null;
  }
}
