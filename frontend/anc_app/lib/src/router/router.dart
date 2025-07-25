// GoRouter configuration
import "dart:async";

import "package:anc_app/src/features/auth/cubits/auth_cubit.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:go_router/go_router.dart";
import "package:anc_app/src/router/screen_params.dart";
import "package:anc_app/src/features/auth/screens/login_screen.dart";
import "package:anc_app/src/features/chatbot/screens/chatbot_screen.dart";
import "package:anc_app/src/features/splash/screens/splash_screen.dart"; // Added splash screen import
import "package:anc_app/src/features/audit/screen/audit_screen.dart"; // Added audit screen import
import "package:anc_app/src/features/dashboard/screens/dashboard_screen.dart";

/// All the routes in the app are defined here
///
/// [path] is the route path
/// [isAuthEnforcementRequired] flag is used to determine if the route requires authentication
/// [ParamsType] is the type of the query parameters for the route.
/// Use [NoParams] if the route does not have any query parameters
///
/// To add a new route:
/// 1. Add a new route enum value.
/// 2. If the route has query parameters, specify the type of the query
///    parameters in the enum value.
/// 3. Add a new GoRoute in the [buildRouter] function.
enum AppRoute<ParamsType extends ScreenParams<ParamsType>> {
  initial<NoParams>(
    path: "/",
    isAuthEnforcementRequired: false,
  ),
  home<NoParams>(
    path: "/home",
    isAuthEnforcementRequired: true,
  ),
  dashboard<NoParams>(
    path: "/dashboard",
    isAuthEnforcementRequired: true,
  ),
  chatbot<ChatbotParams>(
    path: "/chatbot",
    isAuthEnforcementRequired: true,
  ),
  splash<NoParams>(
    path: "/splash",
    isAuthEnforcementRequired: false,
  ),
  audit<NoParams>(
    path: "/audit",
    isAuthEnforcementRequired: true,
  ),
  ;

  final String path;
  final bool isAuthEnforcementRequired;

  const AppRoute({
    required this.path,
    required this.isAuthEnforcementRequired,
  });

  static AppRoute fromPath(String path) {
    return AppRoute.values.firstWhere(
      (e) => e.path.toLowerCase() == path.toLowerCase(),
      orElse: () => AppRoute.initial,
    );
  }

  static AppRoute fromString(String nameOrFullPath) {
    return AppRoute.values.firstWhere(
      (e) => nameOrFullPath.toLowerCase().contains(e.name.toLowerCase()),
      orElse: () => AppRoute.initial,
    );
  }

  @override
  String toString() => path;
}

final router = buildRouter();

GoRouter buildRouter({
  String initialLocation = "/",
}) =>
    GoRouter(
      debugLogDiagnostics: true,
      initialLocation: initialLocation,
      routes: [
        ShellRoute(
          builder: _wrapWithAuthEnforcer,
          routes: [
            // Example route:
            // GoRoute(
            //   name: AppRoute.initial.name,
            //   path: AppRoute.initial.path,
            //   builder: (context, state) => const SplashScreen(),
            // ),
            GoRoute(
              name: AppRoute.initial.name,
              path: AppRoute.initial.path,
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
              name: AppRoute.chatbot.name,
              path: AppRoute.chatbot.path,
              builder: (context, state) {
                final conversationId =
                    state.uri.queryParameters["conversation"];
                return ChatbotScreen(initialConversationId: conversationId);
              },
            ),
            GoRoute(
              name: AppRoute.splash.name,
              path: AppRoute.splash.path,
              builder: (context, state) => const SplashScreen(),
            ),
            GoRoute(
              name: AppRoute.audit.name,
              path: AppRoute.audit.path,
              builder: (context, state) => const AuditScreen(),
            ),
            GoRoute(
              name: AppRoute.dashboard.name,
              path: AppRoute.dashboard.path,
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
      ],
    );

/// Extension to navigate to a named route with typed query parameters
/// It will infer the type of the query parameters from the type of the route enum
/// This extension is needed for type safety when navigating to a route with query parameters
extension GoNamedWithTypedParams on BuildContext {
  Future<void> goToAppRoute<T extends ScreenParams<T>>(
    AppRoute<T> appRoute, {
    T? queryParams,
    bool pushOnTop = false,
  }) async {
    final paramsMap = queryParams?.toMap() ?? <String, String>{};

    if (pushOnTop) {
      await pushNamed(
        appRoute.name,
        queryParameters: paramsMap,
      );
    } else {
      goNamed(
        appRoute.name,
        queryParameters: paramsMap,
      );
    }
  }
}

Widget _wrapWithAuthEnforcer(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final appRoute = AppRoute.fromString(state.name ?? state.fullPath ?? "");
  if (appRoute.isAuthEnforcementRequired) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (!authState.isAuthenticated) {
          return const LoginScreen();
        }
        return child;
      },
    );
  } else {
    return child;
  }
}
