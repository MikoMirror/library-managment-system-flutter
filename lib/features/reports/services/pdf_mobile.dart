import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'pdf_platform_helper.dart';

class PdfPlatformHelper implements IPdfPlatformHelper {
  @override
  Future<File?> handlePdfBytes(List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/report.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
} 