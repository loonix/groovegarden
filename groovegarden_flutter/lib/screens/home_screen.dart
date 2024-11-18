import 'package:flutter/material.dart';
import 'package:groovegarden_flutter/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List songs = [];

  @override
  void initState() {
    super.initState();
    fetchSongs();
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

  Future<void> voteForSong(int songId) async {
    try {
      await ApiService.voteForSong(songId);
      fetchSongs(); // Refresh the list after voting
    } catch (e) {
      print('Error voting for song: $e');
    }
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
                    onPressed: () => voteForSong(song['id']),
                    child: const Text('Vote'),
                  ),
                );
              },
            ),
    );
  }
}
