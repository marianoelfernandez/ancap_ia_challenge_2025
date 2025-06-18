class ChatMessage {
  final String id;
  final String text;
  final bool isAi;
  final DateTime timestamp;
  final String? chartData; // Optional field for chart JSON data

  ChatMessage({
    required this.id,
    required this.text,
    required this.isAi,
    required this.timestamp,
    this.chartData,
  });
}
