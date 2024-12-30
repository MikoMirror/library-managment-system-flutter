import 'dart:html' as html;
import 'dart:io';
import 'pdf_platform_helper.dart';

class PdfPlatformHelper implements IPdfPlatformHelper {
  @override
  Future<File?> handlePdfBytes(List<int> bytes) async {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
    return null;
  }
} 