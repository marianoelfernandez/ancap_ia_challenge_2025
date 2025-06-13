import "dart:async";
import "package:anc_app/src/adapters/conversation_pocketbase_service.dart";
import "package:anc_app/src/env.dart";
import "package:get_it/get_it.dart";
import "package:pocketbase/pocketbase.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:anc_app/src/features/auth/services/auth_service.dart";
import "package:anc_app/src/adapters/auth_pocketbase_service.dart";
import "package:anc_app/src/features/chatbot/services/conversation_service.dart";
import "package:anc_app/src/features/chatbot/services/query_service.dart";
import "package:anc_app/src/adapters/query_pocketbase_service.dart";
import "package:anc_app/src/features/chatbot/services/chat_service.dart";

Future<void> setupDI() async {
  final getIt = GetIt.instance;

  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  await sharedPreferences.reload();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  final store = AsyncAuthStore(
    save: (String data) async => sharedPreferences.setString("pb_auth", data),
    initial: (sharedPreferences.getString("pb_auth")?.isEmpty ?? true)
        ? null
        : sharedPreferences.getString("pb_auth"),
  );

  final pb = PocketBase(AppEnv.I.read(EnvKey.apiUrl), authStore: store);

  getIt.registerSingleton<AuthService>(
    AuthPocketBaseService(
      pocketBase: pb,
    ),
  );

  getIt.registerSingleton<ConversationService>(
    ConversationPocketbaseService(pb),
  );

  getIt.registerSingleton<QueryService>(
    QueryPocketbaseService(pb),
  );
  getIt.registerSingleton<ChatService>(ChatService());
}
