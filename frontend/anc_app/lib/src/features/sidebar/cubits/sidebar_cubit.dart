// Auth service not directly used, only PocketBase for user ID
import "package:anc_app/src/features/auth/services/auth_service.dart";
import "package:anc_app/src/features/chatbot/services/conversation_service.dart";
import "package:anc_app/src/models/conversation.dart";
import "package:anc_app/src/models/user.dart";
import "package:bloc/bloc.dart";
import "package:equatable/equatable.dart";
import "package:flutter/foundation.dart";
import "package:get_it/get_it.dart";

// Define the sidebar state
class SidebarState extends Equatable {
  final List<Conversation> recentConversations;
  final bool isLoading;
  final String? error;
  final User? currentUser;

  const SidebarState({
    this.recentConversations = const [],
    this.isLoading = false,
    this.error,
    this.currentUser,
  });

  // Create a copy of the state with updated values
  SidebarState copyWith({
    List<Conversation>? recentConversations,
    bool? isLoading,
    String? error,
    User? currentUser,
  }) {
    return SidebarState(
      recentConversations: recentConversations ?? this.recentConversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentUser: currentUser ?? this.currentUser,
    );
  }

  @override
  List<Object?> get props => [recentConversations, isLoading, error, currentUser];
}

// Define the sidebar cubit
class SidebarCubit extends Cubit<SidebarState> {
  final ConversationService _conversationService;
  final AuthService _authService; // To access the current user ID

  SidebarCubit({
    ConversationService? conversationService,
    AuthService? authService,
  })  : _conversationService =
            conversationService ?? GetIt.instance<ConversationService>(),
        _authService = authService ?? GetIt.instance<AuthService>(),
        super(const SidebarState());

  // Load recent conversations for the current user
  Future<void> loadRecentConversations() async {
    debugPrint("SidebarCubit: Loading recent conversations");

    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Get the current user using the updated function
      final user = _authService.getCurrentUserId();
      debugPrint("SidebarCubit: Got user: $user");

      // If user is null, the user is not authenticated
      if (user == null) {
        debugPrint("SidebarCubit: User is null");
        emit(state.copyWith(error: "User not authenticated", isLoading: false));
        return;
      }
      
      // Store the user in the state
      emit(state.copyWith(currentUser: user));
      
      // Extract user ID from the User model
      final userId = user.id;

      debugPrint("SidebarCubit: Fetching conversations for user: $userId");
      final result = await _conversationService.getConversations(
        page: 1,
        perPage: 10, // Limit to 10 recent conversations
        userId: userId,
      );

      result.when(
        ok: (response) {
          debugPrint(
            "SidebarCubit: Successfully got conversations: ${response.items.length} items",
          );
          if (response.items.isEmpty) {
            debugPrint("SidebarCubit: No conversations found for user");
          } else {
            for (var conversation in response.items) {
              debugPrint(
                "SidebarCubit: Conversation ID: ${conversation.id}, userId: ${conversation.userId}",
              );
            }
          }

          emit(
            state.copyWith(
              recentConversations: response.items,
              isLoading: false,
            ),
          );
        },
        err: (error) {
          debugPrint("SidebarCubit: Error getting conversations: $error");
          emit(
            state.copyWith(
              isLoading: false,
              error: error.toString(),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("SidebarCubit: Exception getting conversations: $e");
      emit(
        state.copyWith(
          isLoading: false,
          error: "Failed to load conversations: ${e.toString()}",
        ),
      );
    }
  }

  // Refresh conversations (useful after creating a new conversation)
  void refreshConversations() {
    loadRecentConversations();
  }
}
