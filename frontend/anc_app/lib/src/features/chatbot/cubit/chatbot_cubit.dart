import "package:anc_app/src/features/chatbot/services/conversation_service.dart";
import "package:anc_app/src/features/chatbot/services/query_service.dart";
import "package:anc_app/src/models/query.dart";
import "package:bloc/bloc.dart";
import "package:equatable/equatable.dart";
import "package:flutter/foundation.dart";
import "package:get_it/get_it.dart";

class ChatbotState extends Equatable {
  final String? selectedConversationId;
  final List<Query> queries;
  final bool isLoading;
  final String? error;

  const ChatbotState({
    this.selectedConversationId,
    this.queries = const [],
    this.isLoading = false,
    this.error,
  });

  ChatbotState copyWith({
    String? selectedConversationId,
    List<Query>? queries,
    bool? isLoading,
    String? error,
  }) {
    return ChatbotState(
      selectedConversationId:
          selectedConversationId ?? this.selectedConversationId,
      queries: queries ?? this.queries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [selectedConversationId, queries, isLoading, error];
}

class ChatbotCubit extends Cubit<ChatbotState> {
  late final QueryService _queryService;
  late final ConversationService _conversationService;

  ChatbotCubit()
      : super(const ChatbotState()) {
    _queryService = GetIt.instance<QueryService>();
    _conversationService = GetIt.instance<ConversationService>();
  }

  Future<void> selectConversation(String conversationId) async {
    emit(
      state.copyWith(
        selectedConversationId: conversationId,
        isLoading: true,
        error: null,
      ),
    );

    await fetchQueriesForConversation(conversationId);
  }

  Future<void> fetchQueriesForConversation(String conversationId) async {
    try {
      final result = await _queryService.getQueries(
        page: 1,
        perPage: 100,
        conversationId: conversationId,
      );

      result.when(
        ok: (response) {
          emit(
            state.copyWith(
              queries: response.items,
              isLoading: false,
            ),
          );
        },
        err: (error) {
          debugPrint("Error fetching queries: $error");
          emit(
            state.copyWith(
              isLoading: false,
              error: "Failed to load conversation queries",
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Exception fetching queries: $e");
      emit(
        state.copyWith(
          isLoading: false,
          error: "An unexpected error occurred",
        ),
      );
    }
  }

  void clearSelectedConversation() {
    emit(const ChatbotState());
  }
}
