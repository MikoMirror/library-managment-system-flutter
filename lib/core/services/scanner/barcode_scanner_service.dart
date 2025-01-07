import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class BarcodeScannerService {
  static Future<String?> scanBarcode() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || 
        defaultTargetPlatform == TargetPlatform.android)) {
      try {
        final controller = MobileScannerController(
          formats: [BarcodeFormat.ean13],
          detectionSpeed: DetectionSpeed.normal,
        );
        
        String? scannedCode;
        final completer = Completer<String?>();
        
        controller.start();
        
        controller.barcodes.listen((barcodeCapture) {
          for (final barcode in barcodeCapture.barcodes) {
            if (barcode.rawValue != null && !completer.isCompleted) {
              scannedCode = barcode.rawValue;
              completer.complete(scannedCode);
              break;
            }
          }
        });
        
        // Wait for the first valid barcode or timeout after 30 seconds
        scannedCode = await completer.future
            .timeout(const Duration(seconds: 30), onTimeout: () => null);
        
        await controller.stop();
        return scannedCode;
      } catch (e) {
        debugPrint('Error scanning barcode: $e');
        return null;
      }
    }
    return null;
  }
} 