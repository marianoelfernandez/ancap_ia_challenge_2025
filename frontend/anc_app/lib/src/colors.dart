import "package:flutter/material.dart";

/// Colors used by all tenants are defined as default values in the constructor.
/// Each tenant can override the default by defining their own value in the [FlavorColors] enum constructor.
/// If there is no default value, make it required.
enum FlavorColors {
  ancapp(
    primary: Colors.black,
    background: Colors.white,
  ),
  ;

  const FlavorColors({
    required this.primary,
    required this.background,
  });

  final Color primary;
  final Color background;
}
