// Stub implementation for non-web platforms
import 'package:flutter/material.dart';

/// Stub implementation of WebAudio for non-web platforms
class WebAudio {
  /// Function to call when playback ends
  Function? onPlaybackEnded;

  /// Initialize an empty WebAudio object
  WebAudio();

  /// Play audio from the given URL (stub)
  void playAudio(String url) {
    debugPrint('WebAudio stub: playAudio called with URL $url');
  }

  /// Pause audio playback (stub)
  void pauseAudio() {}

  /// Resume audio playback (stub)
  void resumeAudio() {}

  /// Stop and clean up audio (stub)
  void stopAudio() {}

  /// Seek to position in seconds (stub)
  void seekTo(double seconds) {}

  /// Get current playback position (stub)
  Duration getCurrentPosition() => Duration.zero;

  /// Get total duration of the audio (stub)
  Duration getDuration() => Duration.zero;

  /// Check if currently playing (stub)
  bool isPlaying() => false;

  /// Check if audio has reached the end (stub)
  bool hasEnded() => false;

  /// Get error state (stub)
  bool hasError() => false;

  /// Get last error message (stub)
  String getErrorMessage() => '';
}
