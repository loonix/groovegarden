import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/api_service.dart';

class SongUploadScreen extends StatefulWidget {
  final String jwtToken; // Pass JWT token for authorization

  const SongUploadScreen({super.key, required this.jwtToken});

  @override
  SongUploadScreenState createState() => SongUploadScreenState();
}

class SongUploadScreenState extends State<SongUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  String? _selectedFilename;
  Uint8List? _selectedFileBytes;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Allow any file type
      );

      if (result != null) {
        final fileName = result.files.single.name.toLowerCase();

        // Validate file extension
        if (fileName.endsWith('.mp3') || fileName.endsWith('.aac')) {
          setState(() {
            _selectedFilename = result.files.single.name; // Store filename
            _selectedFileBytes = result.files.single.bytes; // Store file bytes
          });
        } else {
          // Invalid file type
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid file type. Only MP3 and AAC files are allowed.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _uploadSong() async {
    if (_selectedFileBytes == null || _selectedFilename == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file to upload')),
        );
      }
      return;
    }

    final title = _titleController.text;
    final artist = _artistController.text;
    int? duration;

    try {
      duration = int.parse(_durationController.text);
    } catch (e) {
      debugPrint('Invalid duration: $_durationController.text');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid duration in seconds')),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Fix function call with correct parameters
      final success = await ApiService.uploadSongWithBytes(
        title, // String title
        artist, // String artist
        duration, // int duration
        _selectedFilename!, // String filename
        _selectedFileBytes!, // Uint8List fileBytes
        widget.jwtToken, // String token
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Song uploaded successfully!')),
          );
          Navigator.pop(context); // Go back to the previous screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload song')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error during upload: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred during upload')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Song'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Song Title'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a song title' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _artistController,
                decoration: const InputDecoration(labelText: 'Artist'),
                validator: (value) => value == null || value.isEmpty ? 'Enter the artist name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration (seconds)'),
                validator: (value) => value == null || value.isEmpty ? 'Enter the duration in seconds' : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Select Song File'),
              ),
              if (_selectedFilename != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Selected File: $_selectedFilename', // Use name instead of path
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 20),
              if (_isUploading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _uploadSong();
                    }
                  },
                  child: const Text('Upload Song'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
