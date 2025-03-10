import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:async';

/// Utility class for handling files on web platform
class WebFileUtil {
  /// Creates a URL for a blob from byte data
  /// This can be used for previewing files in web browsers
  static String createBlobUrl(Uint8List bytes, String mimeType) {
    final blob = html.Blob([bytes], mimeType);
    return html.Url.createObjectUrlFromBlob(blob);
  }

  /// Creates an AudioContext to analyze audio
  /// Note: This is subject to browser autoplay policies
  static Future<int?> getAudioDuration(Uint8List bytes) async {
    final completer = Completer<int?>();

    try {
      final blob = html.Blob([bytes], 'audio/mpeg');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final audio = html.AudioElement()
        ..src = url
        ..preload = 'metadata';

      audio.onLoadedMetadata.listen((_) {
        final duration = (audio.duration * 1000).toInt();
        completer.complete(duration);
        html.Url.revokeObjectUrl(url);
      });

      audio.onError.listen((_) {
        completer.complete(null);
        html.Url.revokeObjectUrl(url);
      });

      // Set a timeout in case loading metadata takes too long
      Future.delayed(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete(null);
          html.Url.revokeObjectUrl(url);
        }
      });
    } catch (e) {
      completer.complete(null);
    }

    return completer.future;
  }
}

extension CompleterExtension on Completer {
  bool get isCompleted => future.isCompleted;
}

extension FutureExtension on Future {
  bool get isCompleted {
    bool completed = true;
    then((_) => completed = true).catchError((_) => completed = true);
    return completed;
  }
}
