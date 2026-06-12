import 'package:flutter/material.dart';

/// The direction characters roll during a [RollingText] transition.
enum RollingDirection {
  /// Characters roll upward — new text enters from below the clip boundary.
  up,

  /// Characters roll downward — new text enters from above the clip boundary.
  down,
}

/// Immutable configuration for a [RollingText] animation.
///
/// Configures the animation behavior of a [RollingText] widget.
@immutable
class RollingTextOptions {
  /// Creates a [RollingTextOptions] with the given parameters.
  ///
  /// All parameters are optional and have sensible defaults that match the
  /// the rolling_text package defaults.
  const RollingTextOptions({
    this.direction = RollingDirection.down,
    this.stagger = const Duration(milliseconds: 45),
    this.duration = const Duration(milliseconds: 300),
    this.exitOffset = const Duration(milliseconds: 50),
    this.bounce = 0.6,
    this.springMass = 1.0,
    this.springStiffness = 200.0,
    this.springDamping = 22.0,
    this.color,
    this.restingColor,
    this.colorFadeDuration = const Duration(milliseconds: 280),
    this.skipUnchanged = true,
    this.interrupt = true,
    this.fadeEdges = 0.0,
  })  : assert(
          bounce >= 0.0 && bounce <= 1.0,
          'bounce must be between 0.0 and 1.0',
        ),
        assert(
          fadeEdges >= 0.0 && fadeEdges <= 0.5,
          'fadeEdges must be between 0.0 and 0.5',
        );

  /// The direction characters roll when transitioning.
  ///
  /// [RollingDirection.down] — characters enter from above (roll downward).
  /// [RollingDirection.up]   — characters enter from below (roll upward).
  final RollingDirection direction;

  /// Additional delay between each character starting its animation.
  ///
  /// Each character at index `i` starts `i * stagger` after the first.
  /// Default: 45ms.
  final Duration stagger;

  /// Duration of the slide animation for each individual character.
  ///
  /// Default: 300ms.
  final Duration duration;

  /// How long the entering glyph trails behind the exiting one.
  ///
  /// A higher value creates a more dramatic "chase" effect where the old char
  /// has already started moving before the new one begins. Default: 50ms.
  final Duration exitOffset;

  /// Per-character spring personality (0.0 = uniform, 1.0 = maximum variance).
  ///
  /// Adds a deterministic stiffness variance per character position, giving
  /// each glyph a slightly different bounce feel on landing. Default: 0.6.
  final double bounce;

  /// Mass of the spring simulation (affects inertia feel). Default: 1.0.
  final double springMass;

  /// Stiffness of the spring simulation (higher = snappier landing). Default: 200.0.
  final double springStiffness;

  /// Damping of the spring simulation (lower = more overshoot). Default: 22.0.
  ///
  /// Values above 2 * sqrt(mass * stiffness) are overdamped (no bounce).
  final double springDamping;

  /// Optional per-character chromatic color tint during roll-in.
  ///
  /// Called once per animated character with `(index, totalChars)`. When the
  /// animation settles, the tint fades back to [restingColor] (if set) or
  /// `style.color`.
  ///
  /// Use the [chromatic] helper for a built-in rainbow sweep:
  /// ```dart
  /// RollingTextOptions(color: chromatic())
  /// ```
  final Color Function(int index, int total)? color;

  /// Optional per-character color applied when the slot is at **rest**
  /// (not animating).
  ///
  /// Called with `(index, totalChars)` and replaces `style.color` as the
  /// permanent per-slot color. This lets you paint static gradient text,
  /// branded character tints, or any per-position coloring without needing
  /// an animation trigger.
  ///
  /// When [color] (chromatic tint) is also set, the roll-in tint lerps toward
  /// [restingColor] rather than `style.color` after the animation settles.
  ///
  /// ```dart
  /// // Permanent rainbow across all characters at rest:
  /// RollingTextOptions(restingColor: chromatic())
  ///
  /// // Chromatic roll-in that settles into a different permanent rainbow:
  /// RollingTextOptions(
  ///   color: chromatic(from: 0, spread: 320),
  ///   restingColor: chromatic(from: 180, spread: 120),
  /// )
  /// ```
  final Color Function(int index, int total)? restingColor;

  /// How long the chromatic tint takes to fade back to the resting text color.
  ///
  /// Only relevant when [color] is set. Default: 280ms.
  final Duration colorFadeDuration;

  /// Whether to skip animating characters that are identical at the same index.
  ///
  /// When `true` (default), characters at the same position that haven't changed
  /// remain static. Ideal for aligned labels like "Copy → Copied".
  final bool skipUnchanged;

  /// Whether a new animation interrupts one currently in progress.
  ///
  /// - `true` (default): snaps in-flight characters to their targets, then
  ///   starts the new transition immediately.
  /// - `false`: waits for the current transition to settle before starting
  ///   the next one. Ideal for rapid-fire triggers like buttons.
  final bool interrupt;

  /// Fraction of the slot height faded to transparent at the top and bottom
  /// edges of each character cell (0.0–0.5).
  ///
  /// Produces the classic odometer / slot-machine "depth" effect where digits
  /// appear to emerge from and disappear into a glowing slit. Implemented via
  /// a [ShaderMask] with a [LinearGradient] using `BlendMode.dstIn`.
  ///
  /// - `0.0` (default) — no fade, no [ShaderMask] overhead.
  /// - `0.15` — subtle, suitable for number rollers in light UI.
  /// - `0.25` — pronounced, ideal for dark-themed odometers.
  /// - `0.5` — maximum: full fade from edges to center.
  ///
  /// ⚠️ Each non-zero [RollingChar] creates one compositing layer. For texts
  /// longer than ~15 characters consider leaving this at `0.0` on low-end
  /// devices.
  final double fadeEdges;

  /// Returns a copy of this options object with the given fields replaced.
  RollingTextOptions copyWith({
    RollingDirection? direction,
    Duration? stagger,
    Duration? duration,
    Duration? exitOffset,
    double? bounce,
    double? springMass,
    double? springStiffness,
    double? springDamping,
    Color Function(int index, int total)? color,
    Color Function(int index, int total)? restingColor,
    Duration? colorFadeDuration,
    bool? skipUnchanged,
    bool? interrupt,
    double? fadeEdges,
  }) {
    return RollingTextOptions(
      direction: direction ?? this.direction,
      stagger: stagger ?? this.stagger,
      duration: duration ?? this.duration,
      exitOffset: exitOffset ?? this.exitOffset,
      bounce: bounce ?? this.bounce,
      springMass: springMass ?? this.springMass,
      springStiffness: springStiffness ?? this.springStiffness,
      springDamping: springDamping ?? this.springDamping,
      color: color ?? this.color,
      restingColor: restingColor ?? this.restingColor,
      colorFadeDuration: colorFadeDuration ?? this.colorFadeDuration,
      skipUnchanged: skipUnchanged ?? this.skipUnchanged,
      interrupt: interrupt ?? this.interrupt,
      fadeEdges: fadeEdges ?? this.fadeEdges,
    );
  }
}
