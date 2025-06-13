import "dart:async";
import "package:anc_app/src/env.dart";
import "package:get_it/get_it.dart";
import "package:pocketbase/pocketbase.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:anc_app/src/features/auth/services/auth_service.dart";
import "package:anc_app/src/adapters/auth_pocketbase_service.dart";
import "package:anc_app/src/features/chatbot/services/chat_service.dart";

Future<void> setupDI() async {
  final getIt = GetIt.instance;

  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  await sharedPreferences.reload();

  final pb = PocketBase(AppEnv.I.read(EnvKey.apiUrl));
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  getIt.registerSingleton<AuthService>(
    AuthPocketBaseService(
      pocketBase: pb,
    ),
  );

  getIt.registerSingleton<ChatService>(ChatService());
}
