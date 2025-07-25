/// T is a phantom type to enforce the type of the query parameters
/// It prevents dart from inferring the type of the query parameters as dynamic
abstract class ScreenParams<T> {
  const ScreenParams();
  Map<String, String> toMap();
}

class NoParams extends ScreenParams<NoParams> {
  static NoParams unit = const NoParams();
  const NoParams();

  @override
  Map<String, String> toMap() => {};
}

class ChatbotParams extends ScreenParams<ChatbotParams> {
  final String? conversation;

  const ChatbotParams({this.conversation});

  factory ChatbotParams.fromMap(Map<String, String> map) {
    return ChatbotParams(
      conversation: map["conversation"],
    );
  }

  @override
  Map<String, String> toMap() {
    return {
      if (conversation != null) "conversation": conversation!,
    };
  }
}
