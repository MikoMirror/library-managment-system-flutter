import 'dart:io';

abstract class IPdfPlatformHelper {
  Future<File?> handlePdfBytes(List<int> bytes);
} 