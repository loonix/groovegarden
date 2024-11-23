import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:groovegarden_flutter/screens/login_screen.dart';
import 'package:groovegarden_flutter/screens/song_upload_screen.dart';
import 'package:groovegarden_flutter/utils/secure_storage.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final String jwtToken; // Pass JWT token to the screen

  const HomeScreen({super.key, required this.jwtToken});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late WebSocketService _webSocketService;
  List<Map<String, dynamic>> _songs = [];
  String? userRole;

  @override
  void initState() {
    super.initState();

    // Decode the JWT and extract the user's role
    final decodedJWT = AuthService.decodeJWT(widget.jwtToken);
    userRole = decodedJWT['role'];
    print('Decoded JWT: $decodedJWT');

    // Fetch songs from the backend
    ApiService.fetchSongs(widget.jwtToken).then((fetchedSongs) {
      setState(() {
        _songs = fetchedSongs.cast<Map<String, dynamic>>();
      });
    }).catchError((error) {
      print('Error fetching songs: $error');
    });

    // Connect to WebSocket and handle incoming messages
    _webSocketService = WebSocketService();
    _webSocketService.connect((message) {
      try {
        final data = jsonDecode(message);

        setState(() {
          if (data['event'] == 'vote_cast') {
            final updatedSong = data['payload'];
            final songIndex = _songs.indexWhere((song) => song['id'] == updatedSong['id']);
            if (songIndex != -1) {
              _songs[songIndex] = updatedSong;
            }
          } else if (data['event'] == 'song_added') {
            _songs.add(data['payload']);
          }
        });
      } catch (e) {
        print('Error parsing WebSocket message: $e');
      }
    });
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }

  void _uploadNewSong() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongUploadScreen(jwtToken: widget.jwtToken),
      ),
    );
  }

  Future<void> _voteForSong(int songId) async {
    debugger();
    try {
      await ApiService.voteForSong(songId, widget.jwtToken);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote cast successfully!')),
      );
    } catch (e) {
      print('Error voting for song: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cast vote')),
      );
    }
  }

  Future<void> _logout() async {
    await SecureStorage.deleteToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('User role: $userRole');
    print('Songs: $_songs');
    print('Token: ${widget.jwtToken}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('GrooveGarden'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return ListTile(
            title: Text(song['title']),
            subtitle: Text('Votes: ${song['votes']}'),
            trailing: IconButton(
              icon: const Icon(Icons.thumb_up),
              tooltip: 'Vote for this song',
              onPressed: () => _voteForSong(song['id']),
            ),
          );
        },
      ),
      floatingActionButton: userRole == 'artist'
          ? FloatingActionButton(
              onPressed: _uploadNewSong,
              tooltip: 'Upload New Song',
              child: const Icon(Icons.add),
            )
          : null, // Show upload button only for artists
    );
  }
}
