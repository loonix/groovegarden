import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List songs = [];
  late WebSocketService webSocketService;

  @override
  void initState() {
    super.initState();
    fetchSongs();
    initWebSocket();
  }

  void initWebSocket() {
    webSocketService = WebSocketService();
    webSocketService.connect((message) {
      final decodedMessage = jsonDecode(message);

      if (decodedMessage['type'] == 'song_added' || decodedMessage['type'] == 'vote_cast') {
        fetchSongs(); // Refresh the song list on updates
      }
    });
  }

  Future<void> fetchSongs() async {
    try {
      final fetchedSongs = await ApiService.fetchSongs();
      setState(() {
        songs = fetchedSongs;
      });
    } catch (e) {
      print('Error fetching songs: $e');
    }
  }

  @override
  void dispose() {
    webSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GrooveGarden'),
      ),
      body: songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  title: Text(song['title']),
                  subtitle: Text('Votes: ${song['votes']}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await ApiService.voteForSong(song['id']);
                      fetchSongs(); // Refresh the list after voting
                    },
                    child: const Text('Vote'),
                  ),
                );
              },
            ),
    );
  }
}
