import 'package:flutter/material.dart';

/// Returns a per-character color function that sweeps the hue across characters,
/// producing a chromatic rainbow/spectrum tint during the roll-in animation.
///
/// Pass the result to [RollingTextOptions.color]:
/// ```dart
/// RollingTextOptions(color: chromatic())
/// RollingTextOptions(color: chromatic(from: 18))  // warm gold start
/// RollingTextOptions(color: chromatic(spread: 60)) // tight analogous hues
/// ```
///
/// Parameters:
/// - [from] — starting hue (0–360). Default 0 (red).
/// - [spread] — total hue degrees swept across all characters. Default 320.
/// - [saturation] — HSL saturation (0.0–1.0). Default 0.92.
/// - [lightness] — HSL lightness (0.0–1.0). Default 0.60.
Color Function(int index, int total) chromatic({
  double from = 0,
  double spread = 320,
  double saturation = 0.92,
  double lightness = 0.60,
}) {
  assert(saturation >= 0 && saturation <= 1, 'saturation must be 0.0–1.0');
  assert(lightness >= 0 && lightness <= 1, 'lightness must be 0.0–1.0');

  return (int index, int total) {
    final double t = total <= 1 ? 0.0 : index / (total - 1);
    final double hue = (from + t * spread) % 360;
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  };
}
