import "package:anc_app/src/assets.dart";
import "package:anc_app/src/colors.dart";

enum Environment {
  test("TEST"),
  local("LOCAL"),
  dev("DEV"),
  prod("PROD");

  final String name;

  const Environment(this.name);

  static Environment fromString(String value) => Environment.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
        orElse: () {
          if (value.isNotEmpty) {
            throw Exception("Invalid environment $value");
          }
          return Environment.dev;
        },
      );
}

enum AppEnvLocale {
  us("us"),
  eu("eu"),
  ;

  final String name;

  const AppEnvLocale(this.name);

  static AppEnvLocale fromString(String value) =>
      AppEnvLocale.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
        orElse: () {
          if (value.isNotEmpty) {
            throw Exception("Invalid locale $value");
          }
          return AppEnvLocale.us;
        },
      );
}

enum Flavor {
  ancapp(
    "Ancap",
    "ancapp",
    "Ancap",
    FlavorAssets.ancapp,
    FlavorColors.ancapp,
  ),
  ;

  static Flavor fromString(String value) => Flavor.values.firstWhere(
        (e) => e.key.toUpperCase() == value.toUpperCase(),
        orElse: () => Flavor.ancapp,
      );

  final String key;
  final String id;
  final String title;
  final FlavorAssets assets;
  final FlavorColors colors;

  const Flavor(
    this.key,
    this.id,
    this.title,
    this.assets,
    this.colors,
  );
}

enum AppLogLevel {
  debug(
    0,
    "debug",
    "🔍|D| ",
  ),
  info(
    1,
    "info",
    "💬|I| ",
  ),
  warn(
    2,
    "warn",
    "⚠️|W| ",
  ),
  error(
    3,
    "error",
    "🐞|E| ",
  );

  const AppLogLevel(
    this.priority,
    this.name,
    this.visualizer,
  );

  final int priority;
  final String name;
  final String visualizer;

  static AppLogLevel fromString(String name) {
    return AppLogLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => AppLogLevel.debug,
    );
  }

  static AppLogLevel parse(dynamic value) => AppLogLevel.fromString(value);
}
