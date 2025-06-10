import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:anc_app/src/build_args.dart";
import "package:toml/toml.dart";

/// [EnvKey] is a list of all the environment variables used in the app.
/// To add a new env var, add a new enum value.
///
/// [defaultValue] is the value to use if the env value is not defined.
///
/// [path] is the path to the value in the toml file.
/// For example, if you have a toml file with the following content:
/// [general.title]
/// name = "My App"
///
/// Your path would be "general.title.name"
///
/// If the key depends on Platform, Locale or any other runtime variable, use
/// the [localeCard] or [platformCard] to replace the value in the path at
/// runtime. Add new runtime variables if needed.
///
/// For example, if you have a toml file with the following content:
/// [us.title]
/// name = "My App in the US"
/// [eu.title]
/// name = "My App in the EU"
///
/// Your path would be "$[localeCard].title.name".
/// At runtime, us.title will be used if the locale is US.
/// And eu.title will be used if the locale is EU.
///
/// If the env value is not a primitive type, add a [parser] function.
/// The [parser] function receives the value from the toml file and returns the
/// value to be used.
/// It has to be a constant expression. See [_appLogLevelParser] as an example.
enum EnvKey<T> {
  easteregg<bool>(
    path: "$localeCard.easter_egg",
    defaultValue: false,
  ),
  logLevel<AppLogLevel>(
    path: "general.log_level",
    defaultValue: AppLogLevel.info,
    parser: AppLogLevel.parse,
  ),
  apiUrl(
    path: "general.api_url",
    defaultValue: "",
  ),
  ;

  final String path;
  final T? defaultValue;
  final T Function(dynamic)? parser;

  const EnvKey({required this.path, this.defaultValue, this.parser});

  @override
  String toString() => name;
}

const String localeCard = "{locale}";
const String platformCard = "{platform}";

/// [AppEnv] is a singleton class that holds all the environment variables.
///
/// [load] -- loads the environment variables from the toml env file.
///
/// [read] -- reads the value of an environment variable.
///
/// [flavor] -- returns the current tenant.
///
/// [environment] -- returns the current environment.
///
/// [isAndroid] -- returns true if the current platform is Android.
///
/// [isIOS] -- returns true if the current platform is iOS.
///
/// [isReleaseMode] -- returns true if the app is running in release mode.
///
/// [isDebugMode] -- returns true if the app is running in debug mode.
///
/// [isProfileMode] -- returns true if the app is running in profile mode.
///
/// [loadTesting] -- is used to load the environment variables in tests.
///
/// The environment variables are loaded from the toml file and are stored in the [_values] map.
/// The map is used to read the values of the environment variables.
/// All EnvKeys must have a value after loaded. This is checked in the [_verifyAllValuesInitialized] method.
class AppEnv {
  static AppEnv instance = AppEnv();
  static AppEnv get I => instance;
  static bool _isInitialized = false; // used to prevent loading twice

  AppEnv();

  T read<T>(EnvKey<T> key) =>
      _values[key] != null ? _values[key] as T : key.defaultValue!;
  final Map<EnvKey, dynamic> _values = {};

  Flavor get flavor => _flavor!;
  static Flavor? _flavor;

  Environment get environment => _env!;
  static Environment? _env;

  AppEnvLocale get locale => _locale!;
  static AppEnvLocale? _locale;

  static String _buildEnvFilePath(String environment, String tenant) =>
      "assets/env/$environment.$tenant.toml";

  void _loadValues(AppEnvLocale locale, Map<String, dynamic> values) =>
      EnvKey.values.forEach(
        (key) => _assign(
          key,
          _read(key, locale, values),
        ),
      );

  T? _read<T>(EnvKey<T> key, AppEnvLocale locale, Map<String, dynamic> values) {
    final path = key.path
        .replaceAll(
          localeCard,
          locale.name,
        )
        .replaceAll(
          platformCard,
          _platformKey,
        );
    final parts = path.split(".");
    dynamic value = values;
    for (final part in parts) {
      if (value is Map<String, dynamic>) {
        value = value[part];
      } else {
        value = null;
        break;
      }
    }
    return value;
  }

