import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  late WebSocketChannel channel;

  void connect(Function(dynamic) onMessage) {
    // Connect to the WebSocket server
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/ws'),
    );

    // Listen for incoming messages
    channel.stream.listen((message) {
      onMessage(message);
    }, onError: (error) {
      print("WebSocket error: $error");
    }, onDone: () {
      print("WebSocket closed");
    });
  }

  void disconnect() {
    channel.sink.close(status.goingAway);
  }
}
