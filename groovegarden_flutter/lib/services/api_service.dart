import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ApiService {
  // If running on web, use window.location.hostname to dynamically set the host
  static String get baseUrl {
    if (kIsWeb) {
      // This will work when the Flutter app and Go server are on the same host
      return 'http://localhost:8081';
    }
    // For mobile devices, we need the actual IP address of the server
    return 'http://localhost:8081'; // Update this with your actual server IP if needed
  }

  // Fetch all songs from the API
  static Future<List<dynamic>> fetchSongs(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/songs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as List<dynamic>;
      } catch (e) {
        debugPrint('Error decoding response: $e');
        throw Exception('Failed to decode songs data');
      }
    } else {
      debugPrint('Error fetching songs: ${response.statusCode}, ${response.body}');
      throw Exception('Error fetching songs: ${response.statusCode}');
    }
  }

  // Vote for a song
  static Future<void> voteForSong(int songId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/songs/vote/$songId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      debugPrint('Error voting for song: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to vote for song: ${response.statusCode}');
    }
  }

  // Upload a new song
  static Future<bool> uploadSong(
    String title,
    String artist,
    int duration,
    String filePath,
    String token,
  ) async {
    // Implementation depends on your file upload requirements
    // This is a placeholder for song upload functionality
    return true;
  }

  // Upload a song with file bytes
  static Future<bool> uploadSongWithBytes(
    String title,
    String artist,
    int duration,
    String filename,
    Uint8List fileBytes,
    String token,
  ) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/songs/upload'));

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'song',
          fileBytes,
          filename: path.basename(filename),
        ),
      );

      // Add metadata
      request.fields['title'] = title;
      request.fields['artist'] = artist;
      request.fields['duration'] = duration.toString();

      // Send the request
      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Song uploaded successfully');
        return true;
      } else {
        debugPrint('Failed to upload song: ${response.statusCode}');
        // Read response body
        final responseBody = await response.stream.bytesToString();
        debugPrint('Response: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('Error uploading song: $e');
      return false;
    }
  }

  // We're removing the checkStreamAvailability method as it's causing issues
  // and we'll handle errors directly in the play method

  // Other API methods as needed...
}
