import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:groovegarden_flutter/screens/login_screen.dart';
import 'package:groovegarden_flutter/screens/song_upload_screen.dart';
import 'package:groovegarden_flutter/utils/secure_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final String jwtToken;

  const HomeScreen({super.key, required this.jwtToken});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late WebSocketService _webSocketService;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Audio player for streaming
  List<Map<String, dynamic>> _songs = [];
  String? userRole;
  String? currentlyPlaying;

  @override
  void initState() {
    super.initState();

    // Decode the JWT and extract the user's role
    final decodedJWT = AuthService.decodeJWT(widget.jwtToken);
    userRole = decodedJWT['role'];
    debugPrint('Decoded JWT: $decodedJWT');

    // Fetch songs from the backend
    _fetchSongs();

    // Connect to WebSocket and handle incoming messages
    _connectWebSocket();
  }

  Future<void> _fetchSongs() async {
    try {
      final fetchedSongs = await ApiService.fetchSongs(widget.jwtToken);
      setState(() {
        _songs = fetchedSongs.cast<Map<String, dynamic>>();
      });
    } catch (error) {
      debugPrint('Error fetching songs: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch songs')),
      );
    }
  }

  void _connectWebSocket() {
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
        debugPrint('Error parsing WebSocket message: $e');
      }
    });
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    _audioPlayer.dispose();
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

  Future<void> _playSong(String streamUrl, String title) async {
    try {
      await _audioPlayer.play(DeviceFileSource(streamUrl));
      setState(() {
        currentlyPlaying = title;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playing: $title')),
      );
    } catch (e) {
      print('Error playing song: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to play song')),
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
    debugPrint('User role: $userRole');
    debugPrint('Songs: $_songs');
    debugPrint('Token: ${widget.jwtToken}');
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
      body: Column(
        children: [
          if (currentlyPlaying != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.green.shade100,
              child: Text(
                'Currently Playing: $currentlyPlaying',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return ListTile(
                  title: Text(song['title']),
                  subtitle: Text('Votes: ${song['votes']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.thumb_up),
                        tooltip: 'Vote for this song',
                        onPressed: () => _voteForSong(song['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        tooltip: 'Play this song',
                        onPressed: () => _playSong('http://localhost:8081/stream/${song['id']}', song['title']),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
