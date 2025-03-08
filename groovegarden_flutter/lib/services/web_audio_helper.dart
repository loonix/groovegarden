import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Helper class for managing web audio playback
class WebAudioHelper {
  /// Creates an HTML audio element for playing audio in web browsers
  static html.AudioElement createAudioElement(String url) {
    final audioElement = html.AudioElement()
      ..src = url
      ..crossOrigin = "anonymous" // Enable CORS access
      ..preload = "auto";

    // Add debugging listeners
    audioElement.onError.listen((event) {
      debugPrint('HTML Audio Error: ${event.toString()}');
    });

    audioElement.onLoadedData.listen((event) {
      debugPrint('HTML Audio loaded successfully');
    });

    return audioElement;
  }

  /// Plays a stream with the given URL and returns the audio element
  static html.AudioElement playStream(String url) {
    final audioElement = createAudioElement(url);
    audioElement.play();

    // Make sure the element isn't garbage collected
    html.document.body?.append(audioElement);

    return audioElement;
  }

  /// Stops playback and removes an audio element
  static void stopAndRemove(html.AudioElement? audioElement) {
    if (audioElement != null) {
      audioElement.pause();
      audioElement.remove();
    }
  }

  /// Get current playback position in seconds
  static num getCurrentPosition(html.AudioElement audioElement) {
    return audioElement.currentTime;
  }

  /// Get total duration in seconds
  static num getDuration(html.AudioElement audioElement) {
    return audioElement.duration;
  }

  /// Seek to position in seconds
  static void seekTo(html.AudioElement audioElement, double positionInSeconds) {
    audioElement.currentTime = positionInSeconds;
  }
}
