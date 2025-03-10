import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:groovegarden_flutter/services/api_service.dart';
import 'package:groovegarden_flutter/services/auth_service.dart';
import 'package:just_audio/just_audio.dart';

class SongUploadScreen extends StatefulWidget {
  final String jwtToken;

  const SongUploadScreen({super.key, required this.jwtToken});

  @override
  SongUploadScreenState createState() => SongUploadScreenState();
}

class SongUploadScreenState extends State<SongUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();

  String? _filename;
  Uint8List? _fileBytes;
  bool _isUploading = false;
  bool _uploadSuccess = false;
  String _errorMessage = '';
  int _duration = 0; // Duration in seconds, will be extracted from file

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _filename = file.name;
          _fileBytes = file.bytes;
          _duration = 0; // Reset duration, will extract from file
          _errorMessage = '';
        });

        // Extract duration from audio file
        await _extractDurationFromFile(file);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _extractDurationFromFile(PlatformFile file) async {
    try {
      // Create a temporary audio player to extract metadata
      final player = AudioPlayer();

      try {
        Duration? duration;

        if (kIsWeb) {
          // For web, we can't use file paths or data URIs directly with just_audio
          // Instead, we'll skip duration extraction on web for now
          debugPrint('Skipping duration extraction on web');
          // Estimate duration based on file size (very rough estimate)
          if (file.size > 0) {
            // Rough estimate: ~1MB per minute for typical MP3
            final estimatedDurationInSeconds = (file.size / 1000000) * 60;
            duration = Duration(seconds: estimatedDurationInSeconds.round());
            debugPrint('Estimated duration from file size: ${duration.inSeconds} seconds');
          }
        } else {
          // For mobile platforms, we use the file path
          if (file.path != null) {
            duration = await player.setFilePath(file.path!);
          }
        }

        if (duration != null) {
          setState(() {
            _duration = duration!.inSeconds;
          });
          debugPrint('Audio duration: ${duration.inSeconds} seconds');
        }
      } finally {
        // Clean up
        await player.dispose();
      }
    } catch (e) {
      debugPrint('Error extracting duration: $e');
      // If we can't extract the duration, we'll just leave it at 0
      // and let the backend handle it
    }
  }

  Future<void> _uploadSong() async {
    if (_formKey.currentState!.validate() && _fileBytes != null) {
      setState(() {
        _isUploading = true;
        _errorMessage = '';
      });

      try {
        // Check if token is expired
        if (AuthService.isTokenExpired(widget.jwtToken)) {
          final newToken = await AuthService.refreshToken(widget.jwtToken);
          if (newToken != null) {
            debugPrint('Token refreshed before upload');
            // Use new token
            final success = await ApiService.uploadSongWithBytes(
              _titleController.text,
              _artistController.text,
              _duration,
              _filename ?? 'unknown.mp3',
              _fileBytes!,
              newToken,
            );
            _handleUploadResult(success);
          } else {
            // Token refresh failed, try with original token
            debugPrint('Token refresh failed, trying upload with original token');
            final success = await ApiService.uploadSongWithBytes(
              _titleController.text,
              _artistController.text,
              _duration,
              _filename ?? 'unknown.mp3',
              _fileBytes!,
              widget.jwtToken,
            );
            _handleUploadResult(success);
          }
        } else {
          // Token not expired, use it directly
          final success = await ApiService.uploadSongWithBytes(
            _titleController.text,
            _artistController.text,
            _duration,
            _filename ?? 'unknown.mp3',
            _fileBytes!,
            widget.jwtToken,
          );
          _handleUploadResult(success);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _errorMessage = 'Upload error: $e';
          });
        }
      }
    }
  }

  void _handleUploadResult(bool success) {
    if (!mounted) return;

    setState(() {
      _isUploading = false;
      _uploadSuccess = success;
      if (!success) {
        _errorMessage = 'Upload failed. Please try again or log out and log back in.';
      } else {
        // Reset form on success
        _titleController.clear();
        _artistController.clear();
        _filename = null;
        _fileBytes = null;
        _duration = 0;
      }
    });

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload a Song'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _artistController,
                decoration: const InputDecoration(labelText: 'Artist'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an artist name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickAudioFile,
                icon: const Icon(Icons.audio_file),
                label: Text(_filename != null ? 'Change File' : 'Select Audio File'),
              ),
              if (_filename != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    'Selected: $_filename${_duration > 0 ? ' (${_formatDuration(_duration)})' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isUploading || _fileBytes == null ? null : _uploadSong,
                child: _isUploading ? const CircularProgressIndicator() : const Text('Upload Song'),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (_uploadSuccess)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Song uploaded successfully!',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }
}
