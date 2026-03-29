import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  /// Shares a CSV string securely by writing it to a temporary file,
  /// sharing it via the platform's native share sheet, and then immediately deleting the file.
  static Future<void> shareCsvFile(String csvString) async {
    File? tempFile;
    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/private_tracker_export.csv';
      tempFile = File(path);
      
      // Write unencrypted data to temp file
      await tempFile.writeAsString(csvString);
      
      // Share it
      final xFile = XFile(tempFile.path, mimeType: 'text/csv');
      // ignore: deprecated_member_use
      await Share.shareXFiles([xFile], text: 'My Cycle & Symptom Logs');
    } finally {
      // Ensure the temp file is deleted no matter what happens, to prevent unencrypted data leakage.
      // Note: shareXFiles on current share_plus awaits the sheet dismissal before returning,
      // so deleting here is generally safe and necessary for strict privacy.
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          // If we fail to delete, it might be locked, but we tried our best.
          // In a production scenario, we'd log this securely.
        }
      }
    }
  }
}
