import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String baseUrl = 'http://localhost:8081';
  static String bearer = ''; //'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MzIyMzA0ODUsInJvbGUiOiJhcnRpc3QiLCJ1c2VyX2lkIjoxfQ.4PsoGJlxQyxIKeuDuhYKO6VJtrxbcBbJgNDtXByGtBY';
  // Fetch songs from the backend
  static Future<List<dynamic>> fetchSongs(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/songs'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load songs');
    }
  }

  static Future<void> uploadSong(String title, String filePath, String jwtToken) async {
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $jwtToken'
      ..fields['title'] = title
      ..files.add(await http.MultipartFile.fromPath('song', filePath));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to upload song: ${response.reasonPhrase}');
    }
  }

  // Upload a song with bytes
  static Future<void> uploadSongWithBytes(
    String title,
    Uint8List bytes,
    String fileName,
    String jwtToken,
  ) async {
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $jwtToken'
      ..fields['title'] = title
      ..files.add(http.MultipartFile.fromBytes(
        'song',
        bytes,
        filename: fileName, // Use the file name from the picker
      ));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to upload song: ${response.reasonPhrase}');
    }
  }

  // Vote for a song
  static Future<void> voteForSong(int songId, String jwtToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vote/$songId'),
      headers: {
        'Authorization': 'Bearer $jwtToken', // Use the provided JWT token
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to vote for song: ${response.body}');
    }
  }

  static Future<void> addSong(String title, String url, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': title, 'url': url}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload song: ${response.body}');
    }
  }

  static Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token']; // Assuming the backend returns a token
    } else {
      throw Exception('Invalid email or password');
    }
  }
}
