import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String baseUrl = 'http://localhost:8081';
  static String bearer = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MzIyMzA0ODUsInJvbGUiOiJhcnRpc3QiLCJ1c2VyX2lkIjoxfQ.4PsoGJlxQyxIKeuDuhYKO6VJtrxbcBbJgNDtXByGtBY';
  // Fetch songs from the backend
  static Future<List<dynamic>> fetchSongs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/songs'),
      headers: {
        'Authorization': 'Bearer $bearer', // Replace with valid token
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load songs');
    }
  }

  // Vote for a song
  static Future<void> voteForSong(int songId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vote/$songId'),
      headers: {
        'Authorization': 'Bearer $bearer', // Replace with valid token
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to vote for song');
    }
  }
}
