import 'dart:ui';

/// Configuration for waiting animations on [RollingText].
sealed class RollingWaiting {
  /// Base constructor for [RollingWaiting].
  const RollingWaiting();

  /// Cycles dots at the end of the text.
  /// E.g. "Loading" -> "Loading." -> "Loading.." -> "Loading..."
  const factory RollingWaiting.ellipsis({
    Duration interval,
  }) = _Ellipsis;

  /// Wave effect that animates characters to themselves using spring physics.
  /// Staggers across the text from left to right.
  const factory RollingWaiting.wave({
    Duration interval,
    Duration rest,
  }) = _Wave;

  /// Shimmer effect that shifts a temporary color spotlight across the characters
  /// without rolling the text itself.
  const factory RollingWaiting.shimmer({
    Duration interval,
    Color? color,
  }) = _Shimmer;

  /// A completely custom waiting animation builder.
  /// Takes the base text and current tick, returning the text for that frame.
  const factory RollingWaiting.builder(
    String Function(String text, int tick) builder, {
    Duration interval,
  }) = _Builder;
}

class _Ellipsis extends RollingWaiting {
  /// Creates an ellipsis waiting animation configuration.
  const _Ellipsis({
    this.interval = const Duration(milliseconds: 400),
  });

  /// The duration of each animation step.
  final Duration interval;
}

class _Wave extends RollingWaiting {
  /// Creates a wave waiting animation configuration.
  const _Wave({
    this.interval = const Duration(milliseconds: 150),
    this.rest = const Duration(milliseconds: 1200),
  });

  /// The duration between character triggers in the wave.
  final Duration interval;

  /// The rest duration between wave cycles.
  final Duration rest;
}

class _Shimmer extends RollingWaiting {
  /// Creates a shimmer waiting animation configuration.
  const _Shimmer({
    this.interval = const Duration(milliseconds: 120),
    this.color,
  });

  /// The speed of the shimmer spotlight movement.
  final Duration interval;

  /// The color of the shimmer spotlight highlight.
  final Color? color;
}

class _Builder extends RollingWaiting {
  /// Creates a custom waiting animation builder configuration.
  const _Builder(
    this.builder, {
    this.interval = const Duration(milliseconds: 200),
  });

  /// The custom frame builder.
  final String Function(String text, int tick) builder;

  /// The duration of each animation step.
  final Duration interval;
}
