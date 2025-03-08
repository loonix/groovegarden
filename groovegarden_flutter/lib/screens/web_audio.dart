// Web-only file for handling HTML5 audio
import 'dart:html' as html;
import 'package:flutter/material.dart';

/// Class for managing web audio player
class WebAudio {
  html.AudioElement? _audioElement;
  bool _hasError = false;
  String _lastErrorMessage = '';

  // Callback function for when playback ends
  Function? onPlaybackEnded;

  /// Initialize an empty WebAudio object
  WebAudio();

  /// Play audio from the given URL
  void playAudio(String url) {
    stopAudio(); // Stop any currently playing audio
    _hasError = false;
    _lastErrorMessage = '';

    debugPrint('WebAudio: Attempting to play from URL $url');

    // Create audio element with better error handling
    _audioElement = html.AudioElement();

    // Set up error handler before setting src to catch loading errors
    _audioElement!.onError.listen((event) {
      _hasError = true;
      // Try to get more detailed error information
      final errorCode = _audioElement?.error?.code ?? -1;
      final errorMessage = _getErrorMessage(errorCode);
      _lastErrorMessage = 'Error code: $errorCode - $errorMessage';

      debugPrint('WebAudio Error: $_lastErrorMessage');
      debugPrint('Network state: ${_getNetworkStateMessage(_audioElement?.networkState ?? 0)}');
      debugPrint('Ready state: ${_getReadyStateMessage(_audioElement?.readyState ?? 0)}');
    });

    // Set up event listeners for debugging using available events
    _audioElement!.onLoadedData.listen((_) => debugPrint('WebAudio: Data loaded successfully'));
    _audioElement!.onLoadedMetadata.listen((_) => debugPrint('WebAudio: Metadata loaded'));
    _audioElement!.onCanPlay.listen((_) => debugPrint('WebAudio: Can play'));
    _audioElement!.onCanPlayThrough.listen((_) => debugPrint('WebAudio: Can play through'));
    _audioElement!.onPlay.listen((_) => debugPrint('WebAudio: Playback started'));
    _audioElement!.onPause.listen((_) => debugPrint('WebAudio: Playback paused'));

    // Handle end of playback
    _audioElement!.onEnded.listen((_) {
      debugPrint('WebAudio: Playback ended');
      if (onPlaybackEnded != null) {
        onPlaybackEnded!();
      }
    });

    _audioElement!.onStalled.listen((_) => debugPrint('WebAudio: Playback stalled'));
    _audioElement!.onSeeking.listen((_) => debugPrint('WebAudio: Seeking'));
    _audioElement!.onSeeked.listen((_) => debugPrint('WebAudio: Seeked'));

    // Set attributes for better compatibility
    _audioElement!
      ..crossOrigin = "anonymous"
      ..preload = "auto";

    // Add audio types that might be supported - try multiple formats
    _tryMultipleFormats(url);

    // Add to DOM to ensure it works in all browsers
    html.document.body?.append(_audioElement!);
  }

  /// Try to play audio with multiple format options
  void _tryMultipleFormats(String url) {
    // First check if URL has a file extension
    final hasExtension = url.contains(RegExp(r'\.(mp3|ogg|wav|aac)($|\?)'));

    if (hasExtension) {
      // If URL already has an extension, use it directly
      _audioElement!.src = url;
      _tryPlayAudio();
    } else {
      // Otherwise try to add source elements with different formats
      _addSourceElement(url, 'audio/mpeg');
      _addSourceElement('${url}.mp3', 'audio/mpeg');
      _addSourceElement('${url}.ogg', 'audio/ogg');
      _addSourceElement('${url}.wav', 'audio/wav');

      // Try to play with the multiple sources
      _tryPlayAudio();
    }
  }

  /// Add a source element with a specific MIME type
  void _addSourceElement(String url, String mimeType) {
    final sourceElement = html.SourceElement()
      ..src = url
      ..type = mimeType;
    _audioElement?.append(sourceElement);
  }

