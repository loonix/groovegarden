import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SongUploadScreen extends StatefulWidget {
  final String jwtToken; // Pass JWT token for authorization

  const SongUploadScreen({required this.jwtToken});

  @override
  _SongUploadScreenState createState() => _SongUploadScreenState();
}

class _SongUploadScreenState extends State<SongUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _url = '';
  bool _isLoading = false;

  Future<void> _uploadSong() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Uploading song: $_title, $_url');
      await ApiService.addSong(_title, _url, widget.jwtToken);
      print('Song uploaded successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Song uploaded successfully!')),
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
        title: Text('Upload Song'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Song Title'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a song title' : null,
                onSaved: (value) {
                  _title = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Song URL'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a valid URL' : null,
                onSaved: (value) {
                  _url = value!;
                },
              ),
              SizedBox(height: 20),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () {
                    _formKey.currentState!.save();
                    _uploadSong();
                  },
                  child: Text('Upload Song'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
