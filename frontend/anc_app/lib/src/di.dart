import "dart:async";

import "package:get_it/get_it.dart";
import "package:shared_preferences/shared_preferences.dart";

Future<void> setupDI() async {
  final getIt = GetIt.instance;

  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  await sharedPreferences.reload();
  // AuthService authService = AuthServiceMock();

  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  //..registerSingleton<AuthService>(authService);
}
