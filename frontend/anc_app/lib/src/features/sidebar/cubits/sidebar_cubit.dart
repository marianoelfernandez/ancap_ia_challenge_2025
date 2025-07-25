import "package:anc_app/src/features/auth/services/auth_service.dart";
import "package:anc_app/src/features/chatbot/services/conversation_service.dart";
import "package:anc_app/src/models/conversation.dart";
import "package:anc_app/src/models/user.dart";
import "package:bloc/bloc.dart";
import "package:equatable/equatable.dart";
import "package:flutter/foundation.dart";
import "package:get_it/get_it.dart";

class SidebarState extends Equatable {
  final List<Conversation> recentConversations;
  final bool isLoading;
  final String? error;
  final User? currentUser;
  final String searchQuery;
  final String? selectedConversationId; // Add this field

  List<Conversation> get filteredConversations {
    if (searchQuery.isEmpty) {
      return recentConversations;
    }

    final query = searchQuery.toLowerCase();
    return recentConversations.where((conversation) {
      final title = _extractConversationTitle(conversation).toLowerCase();
      return title.contains(query);
    }).toList();
  }

  String _extractConversationTitle(Conversation conversation) {
    try {
      if (conversation.conversation.isNotEmpty) {
        return conversation.conversation.split("\n").first.trim().substring(
              0,
              min(
                50,
                conversation.conversation.split("\n").first.trim().length,
              ),
            );
      }
      return "Conversation ${conversation.id.substring(0, min(8, conversation.id.length))}";
    } catch (e) {
      return "Conversation ${conversation.id.substring(0, min(8, conversation.id.length))}";
    }
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }

  const SidebarState({
    this.recentConversations = const [],
    this.isLoading = false,
    this.error,
    this.currentUser,
    this.searchQuery = "",
    this.selectedConversationId, // Add this parameter
  });

  SidebarState copyWith({
    List<Conversation>? recentConversations,
    bool? isLoading,
    String? error,
    User? currentUser,
    String? searchQuery,
    String? selectedConversationId, // Add this parameter
  }) {
    return SidebarState(
      recentConversations: recentConversations ?? this.recentConversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentUser: currentUser ?? this.currentUser,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedConversationId: selectedConversationId ??
          this.selectedConversationId, // Add this line
    );
  }

  @override
  List<Object?> get props => [
        recentConversations,
        isLoading,
        error,
        currentUser,
        searchQuery,
        selectedConversationId,
      ]; // Add selectedConversationId to props
}

class SidebarCubit extends Cubit<SidebarState> {
  final ConversationService _conversationService;
  final AuthService _authService;

  SidebarCubit({
    ConversationService? conversationService,
    AuthService? authService,
  })  : _conversationService =
            conversationService ?? GetIt.instance<ConversationService>(),
        _authService = authService ?? GetIt.instance<AuthService>(),
        super(const SidebarState()) {
    loadUser();
  }

  Future<void> loadRecentConversations() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final user = _authService.getCurrentUser();
      debugPrint("SidebarCubit: Got user: $user");

      if (user == null) {
        debugPrint("SidebarCubit: User is null");
        emit(state.copyWith(error: "User not authenticated", isLoading: false));
        return;
      }

      emit(state.copyWith(currentUser: user));

      final userId = user.id;

      debugPrint("SidebarCubit: Fetching conversations for user: $userId");

      final result = await _conversationService.getConversations(
        page: 1,
        perPage: 20,
        userId: userId,
        sortByCreationDateDesc: true,
      );

      result.when(
        ok: (conversationsResponse) {
          debugPrint(
            "SidebarCubit: Loaded ${conversationsResponse.items.length} conversations",
          );
          emit(
            state.copyWith(
              recentConversations: conversationsResponse.items,
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

  void refreshConversations() {
    loadRecentConversations();
  }

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
    debugPrint("SidebarCubit: Search query updated to: $query");
  }

  void clearSearchQuery() {
    emit(state.copyWith(searchQuery: ""));
    debugPrint("SidebarCubit: Search query cleared");
  }

  void setSelectedConversation(String? conversationId) {
    emit(state.copyWith(selectedConversationId: conversationId));
    debugPrint("SidebarCubit: Selected conversation set to: $conversationId");
  }

  void clearSelectedConversation() {
    emit(state.copyWith(selectedConversationId: null));
    debugPrint("SidebarCubit: Selected conversation cleared");
  }

  Future<void> loadUser() async {
    try {
      final user = _authService.getCurrentUser();
      debugPrint("SidebarCubit: Got user in loadUser(): $user");

      if (user == null) {
        debugPrint("SidebarCubit: User is null in loadUser()");
        return;
      }

      emit(state.copyWith(currentUser: user));
    } catch (e) {
      debugPrint("SidebarCubit: Exception getting user: $e");
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint("SidebarCubit: Signing out user");
      final result = await _authService.signOut();
      result.when(
        ok: (_) {
          debugPrint("SidebarCubit: Sign out successful");
          emit(
            state.copyWith(
              currentUser: null,
              recentConversations: [],
              selectedConversationId: null,
            ),
          );
        },
        err: (error) {
          debugPrint("SidebarCubit: Sign out error: $error");
          emit(state.copyWith(error: "Failed to sign out"));
        },
      );
    } catch (e) {
      debugPrint("SidebarCubit: Exception during sign out: $e");
      emit(state.copyWith(error: "Failed to sign out"));
    }
  }
}
