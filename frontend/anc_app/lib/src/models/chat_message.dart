class ChatMessage {
  final String id;
  final String text;
  final bool isAi;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isAi,
    required this.timestamp,
  });
}
