import 'package:flutter/foundation.dart';
import 'platform_helper_stub.dart'
    if (dart.library.js_interop) 'platform_helper_web.dart';

class PlatformHelper {
  /// Triggers a direct browser file download on Web without needing platform channels
  static void downloadFile(Uint8List bytes, String filename, String mimeType) {
    if (kIsWeb) {
      downloadFileImpl(bytes, filename, mimeType);
    }
  }

  /// Opens an external URL via an HTMLAnchorElement in a new tab without popup blocker interference
  static void openWebUrl(String url) {
    if (kIsWeb) {
      openExternalUrlImpl(url);
    }
  }
}
