import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ExportHelper {
  static Future<String?> saveImageToFile(
    Uint8List imageBytes,
    String fileName, {
    String format = 'png',
  }) async {
    try {
      final wantJpg = format.toLowerCase() == 'jpg' || format.toLowerCase() == 'jpeg';
      Uint8List bytes = imageBytes;
      var extension = 'png';

      if (wantJpg) {
        final decoded = img.decodeImage(imageBytes);
        if (decoded != null) {
          bytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
          extension = 'jpg';
        } else {
          debugPrint('JPG encode failed, falling back to PNG');
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\-]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/${sanitizedName}_$timestamp.$extension');
      await file.writeAsBytes(bytes);
      debugPrint('Image saved to: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error saving to file: $e');
      return null;
    }
  }
}