  /// Try to play audio with error handling
  void _tryPlayAudio() {
    if (_audioElement != null) {
      try {
        // Play the audio and handle any exceptions
        _audioElement!.play();

        // Add a timeout to detect if playback doesn't start
        Future.delayed(const Duration(seconds: 3), () {
          if (!_hasError && _audioElement != null && _audioElement!.paused) {
            debugPrint('WebAudio: Playback did not start after timeout');

            // Try to provide more debugging info
            debugPrint('Current src: ${_audioElement!.src}');
            debugPrint('Current time: ${_audioElement!.currentTime}');
            debugPrint('Duration: ${_audioElement!.duration}');
            debugPrint('Paused: ${_audioElement!.paused}');
            debugPrint('Muted: ${_audioElement!.muted}');
            debugPrint('Volume: ${_audioElement!.volume}');
          }
        });
      } catch (e) {
        debugPrint('WebAudio: Exception during play: $e');
        _hasError = true;
        _lastErrorMessage = 'Play exception: $e';
      }
    }
  }

  /// Get a human-readable error message
  String _getErrorMessage(int code) {
    switch (code) {
      case 1:
        return 'MEDIA_ERR_ABORTED: Fetching process aborted by user';
      case 2:
        return 'MEDIA_ERR_NETWORK: Network error';
      case 3:
        return 'MEDIA_ERR_DECODE: Media decoding error';
      case 4:
        return 'MEDIA_ERR_SRC_NOT_SUPPORTED: Format not supported';
      default:
        return 'Unknown error';
    }
  }

  /// Get network state as string
  String _getNetworkStateMessage(int state) {
    switch (state) {
      case 0:
        return 'NETWORK_EMPTY: Resource not initialized';
      case 1:
        return 'NETWORK_IDLE: Resource selected but not in use';
      case 2:
        return 'NETWORK_LOADING: Data is being loaded';
      case 3:
        return 'NETWORK_NO_SOURCE: No source found';
      default:
        return 'Unknown state';
    }
  }

  /// Get ready state as string
  String _getReadyStateMessage(int state) {
    switch (state) {
      case 0:
        return 'HAVE_NOTHING: No information';
      case 1:
        return 'HAVE_METADATA: Metadata loaded';
      case 2:
        return 'HAVE_CURRENT_DATA: Data for current position available';
      case 3:
        return 'HAVE_FUTURE_DATA: Data for current and future position available';
      case 4:
        return 'HAVE_ENOUGH_DATA: Enough data available';
      default:
        return 'Unknown state';
    }
  }

  /// Pause audio playback
  void pauseAudio() {
    _audioElement?.pause();
  }

  /// Resume audio playback
  void resumeAudio() {
    if (_audioElement != null && !_hasError) {
      _audioElement!.play();
    }
  }

  /// Stop and reset playback completely
  void stopAudio() {
    if (_audioElement != null) {
      _audioElement!.pause();
      // Reset current time to beginning
      try {
        _audioElement!.currentTime = 0;
      } catch (e) {
        debugPrint('WebAudio: Error resetting time: $e');
      }
      _audioElement!.remove();
      _audioElement = null;
    }
    _hasError = false;
    _lastErrorMessage = '';
  }

  /// Seek to position in seconds
  void seekTo(double seconds) {
    if (_audioElement != null && !_hasError) {
      _audioElement!.currentTime = seconds;
    }
  }

  /// Get current playback position
  Duration getCurrentPosition() {
    if (_audioElement == null || _hasError) return Duration.zero;
    return Duration(seconds: _audioElement!.currentTime.toInt());
  }

  /// Get total duration of the audio
  Duration getDuration() {
    if (_audioElement == null || _hasError || _audioElement!.duration.isNaN) {
      return Duration.zero;
    }
    return Duration(seconds: _audioElement!.duration.toInt());
  }

  /// Check if currently playing
  bool isPlaying() {
    if (_audioElement == null || _hasError) return false;
    return !_audioElement!.paused;
  }

  /// Check if audio has reached the end
  bool hasEnded() {
    if (_audioElement == null) return false;
    // Check if we're at the end of the audio
    return _audioElement!.ended || (_audioElement!.duration > 0 && _audioElement!.currentTime >= _audioElement!.duration - 0.5);
  }

  /// Get error state
  bool hasError() {
    return _hasError;
  }

  /// Get last error message
  String getErrorMessage() {
    return _lastErrorMessage;
  }
}
