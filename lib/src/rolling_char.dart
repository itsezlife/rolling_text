import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'rolling_text_options.dart';

/// Non-breaking space — replaces regular space to preserve cell width.
const String _kNbsp = '\u00A0';

/// Returns [char] ready for display. Spaces become non-breaking spaces so the
/// cell retains its natural width even when the character is a plain space.
String _glyph(String char) => char == ' ' ? _kNbsp : char;

/// Measures the natural pixel width of a single rendered character.
///
/// Uses [TextPainter] with [height: 1.0] to ensure consistent, predictable
/// measurements regardless of the consumer's [TextStyle.height] setting.
double _measureCharWidth(String char, TextStyle style) {
  if (char.isEmpty) return 0.0;
  final TextPainter painter = TextPainter(
    text: TextSpan(text: _glyph(char), style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width;
}

/// Custom clipper that restricts rendering only on the **Y axis**.
///
/// Horizontally the clip path extends ±512 logical pixels past the widget
/// bounds so characters that are wider than their slot can paint freely during
/// a transition without being clipped on the sides.
/// Only [height] (= charHeight) is enforced on the vertical axis, preventing
/// the spring overshoot from bleeding above or below the character cell.
class _YOnlyClipper extends CustomClipper<Path> {
  const _YOnlyClipper({required this.height});

  final double height;

  @override
  Path getClip(Size size) => Path()
    // 512 lp horizontal padding is generous for even large font sizes;
    // characters rarely exceed ~10× their em-square during a transition.
    ..addRect(Rect.fromLTWH(-512, 0, size.width + 1024, height));

  @override
  bool shouldReclip(_YOnlyClipper old) => old.height != height;
}

/// A single animated character cell within a [RollingText] widget.
///
/// Each [RollingChar] independently manages:
/// - An **exit** [AnimationController] that slides the old character out.
/// - An **enter** [AnimationController] that spring-drives the new character in.
/// - A **width** [AnimationController] that transitions the slot's layout width.
/// - A **color** [AnimationController] that fades the chromatic tint to the
///   resting text color after landing.
class RollingChar extends StatefulWidget {
  /// Creates an animated character cell.
  const RollingChar({
    super.key,
    required this.currentChar,
    required this.previousChar,
    required this.textStyle,
    required this.options,
    required this.charIndex,
    required this.totalChars,
    required this.charHeight,
    required this.animate,
    this.animationTrigger = 0,
    this.spacing = 0.0,
    this.isLast = false,
  });

  /// Horizontal spacing between character slots.
  final double spacing;

  /// Whether this is the last character in the text.
  final bool isLast;

  /// The character to display after the transition.
  final String currentChar;

  /// The character displayed before the transition.
  ///
  /// An empty string indicates this is a brand-new position, triggering an
  /// enter-only animation with no exit phase.
  final String previousChar;

  /// The [TextStyle] applied to both old and new characters.
  final TextStyle textStyle;

  /// Animation configuration inherited from [RollingText].
  final RollingTextOptions options;

  /// Zero-based position of this slot within the full text.
  final int charIndex;

  /// Total number of characters currently rendered by [RollingText].
  final int totalChars;

  /// Pre-measured line height for this text style (shared across all slots).
  final double charHeight;

  /// Whether to run the transition animation for this character.
  final bool animate;

  /// Numeric trigger to force re-animation of unchanged characters.
  final int animationTrigger;

  @override
  State<RollingChar> createState() => RollingCharState();
}

class RollingCharState extends State<RollingChar>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Controllers
  // ---------------------------------------------------------------------------

  /// Drives the exiting character from rest (0.0) to fully offscreen (1.0).
  late AnimationController _exitCtrl;

  /// Drives the entering character with a spring simulation.
  /// Unbounded to allow natural overshoot.
  late AnimationController _enterCtrl;

  /// Drives the width transition of the slot cell.
  late AnimationController _widthCtrl;

  /// Cached curve for width animation.
  late Animation<double> _widthCurve;

  /// Fades the chromatic tint from full (0.0) to zero (1.0) after landing.
  late AnimationController _colorCtrl;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// The character currently animating out. Empty string when idle.
  String _prevChar = '';

  /// Whether a transition animation is currently in progress.
  bool _isAnimating = false;

  /// Pixel width of the **target** (new) character.
  double _cellWidth = 0;

  /// Pixel width of the **exiting** (old) character.
  double _prevCellWidth = 0;

  /// Guard flag — prevents timer callbacks from firing after [dispose].
  bool _disposed = false;

  /// Active stagger timers. All cancelled on [dispose] and on interrupt.
  final List<Timer> _timers = [];

  /// Cached render-ready style ([TextStyle] with [height] forced to 1.0).
  /// Recomputed only when [widget.textStyle] changes, avoiding per-frame
  /// [copyWith] allocations during spring-driven animation rebuilds.
  late TextStyle _cachedRenderStyle;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _cachedRenderStyle = widget.textStyle.copyWith(height: 1.0);
    _cellWidth = _measureCharWidth(widget.currentChar, _cachedRenderStyle);
    _prevChar = widget.previousChar;

    _exitCtrl = AnimationController(
      vsync: this,
      duration: widget.options.duration,
    );

    _enterCtrl = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
      value: 0.0,
    );

    _widthCtrl = AnimationController(
      vsync: this,
      duration: widget.options.duration,
    );

    // Custom ease-out bezier for width transitions — fast start, gentle settle.
    _widthCurve = CurvedAnimation(
      parent: _widthCtrl,
      curve: const Cubic(0.2, 0.0, 0.0, 1.0),
    );

    _colorCtrl = AnimationController(
      vsync: this,
      duration: widget.options.colorFadeDuration,
      value: 1.0,
    );

    if (widget.animate && widget.previousChar.isEmpty) {
      _prevCellWidth = 0.0;
      _widthCtrl.value = 0.0;
      _enterCtrl.value = 1.0;
      if (widget.options.color != null) _colorCtrl.value = 0.0;
      _isAnimating = true;
      _scheduleAnimations();
    } else {
      _prevCellWidth = _cellWidth;
      _widthCtrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(RollingChar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-cache the render style if the text style changed.
    if (oldWidget.textStyle != widget.textStyle) {
      _cachedRenderStyle = widget.textStyle.copyWith(height: 1.0);
    }

    if (oldWidget.currentChar == widget.currentChar &&
        oldWidget.animationTrigger == widget.animationTrigger) {
      return;
    }

    _prevCellWidth = _cellWidth;
    _cellWidth = _measureCharWidth(widget.currentChar, _renderStyle);

    if (!widget.animate) {
      setState(() {
        _prevChar = '';
        _prevCellWidth = _cellWidth;
        _widthCtrl.value = 1.0;
        _isAnimating = false;
      });
      return;
    }

    _prevChar = oldWidget.currentChar;

    if (_isAnimating && !widget.options.interrupt) return;

    _interruptAndTrigger();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    _exitCtrl.dispose();
    _enterCtrl.dispose();
    _widthCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  TextStyle get _renderStyle => _cachedRenderStyle;

  /// Computes a deterministic pseudo-random wobble in [-1.0, 1.0] for the character
  /// based on its index and a numeric salt.
  double _wobble(int index, int salt) {
    final double x = (index + 1) * 12.9898 + salt * 78.233;
    final double sinVal = math.sin(x) * 43758.5453;
    return (sinVal - sinVal.floor()) * 2.0 - 1.0;
  }

  // ---------------------------------------------------------------------------
  // Timer management
  // ---------------------------------------------------------------------------

  void _cancelTimers() {
    for (final Timer t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _addTimer(Duration delay, VoidCallback callback) {
    _timers.add(
      Timer(delay, () {
        if (!_disposed && mounted) callback();
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Animation sequencing
  // ---------------------------------------------------------------------------

  void _interruptAndTrigger() {
    _cancelTimers();
    _exitCtrl
      ..stop()
      ..value = 0.0;
    _enterCtrl.stop();
    _widthCtrl.stop();
    _colorCtrl.stop();

    _enterCtrl.value = 1.0;
    _widthCtrl.value = 0.0;
    if (widget.options.color != null) _colorCtrl.value = 0.0;

    setState(() => _isAnimating = true);

    _scheduleAnimations();
  }

  void _scheduleAnimations() {
    final double wobbleSpeed = _wobble(widget.charIndex, 1);
    final double wobbleStagger = _wobble(widget.charIndex, 2);

    final bool isTail = widget.currentChar.isEmpty;
    final bool isLead = _prevChar.isEmpty;

    final double durationMs = widget.options.duration.inMilliseconds.toDouble();
    final double d =
        (durationMs *
                (isTail ? 0.75 : 1.0) *
                (1.0 + widget.options.bounce * 0.45 * wobbleSpeed))
            .roundToDouble();

    final double staggerMs = widget.options.stagger.inMilliseconds.toDouble();
    final double staggerIndex = widget.charIndex.toDouble();
    final double base =
        (staggerIndex *
                staggerMs *
                (1.0 + widget.options.bounce * 0.25 * wobbleStagger))
            .roundToDouble();

    // Stagger slide-out of existing char
    if (_prevChar.isNotEmpty) {
      _addTimer(Duration(milliseconds: base.toInt()), () {
        _exitCtrl.duration = Duration(milliseconds: d.toInt());
        _exitCtrl.forward(from: 0.0);
      });
    }

    // Stagger slide-in of entering char
    final double enterDelay =
        base + widget.options.exitOffset.inMilliseconds.toDouble();
    _addTimer(Duration(milliseconds: enterDelay.toInt()), _runEnterSpring);

    // Calculate layout width transition delay & duration
    final bool widthChanges = (_cellWidth - _prevCellWidth).abs() > 0.5;
    if (widthChanges) {
      double wDelay = base;
      double wDur = d;

      if (isTail) {
        wDelay = base + (d * 0.55).roundToDouble();
        wDur = math.max(140.0, d * 0.6);
      } else if (isLead) {
        wDur = math.max(140.0, d * 0.45);
      }

      _addTimer(Duration(milliseconds: wDelay.toInt()), () {
        _widthCtrl.duration = Duration(milliseconds: wDur.toInt());
        _widthCtrl.forward(from: 0.0);
      });
    } else {
      _widthCtrl.value = 1.0;
    }
  }

  void _runEnterSpring() {
    final double wobbleSpeed = _wobble(widget.charIndex, 1);
    final double stiffnessVariance = widget.options.bounce * wobbleSpeed * 40.0;

    final SpringDescription spring = SpringDescription(
      mass: widget.options.springMass,
      stiffness: widget.options.springStiffness + stiffnessVariance,
      damping: widget.options.springDamping,
    );

    final SpringSimulation simulation = SpringSimulation(
      spring,
      _enterCtrl.value,
      0.0,
      0.0,
    );

    _enterCtrl.animateWith(simulation).then((_) {
      if (_disposed || !mounted) return;

      setState(() {
        _isAnimating = false;
        _prevChar = '';
        _prevCellWidth = _cellWidth;
        _widthCtrl.value = 1.0;
      });

      if (widget.options.color != null) {
        _colorCtrl.forward(from: 0.0);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Character widget helpers
  // ---------------------------------------------------------------------------

  List<Widget> _buildCharWidgets({
    required TextStyle style,
    required double exitY,
    required double enterY,
    required Color renderColor,
  }) {
    return [
      if (_isAnimating && _prevChar.isNotEmpty)
        Transform.translate(
          offset: Offset(0, exitY),
          child: Opacity(
            opacity: (1.0 - _exitCtrl.value * _exitCtrl.value).clamp(0.0, 1.0),
            child: OverflowBox(
              alignment: Alignment.center,
              minWidth: _prevCellWidth,
              maxWidth: _prevCellWidth,
              minHeight: widget.charHeight,
              maxHeight: widget.charHeight,
              child: Text(
                _glyph(_prevChar),
                style: style,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      if (widget.currentChar.isNotEmpty)
        Transform.translate(
          offset: Offset(0, _isAnimating ? enterY : 0.0),
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: _cellWidth,
            maxWidth: _cellWidth,
            minHeight: widget.charHeight,
            maxHeight: widget.charHeight,
            child: Text(
              _glyph(widget.currentChar),
              style: style.copyWith(color: renderColor),
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = _renderStyle;
    final double dirSign = widget.options.direction == RollingDirection.down
        ? 1.0
        : -1.0;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _exitCtrl,
        _enterCtrl,
        _colorCtrl,
        _widthCtrl,
      ]),
      builder: (BuildContext context, Widget? _) {
        final double targetSpacing = widget.isLast ? 0.0 : widget.spacing;
        final double currentSpacing = targetSpacing * _widthCurve.value;
        final double currentWidth =
            _prevCellWidth +
            (_cellWidth - _prevCellWidth) * _widthCurve.value +
            currentSpacing;
        final double exitY = _exitCtrl.value * widget.charHeight * dirSign;
        final double enterY = _enterCtrl.value * (-widget.charHeight * dirSign);

        final Color Function(int, int)? restingFn = widget.options.restingColor;
        final Color atRest = restingFn != null
            ? restingFn(widget.charIndex, widget.totalChars)
            : style.color ?? Colors.black;

        Color renderColor;
        final Color Function(int, int)? colorFn = widget.options.color;
        if (colorFn != null) {
          final Color tint = colorFn(widget.charIndex, widget.totalChars);
          renderColor = Color.lerp(
            tint,
            atRest,
            _colorCtrl.value.clamp(0.0, 1.0),
          )!;
        } else {
          renderColor = atRest;
        }

        return SizedBox(
          width: currentWidth,
          height: widget.charHeight,
          child: Padding(
            padding: EdgeInsets.only(right: currentSpacing),
            child: widget.options.fadeEdges > 0.0
                ? ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (Rect rect) {
                      final double f = widget.options.fadeEdges;
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: const [
                          Colors.transparent,
                          Colors.black,
                          Colors.black,
                          Colors.transparent,
                        ],
                        stops: [0.0, f, 1.0 - f, 1.0],
                      ).createShader(rect);
                    },
                    child: ClipPath(
                      clipper: _YOnlyClipper(height: widget.charHeight),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: _buildCharWidgets(
                          style: style,
                          exitY: exitY,
                          enterY: enterY,
                          renderColor: renderColor,
                        ),
                      ),
                    ),
                  )
                : ClipPath(
                    clipper: _YOnlyClipper(height: widget.charHeight),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: _buildCharWidgets(
                        style: style,
                        exitY: exitY,
                        enterY: enterY,
                        renderColor: renderColor,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
