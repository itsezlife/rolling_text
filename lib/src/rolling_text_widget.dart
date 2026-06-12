import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rolling_char.dart';
import 'rolling_text_controller.dart';
import 'rolling_text_options.dart';

/// Measures the natural pixel height of a single line of text for the
/// given [TextStyle]. Forces [height: 1.0] to get the raw font metrics.
double _measureCharHeight(TextStyle style) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: 'A', style: style.copyWith(height: 1.0)),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.height;
}

/// A per-character vertical rolling text animation widget.
///
/// When the text changes, each character rolls through a clipped vertical slot:
/// the old glyph slides out while the new one springs in with configurable
/// stagger and spring physics.
class RollingText extends StatefulWidget {
  /// Creates a [RollingText] driven by the [text] prop.
  ///
  /// Changing [text] triggers the rolling animation automatically.
  /// When [controller] is provided, [text] is ignored.
  const RollingText({
    super.key,
    required this.style,
    this.text,
    this.options = const RollingTextOptions(),
    this.controller,
    this.spacing = 0.0,
    this.respectDisableAnimations = true,
  });

  /// Additional horizontal spacing between character slots.
  final double spacing;

  /// The text string to display and animate.
  ///
  /// When null (and no [controller] is given), an empty string is used.
  final String? text;

  /// Optional [RollingTextController] for programmatic control.
  ///
  /// When provided, the widget observes [RollingTextController.value] and ignores
  /// the [text] parameter.
  final RollingTextController? controller;

  /// The [TextStyle] applied to all characters.
  ///
  /// Changing this at runtime immediately re-measures the slot grid.
  final TextStyle style;

  /// Animation options. Defaults to sensible values.
  final RollingTextOptions options;

  /// Whether to skip animations and snap directly to the final state
  /// if the user has disabled animations at the system level.
  final bool respectDisableAnimations;

  @override
  State<RollingText> createState() => _RollingTextState();
}

class _RollingTextState extends State<RollingText> {
  /// The text currently being shown (or being transitioned TO).
  late String _currentText;

  /// The text being transitioned FROM. Equals [_currentText] when stable.
  late String _previousText;

  /// Measured line height for all slot cells (same for all chars, same style).
  late double _charHeight;

  /// Settle timer to snap back to pristine layout once transition is finished.
  Timer? _settleTimer;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _currentText = _resolveText();
    _previousText = _currentText; // stable initial state
    _charHeight = _measureCharHeight(widget.style);
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(RollingText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }

    if (oldWidget.style != widget.style) {
      _charHeight = _measureCharHeight(widget.style);
    }

    if (widget.controller == null && oldWidget.text != widget.text) {
      _applyNewText(widget.text ?? '');
    }
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _resolveText() =>
      widget.controller?.value ?? widget.text ?? '';

  void _onControllerChanged() {
    final String newText = widget.controller!.value;
    if (newText != _currentText) {
      _applyNewText(newText);
    } else {
      // Rebuild on tick change for wave/shimmer loops
      setState(() {});
    }
  }

  void _applyNewText(String newText) {
    _settleTimer?.cancel();
    setState(() {
      _previousText = _currentText;
      _currentText = newText;
    });

    final int maxLen = math.max(_previousText.length, _currentText.length);
    if (maxLen == 0) return;

    final options = widget.controller?.optionsOverride ?? widget.options;
    final double durationMs = options.duration.inMilliseconds.toDouble();
    final double maxD = durationMs * (1.0 + options.bounce * 0.45);
    final double staggerMs = options.stagger.inMilliseconds.toDouble();
    final double maxStagger = (maxLen - 1) * staggerMs * (1.0 + options.bounce * 0.25);

    final double totalMs = maxStagger +
        options.exitOffset.inMilliseconds +
        maxD +
        (options.color != null ? options.colorFadeDuration.inMilliseconds : 0) +
        150.0;

    _settleTimer = Timer(Duration(milliseconds: totalMs.toInt()), () {
      if (mounted) {
        setState(() {
          _previousText = _currentText;
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final int prevLen = _previousText.length;
    final int currLen = _currentText.length;
    final int maxLen = math.max(prevLen, currLen);

    final bool isTransitioning = _previousText != _currentText;

    // Check system animation status for Reduced Motion accessibility
    final bool disableAnimations = widget.respectDisableAnimations &&
        MediaQuery.disableAnimationsOf(context);

    // Resolve waiting configurations from controller
    final activeWaiting = widget.controller?.activeWaiting;
    final String waitType = activeWaiting?.toString() ?? '';
    final bool isWave = waitType.contains('Wave');
    final bool isShimmer = waitType.contains('Shimmer');

    // Retrieve active options options (handling overrides)
    RollingTextOptions resolvedOptions =
        widget.controller?.optionsOverride ?? widget.options;

    // Implement Shimmer traveling spotlight color highlights
    if (isShimmer && widget.controller != null) {
      final dynamic dynWaiting = activeWaiting;
      Color? shimmerColor;
      try {
        shimmerColor = dynWaiting.color as Color?;
      } catch (_) {}

      final Color highlight = shimmerColor ??
          widget.style.color?.withValues(alpha: 0.5) ??
          const Color(0xFFFFD700); // Gold

      resolvedOptions = resolvedOptions.copyWith(
        restingColor: (index, total) {
          final int activeIndex = widget.controller!.animationTick % total;
          if (index == activeIndex) {
            return highlight;
          }
          final originalResting = widget.options.restingColor;
          if (originalResting != null) {
            return originalResting(index, total);
          }
          return widget.style.color ?? Colors.black;
        },
      );
    }

    return Semantics(
      label: _currentText,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(maxLen, (int i) {
            final String curr = i < currLen ? _currentText[i] : '';
            final String prev = i < prevLen ? _previousText[i] : '';

            // Calculate Wave travel and trigger index
            int animationTrigger = 0;
            bool isWaveActive = false;
            if (isWave && widget.controller != null) {
              final int total = maxLen;
              final int tick = widget.controller!.animationTick;
              int restSteps = 8;
              try {
                final dynamic dynWaiting = activeWaiting;
                final Duration rest = dynWaiting.rest as Duration;
                final Duration interval = dynWaiting.interval as Duration;
                restSteps = (rest.inMilliseconds / interval.inMilliseconds).round();
              } catch (_) {}

              final int cycleLength = total + restSteps;
              final int currentStep = tick % cycleLength;

              if (currentStep == i) {
                animationTrigger = tick;
                isWaveActive = true;
              }
            }

            final bool shouldAnimate = (isTransitioning || isWaveActive) &&
                (!resolvedOptions.skipUnchanged ||
                    curr != prev ||
                    prev.isEmpty ||
                    curr.isEmpty ||
                    isWaveActive);

            return RollingChar(
              key: ValueKey<int>(i),
              currentChar: curr,
              previousChar: prev,
              textStyle: widget.style,
              options: resolvedOptions,
              charIndex: i,
              totalChars: maxLen,
              charHeight: _charHeight,
              animate: disableAnimations ? false : shouldAnimate,
              animationTrigger: animationTrigger,
              spacing: widget.spacing,
              isLast: i == maxLen - 1,
            );
          }),
        ),
      ),
    );
  }
}
