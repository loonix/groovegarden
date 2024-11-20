import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String baseUrl = 'http://localhost:${dotenv.env['SERVER_PORT']}';

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
