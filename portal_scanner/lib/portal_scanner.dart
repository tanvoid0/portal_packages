import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';

export 'package:cunning_document_scanner/cunning_document_scanner.dart'
    show CunningDocumentScannerException;

/// Bytes plus a filename — the same shape finance's `PickedDocument` has, so
/// a scan and a picked file are interchangeable at the upload call.
typedef ScannedDocument = ({Uint8List bytes, String name});

/// Camera with live edge detection, or a gallery image through the same crop
/// UI. The platform scanner owns capture, crop and page review; nothing here
/// touches pixels.
///
/// Only Android and iOS have a scanner. [isSupported] is false elsewhere and
/// every scan method throws [UnsupportedError] — callers keep their file
/// picker as the fallback and hide the scan affordance.
class PortalDocumentScanner {
  PortalDocumentScanner._();

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// One PDF of up to [maxPages] pages. Null when the user backs out.
  ///
  /// Throws [CunningDocumentScannerException] with code `permission_denied`
  /// when the camera is refused, or on a native scan failure.
  static Future<ScannedDocument?> scanPdf({int maxPages = 5}) async {
    final paths = await _scan(maxPages: maxPages, asPdf: true);
    if (paths == null) return null;
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    return (bytes: await _take(paths.first), name: 'scan-$stamp.pdf');
  }

  /// One JPEG per page, up to [maxPages]. Empty when the user backs out.
  ///
  /// [jpegQuality] is 0..1. Android's scanner always emits JPEG at its own
  /// quality; the knob only reaches iOS, which would otherwise hand back PNG.
  /// Both platforms return JPEG so callers see one format.
  static Future<List<Uint8List>> scanImages({
    int maxPages = 1,
    double jpegQuality = 0.85,
  }) async {
    final paths = await _scan(
      maxPages: maxPages,
      asPdf: false,
      jpegQuality: jpegQuality,
    );
    if (paths == null) return const [];
    return [for (final p in paths) await _take(p)];
  }

  /// Edge detection, corner handles, and the filter bar (colour, greyscale,
  /// B&W, cleanup) are the platform scanner's own UI on both sides —
  /// `AndroidScannerMode.full` and `showFilterBar` are what turn them on.
  static Future<List<String>?> _scan({
    required int maxPages,
    required bool asPdf,
    double jpegQuality = 0.85,
  }) {
    if (!isSupported) {
      throw UnsupportedError('Document scanning needs Android or iOS.');
    }
    return CunningDocumentScanner.getPictures(
      noOfPages: maxPages,
      asPdf: asPdf,
      scannerSource: ScannerSource.cameraAndGallery,
      androidScannerMode: AndroidScannerMode.full,
      iosScannerOptions: IosScannerOptions(
        imageFormat: IosImageFormat.jpg,
        jpgCompressionQuality: jpegQuality,
        showFilterBar: true,
      ),
    );
  }

  /// The plugin writes into its own cache directory and expects the caller to
  /// copy out what it wants; we only want the bytes, so read and delete.
  static Future<Uint8List> _take(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    // Best-effort: a leftover cache file is not a failure.
    try {
      await file.delete();
    } catch (_) {}
    return bytes;
  }
}