  void _verifyAllValuesInitialized() {
    EnvKey.values.forEach((key) {
      if (_values[key] == null) {
        throw Exception(
          "Env key ${key.name} was not loaded correctly",
        );
      }
    });
  }

  Future<void> load({
    AppEnvLocale locale = AppEnvLocale.us,
  }) async {
    if (_isInitialized) {
      debugPrint("*** WARNING: environment already initialized ***");
      return;
    }
    // Read build arguments
    _flavor = Flavor.fromString(
      const String.fromEnvironment(
        "TENANT",
      ),
    );
    _env = Environment.fromString(
      const String.fromEnvironment(
        "ENV",
      ),
    );
    _locale = locale;

    // Read the rest of the env variables from the toml file
    final tenant = _flavor!.key.toLowerCase();
    final environment = _env!.name.toLowerCase();
    final envFilePath = _buildEnvFilePath(environment, tenant);
    final tomlContent = await rootBundle.loadString(envFilePath);
    final doc = TomlDocument.parse(tomlContent);
    final valuesFromToml = doc.toMap();

    // Pretty print the env variables
    debugPrint("Environment: $environment");
    debugPrint("Tenant: $tenant");
    debugPrint("Locale: ${locale.name}");
    debugPrint("Env file $envFilePath content:");
    JsonEncoder encoder = const JsonEncoder.withIndent("  ");
    String prettyprint = encoder.convert(valuesFromToml);
    debugPrint(prettyprint);

    // Load env variables in memory and verify that all variables were loaded
    debugPrint("Loading variables from file");
    _loadValues(locale, valuesFromToml);
    debugPrint("Variables all variables where loaded");
    _verifyAllValuesInitialized();
    _isInitialized = false;

    // Print the env variables
    debugPrint("Env keys loaded:");
    for (final key in _values.keys) {
      debugPrint("${key.name}: ${read(key)}");
    }
  }

  @visibleForTesting
  Future<void> loadTesting({
    AppEnvLocale locale = AppEnvLocale.us,
    Flavor tenant = Flavor.ancapp,
    Environment environment = Environment.test,
    Map<EnvKey, dynamic> values = const {},
    bool verifyValues = false,
    bool reset = true,
  }) async {
    if (_isInitialized && !reset) {
      debugPrint("*** WARNING: environment already initialized ***");
      return;
    }
    if (reset) {
      _isInitialized = false;
      _values.clear();
    }
    _flavor = tenant;
    _env = environment;
    _locale = locale;

    debugPrint("Environtment: ${environment.name}");
    debugPrint("Tenant: ${tenant.key}");
    debugPrint("Locale: ${locale.name}");

    for (final key in values.keys) {
      _assign(key, values[key]);
    }
    if (verifyValues) {
      _verifyAllValuesInitialized();
    }

    _isInitialized = true;

    debugPrint("Env keys loaded:");
    for (final key in _values.keys) {
      debugPrint("${key.name}: ${read(key)}");
    }
  }

  void _assign<T>(EnvKey<T> e, dynamic readValue) {
    var value = readValue ?? e.defaultValue;
    if (value == null) {
      throw Exception(
        "Env key ${e.name} is not defined in the environment",
      );
    }
    if (e.parser != null) {
      value = e.parser!(value);
    }
    if (value is! T) {
      throw Exception(
        "Env key ${e.name} is not of type ${T.toString()}",
      );
    }
    _values[e] = value;
  }

  String get _platformKey => currentPlatform.name.toLowerCase();

  TargetPlatform get currentPlatform => defaultTargetPlatform;

  bool get isAndroid => currentPlatform == TargetPlatform.android;

  bool get isIOS => currentPlatform == TargetPlatform.iOS;
}

extension BuildMode on AppEnv {
  bool get isReleaseMode => kReleaseMode;

  bool get isDebugMode => kDebugMode;

  bool get isProfileMode => kProfileMode;
}
