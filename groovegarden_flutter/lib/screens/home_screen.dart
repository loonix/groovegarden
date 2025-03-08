// TODO: Eventually migrate from dart:html to package:web and dart:js_interop
// Import conditional based on platform to avoid warnings in mobile builds
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:groovegarden_flutter/screens/login_screen.dart';
import 'package:groovegarden_flutter/screens/song_upload_screen.dart';
import 'package:groovegarden_flutter/utils/secure_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'dart:async';
import 'dart:convert';

// Conditionally import dart:html only for web
import 'web_audio.dart' if (dart.library.io) 'stub_web_audio.dart';

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
  WebAudio? webAudio;

  // Player state variables
  bool _isPlaying = false;
  Map<String, dynamic>? _currentSong;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Timer? _positionTimer;

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

    // Initialize web audio helper if on web
    if (kIsWeb) {
      webAudio = WebAudio();
    }

    // Set up audio player listeners for mobile platforms
    if (!kIsWeb) {
      _audioPlayer.onDurationChanged.listen((newDuration) {
        setState(() {
          _duration = newDuration;
        });
      });

      _audioPlayer.onPositionChanged.listen((newPosition) {
        setState(() {
          _position = newPosition;
        });
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      });
    }
  }

  Future<void> _fetchSongs() async {
    try {
      final fetchedSongs = await ApiService.fetchSongs(widget.jwtToken);
      if (!mounted) return;
      setState(() {
        _songs = fetchedSongs.cast<Map<String, dynamic>>();
      });
    } catch (error) {
      debugPrint('Error fetching songs: $error');
      if (!mounted) return;
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
    if (kIsWeb && webAudio != null) {
      webAudio!.stopAudio();
    }
    _positionTimer?.cancel();
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
    try {
      await ApiService.voteForSong(songId, widget.jwtToken);
      // Check if the widget is still mounted before using BuildContext
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote cast successfully!')),
      );
    } catch (e) {
      // Replace print with debugPrint for better debugging
      debugPrint('Error voting for song: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cast vote')),
      );
    }
  }

  Future<void> _playSong(String songId, String title, Map<String, dynamic> song) async {
    try {
      // First check if the file exists and is accessible using our debug endpoint
      final debugResponse = await http.get(
        Uri.parse('${ApiService.baseUrl}/debug/file/$songId'),
        headers: {'Authorization': 'Bearer ${widget.jwtToken}'},
      );

      final debugData = jsonDecode(debugResponse.body);
      debugPrint('File debug data: $debugData');

      if (debugResponse.statusCode != 200 || debugData['error'] == true) {
        throw Exception('File not accessible: ${debugData['message']}');
      }

      // Build the URL based on platform
      final url = _buildStreamUrl(songId);
      debugPrint('Attempting to play song from URL: $url');

      if (kIsWeb) {
        // Web approach: Use WebAudio helper
        if (webAudio != null) {
          webAudio!.stopAudio();

          // Play using the WebAudio helper
          webAudio!.playAudio(url);

          // Set up position updating
          _positionTimer?.cancel();
          _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
            if (mounted) {
              setState(() {
                _position = webAudio!.getCurrentPosition();
                _duration = webAudio!.getDuration();
              });
            }
          });
        }
      } else {
        // Mobile approach: Use audioplayers package
        await _audioPlayer.stop();
        await Future.delayed(const Duration(milliseconds: 300));
        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
        await _audioPlayer.play(UrlSource(url));
      }

      if (!mounted) return;
      setState(() {
        currentlyPlaying = title;
        _isPlaying = true;
        _currentSong = song;
      });
    } catch (e) {
      debugPrint('Error playing song: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play song: ${e.toString()}'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _pausePlaySong() {
    if (_isPlaying) {
      if (kIsWeb && webAudio != null) {
        webAudio!.pauseAudio();
      } else {
        _audioPlayer.pause();
      }
    } else {
      if (kIsWeb && webAudio != null) {
        webAudio!.resumeAudio();
      } else {
        _audioPlayer.resume();
      }
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _seek(double value) {
    final position = Duration(seconds: value.toInt());

    if (kIsWeb && webAudio != null) {
      webAudio!.seekTo(value);
    } else {
      _audioPlayer.seek(position);
    }

    setState(() {
      _position = position;
    });
  }

  // Build appropriate streaming URL based on platform
  String _buildStreamUrl(String songId) {
    if (kIsWeb) {
      // For web, pass the token as a query parameter to avoid CORS issues
      // Note: This is less secure but necessary for web browser compatibility
      return '${ApiService.baseUrl}/stream/$songId?token=${Uri.encodeComponent(widget.jwtToken)}';
    } else {
      // For mobile platforms, we can use the standard URL
      return '${ApiService.baseUrl}/stream/$songId';
    }
  }

  Future<void> _logout() async {
    await SecureStorage.clearToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('User role: $userRole');

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
      body: _songs.isEmpty
          ? const Center(child: Text("No songs available"))
          : ListView.builder(
              padding: _currentSong != null ? EdgeInsets.only(bottom: 80) : null,
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                final isCurrentlyPlaying = _currentSong != null && _currentSong!['id'] == song['id'];

                return ListTile(
                  title: Text(
                    song['title'] ?? 'Unknown Title',
                    style: isCurrentlyPlaying ? TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor) : null,
                  ),
                  subtitle: Text('Artist: ${song['artist'] ?? 'Unknown'} • Votes: ${song['votes'] ?? 0}'),
                  leading: isCurrentlyPlaying
                      ? Icon(
                          _isPlaying ? Icons.music_note : Icons.pause,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.thumb_up),
                        tooltip: 'Vote for this song',
                        onPressed: () => _voteForSong(song['id']),
                      ),
                      IconButton(
                        icon: Icon(
                          isCurrentlyPlaying && _isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        tooltip: isCurrentlyPlaying && _isPlaying ? 'Pause' : 'Play',
                        onPressed: isCurrentlyPlaying ? _pausePlaySong : () => _playSong('${song['id']}', song['title'] ?? 'Unknown', song),
                      ),
                    ],
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
          : null,
      bottomNavigationBar: _currentSong != null ? _buildPlayerControls() : null,
    );
  }

  Widget _buildPlayerControls() {
    final themeData = Theme.of(context);

    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String minutes = twoDigits(duration.inMinutes.remainder(60));
      String seconds = twoDigits(duration.inSeconds.remainder(60));
      return "$minutes:$seconds";
    }

    // Calculate slider values safely
    double positionValue = _position.inSeconds.toDouble();
    double maxValue = _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0;
    if (positionValue > maxValue) positionValue = maxValue;

    return Container(
      height: 100, // Increased height to prevent overflow
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Added vertical padding
      decoration: BoxDecoration(
        color: themeData.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            offset: const Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      // Use a ListView instead of Column to handle potential overflow
      child: ListView(
        // Disable scrolling physics as we want it to be static
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          // Song info
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentSong?['title'] ?? 'Unknown',
                  style: themeData.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _currentSong?['artist'] ?? 'Unknown Artist',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.textTheme.bodyMedium?.color?.withAlpha(178),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress slider - simplified to avoid overflow
          Row(
            children: [
              Text(formatDuration(_position)),
              Expanded(
                child: Slider(
                  value: positionValue,
                  min: 0.0,
                  max: maxValue,
                  onChanged: _seek,
                ),
              ),
              Text(formatDuration(_duration)),
            ],
          ),
          // Play/pause button
          Center(
            child: IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _pausePlaySong,
              iconSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}

extension NumExtension on num {
  num max(num other) => this > other ? this : other;
}
