import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final String jwtToken; // Pass JWT token to the screen

  const HomeScreen({required this.jwtToken});

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

    // Fetch songs from the backend
    ApiService.fetchSongs().then((fetchedSongs) {
      setState(() {
        _songs = fetchedSongs.cast<Map<String, dynamic>>();
      });
    }).catchError((error) {
      print('Error fetching songs: $error');
    });

    // Connect to WebSocket and handle incoming messages
    _webSocketService = WebSocketService();
    _webSocketService.connect((message) {
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
    });
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }

  void _uploadNewSong() {
    // Implement song upload functionality
    print('Uploading a new song...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GrooveGarden'),
      ),
      body: ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return ListTile(
            title: Text(song['title']),
            subtitle: Text('Votes: ${song['votes']}'),
          );
        },
      ),
      floatingActionButton: userRole == 'artist'
          ? FloatingActionButton(
              onPressed: _uploadNewSong,
              child: Icon(Icons.add),
              tooltip: 'Upload New Song',
            )
          : null, // Hide the button for non-artists
    );
  }
}
