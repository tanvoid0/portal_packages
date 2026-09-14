# portal_scanner

Native document scanner — ML Kit Document Scanner on Android, VisionKit on
iOS — returning PDF or JPEG bytes. Thin wrapper over
`cunning_document_scanner`.

```dart
import 'package:portal_scanner/portal_scanner.dart';

if (PortalDocumentScanner.isSupported) {
  final doc = await PortalDocumentScanner.scanPdf(maxPages: 5);   // ScannedDocument?
  final pages = await PortalDocumentScanner.scanImages();         // List<Uint8List>
}
```

Android and iOS only; `isSupported` is false elsewhere.
