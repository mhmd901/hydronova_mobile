class ChatMessage {
  ChatMessage({
    required this.role,
    required this.text,
    required this.timestampMs,
  });

  final ChatRole role;
  final String text;
  final int timestampMs;
}

enum ChatRole {
  user,
  assistant,
}
