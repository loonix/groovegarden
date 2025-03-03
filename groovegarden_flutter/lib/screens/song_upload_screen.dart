import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SongUploadScreen extends StatefulWidget {
  final String jwtToken; // Pass JWT token for authorization

  const SongUploadScreen({super.key, required this.jwtToken});

  @override
  SongUploadScreenState createState() => SongUploadScreenState();
}

class SongUploadScreenState extends State<SongUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  PlatformFile? _selectedFile;
  bool _isLoading = false;

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
            _selectedFile = result.files.single; // Store PlatformFile
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
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields and select a file')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use bytes directly for the upload
      await ApiService.uploadSongWithBytes(
        _title,
        _selectedFile!.bytes!, // Use bytes for the upload
        _selectedFile!.name, // Include the filename
        widget.jwtToken,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song uploaded successfully!')),
      );
      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      print('Error uploading song: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload song: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                decoration: const InputDecoration(labelText: 'Song Title'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a song title' : null,
                onSaved: (value) {
                  _title = value!;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Select Song File'),
              ),
              if (_selectedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Selected File: ${_selectedFile!.name}', // Use name instead of path
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () {
                    _formKey.currentState!.save();
                    _uploadSong();
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
