import 'package:flutter/material.dart';

import 'rolling_text_options.dart';
import 'rolling_text_widget.dart';

/// A numeric slot-animation widget that wraps [RollingText] with number-specific
/// conveniences.
class RollingNumber extends StatefulWidget {
  /// Creates a [RollingNumber] widget.
  const RollingNumber({
    super.key,
    required this.value,
    required this.style,
    this.fractionDigits = 0,
    this.prefix,
    this.suffix,
    this.options,
    this.wholePartPadding = 0,
    this.positiveSign = false,
    this.useTabularFigures = true,
    this.thousandSeparator,
    this.decimalSeparator = '.',
    this.autoDirection = true,
    this.hideLeadingZeroes = false,
  }) : assert(fractionDigits >= 0, 'fractionDigits must be non-negative');

  /// The numeric value to display.
  final num value;

  /// The [TextStyle] applied to the entire number display.
  final TextStyle style;

  /// Number of digits to show after the decimal point.
  final int fractionDigits;

  /// Optional static string prepended to the number (e.g. `'\$'`, `'+'`).
  final String? prefix;

  /// Optional static string appended to the number (e.g. `'%'`, `'pts'`).
  final String? suffix;

  /// Animation options forwarded to [RollingText].
  final RollingTextOptions? options;

  /// Minimum number of digits in the whole-number part (zero-padded on left).
  final int wholePartPadding;

  /// Whether to show a `+` sign for positive values.
  final bool positiveSign;

  /// Whether to apply tabular (monospaced) digit widths.
  final bool useTabularFigures;

  /// Optional separator inserted between every 3 digits in the whole-number part.
  final String? thousandSeparator;

  /// The character used as the decimal point.
  final String decimalSeparator;

  /// Whether to automatically compute the roll direction from value changes.
  final bool autoDirection;

  /// Whether to hide leading zeroes added by [wholePartPadding].
  final bool hideLeadingZeroes;

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> {
  /// The previous value — used to determine roll direction.
  late num _previousValue;

  /// Current resolved direction.
  RollingDirection _direction = RollingDirection.up;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _direction = widget.value >= 0 ? RollingDirection.up : RollingDirection.down;
  }

  @override
  void didUpdateWidget(RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {
        _direction = widget.value >= _previousValue
            ? RollingDirection.up
            : RollingDirection.down;
        _previousValue = widget.value;
      });
    }
  }

  /// Returns only the **unsigned** number body, without any sign character.
  String _format() {
    final double absVal = widget.value.abs().toDouble();
    final String formatted = absVal.toStringAsFixed(widget.fractionDigits);

    final List<String> parts = formatted.split('.');
    String wholePart = parts[0];

    if (widget.wholePartPadding > 0) {
      wholePart = wholePart.padLeft(widget.wholePartPadding, '0');
    }

    if (widget.hideLeadingZeroes && widget.wholePartPadding > 0) {
      wholePart = wholePart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    }

    if (widget.thousandSeparator != null) {
      final StringBuffer buf = StringBuffer();
      for (int i = 0; i < wholePart.length; i++) {
        if (i > 0 && (wholePart.length - i) % 3 == 0) {
          buf.write(widget.thousandSeparator);
        }
        buf.write(wholePart[i]);
      }
      wholePart = buf.toString();
    }

    if (parts.length > 1) {
      return '$wholePart${widget.decimalSeparator}${parts[1]}';
    }
    return wholePart;
  }

  /// Returns the sign character to display: `'-'`, `'+'`, or `''`.
  String _sign() {
    if (widget.value < 0) return '-';
    if (widget.positiveSign && widget.value > 0) return '+';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final RollingTextOptions baseOptions = widget.options ??
        const RollingTextOptions(
          stagger: Duration(milliseconds: 30),
          duration: Duration(milliseconds: 280),
          springStiffness: 240,
          springDamping: 20,
          bounce: 0.7,
        );

    final RollingTextOptions resolved = widget.autoDirection
        ? baseOptions.copyWith(direction: _direction)
        : baseOptions;

    final TextStyle numberStyle = widget.useTabularFigures
        ? widget.style.copyWith(
            fontFeatures: [
              ...?widget.style.fontFeatures,
              const FontFeature.tabularFigures(),
            ],
          )
        : widget.style;

    final RollingTextOptions signOptions = resolved.copyWith(
      stagger: Duration.zero,
      skipUnchanged: false,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        RollingText(
          text: _sign(),
          style: numberStyle,
          options: signOptions,
        ),
        if (widget.prefix != null)
          Text(widget.prefix!, style: widget.style),
        RollingText(
          text: _format(),
          style: numberStyle,
          options: resolved,
        ),
        if (widget.suffix != null)
          Text(widget.suffix!, style: widget.style),
      ],
    );
  }
}
