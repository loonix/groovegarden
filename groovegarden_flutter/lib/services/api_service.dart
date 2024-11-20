import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8081';

  // Fetch songs from the backend
  static Future<List<dynamic>> fetchSongs() async {
    final response = await http.get(Uri.parse('$baseUrl/songs'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load songs');
    }
  }

  // Vote for a song
  static Future<void> voteForSong(int songId) async {
    final response = await http.post(Uri.parse('$baseUrl/vote/$songId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to vote for song');
    }
  }
}
