import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rolling_text/rolling_text.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

const String _version = '0.1.0';

const Color _bg           = Color(0xFF080C10);
const Color _surface      = Color(0xFF0E1318);
const Color _surfaceCode  = Color(0xFF070B0F); // darker well for code blocks
const Color _border       = Color(0xFF1C2128);
const Color _borderCode   = Color(0xFF151C24);
const Color _textPrimary  = Color(0xFFE6EDF3);
const Color _textSecondary = Color(0xFF7D8590);
const Color _textCode     = Color(0xFFA5D6FF); // light blue tint for code
const Color _accent       = Color(0xFF38BDF8);
const Color _green        = Color(0xFF3FB950);
const Color _red          = Color(0xFFF85149);

// ---------------------------------------------------------------------------
// Typography helpers
// ---------------------------------------------------------------------------

TextStyle _inter({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w400,
  Color color = _textPrimary,
  double? letterSpacing,
  double? height,
}) => GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

TextStyle _mono({
  double fontSize = 12,
  Color color = _textCode,
  FontWeight fontWeight = FontWeight.w400,
}) => GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );

// ---------------------------------------------------------------------------
// Shape helpers
// ---------------------------------------------------------------------------

BoxDecoration _cardDecor() => BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    );

BoxDecoration _codeBlockDecor() => BoxDecoration(
      color: _surfaceCode,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _borderCode),
    );

// ---------------------------------------------------------------------------
// App shell
// ---------------------------------------------------------------------------

void main() {
  runApp(const RollingTextShowcaseApp());
}

class RollingTextShowcaseApp extends StatelessWidget {
  const RollingTextShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rolling_text',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          surface: _surface,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const ShowcasePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ShowcasePage extends StatelessWidget {
  const ShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          children: [
            const _PageHeader(),
            const SizedBox(height: 36),

            // 1 — flash / controller
            _DemoCard(
              title: 'flash() — spam-safe revert',
              description:
                  'Rolls to a new string and auto-reverts after a delay. '
                  'Repeated taps reset the timer — no duplicate animations.',
              preview: const _CopyDemo(),
              snippet: '''
final ctrl = RollingTextController(initial: 'Copy');

ctrl.flash(
  'Copied ✓',
  revertAfter: Duration(milliseconds: 1600),
);

RollingText(
  controller: ctrl,
  style: TextStyle(fontSize: 15),
  options: RollingTextOptions(direction: RollingDirection.up),
)''',
            ),
            const SizedBox(height: 14),

            // 2 — RollingNumber integer
            _DemoCard(
              title: 'Direction-aware number roller',
              description:
                  'RollingNumber rolls up when the value increases and down when '
                  'it decreases. Direction is automatic — no setState needed.',
              preview: const _NumberDemo(),
              snippet: '''
RollingNumber(
  value: _count,        // int or double
  wholePartPadding: 3,  // 7 → "007"
  style: TextStyle(fontSize: 56, fontWeight: FontWeight.w700),
  options: RollingTextOptions(
    springStiffness: 250,
    springDamping: 19,
    bounce: 0.65,
  ),
)''',
            ),
            const SizedBox(height: 14),

            // 3 — RollingNumber currency
            _DemoCard(
              title: 'prefix · suffix · fractionDigits',
              description:
                  'Currency, percentages and negative values out of the box. '
                  'The sign character animates as its own slot.',
              preview: const _CurrencyDemo(),
              snippet: '''
// Currency
RollingNumber(
  value: _balance,
  fractionDigits: 2,
  prefix: '\$',
  style: TextStyle(color: _balance >= 0 ? Colors.green : Colors.red),
)

// Percentage with explicit + sign
RollingNumber(
  value: _percent,
  fractionDigits: 1,
  suffix: '%',
  positiveSign: true,
  style: TextStyle(fontSize: 26),
)''',
            ),
            const SizedBox(height: 14),

            // 4 — chromatic
            _DemoCard(
              title: 'chromatic() — per-character hue tint',
              description:
                  'Each character lands with its own color from a hue sweep, '
                  'then fades back to the resting style color.',
              preview: const _ChromaticDemo(),
              snippet: '''
RollingText(
  text: currentLabel,
  style: TextStyle(fontSize: 34, color: Colors.white),
  options: RollingTextOptions(
    direction: RollingDirection.down,
    color: chromatic(from: 190, spread: 260),
    colorFadeDuration: Duration(milliseconds: 420),
    stagger: Duration(milliseconds: 38),
    skipUnchanged: false,
  ),
)''',
            ),
            const SizedBox(height: 14),

            // 5 — stagger
            _DemoCard(
              title: 'Stagger & direction',
              description:
                  'Each character starts its animation offset by stagger × index. '
                  'Combine with bounce for a ripple-spring effect.',
              preview: const _StaggerDemo(),
              snippet: '''
RollingText(
  text: _label,
  style: TextStyle(fontSize: 30),
  options: RollingTextOptions(
    direction: RollingDirection.up, // or .down
    stagger: Duration(milliseconds: 50),
    bounce: 0.8,
    skipUnchanged: false,
  ),
)''',
            ),
            const SizedBox(height: 14),

            // 6 — waiting & progress
            _DemoCard(
              title: 'startWaiting() & startProgress() — async loops',
              description:
                  'Tactile loading states and progress cycles. Wave uses spring physics; '
                  'Shimmer is a traveling restingColor spotlight.',
              preview: const _WaitingDemo(),
              snippet: '''
final ctrl = RollingTextController(initial: 'Idle');

// Ellipsis loop
ctrl.startWaiting('Loading', waiting: RollingWaiting.ellipsis());

// Wave loop (spring-driven roll-to-self)
ctrl.startWaiting('Processing', waiting: RollingWaiting.wave());

// Shimmer (color spotlight tint)
ctrl.startWaiting('Saving data', waiting: RollingWaiting.shimmer(color: Colors.amber));

// Complete the active animation loop
handle.complete('Success ✓');
''',
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page header
// ---------------------------------------------------------------------------

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Package name + version on same baseline
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'rolling_text',
              style: _mono(fontSize: 12, color: _accent, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              'v$_version',
              style: _mono(fontSize: 11, color: _textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Per-character\nslot animation',
          style: _inter(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Spring physics · Any string · Zero dependencies',
          style: _inter(
            fontSize: 14,
            color: _textSecondary,
            height: 1.6,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Demo card — preview on top, copyable code block below
// ---------------------------------------------------------------------------

class _DemoCard extends StatefulWidget {
  const _DemoCard({
    required this.title,
    required this.description,
    required this.preview,
    required this.snippet,
  });

  final String title;
  final String description;
  final Widget preview;
  final String snippet;

  @override
  State<_DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<_DemoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecor(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — Metadata + preview —
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: _inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  style: _inter(
                    fontSize: 12,
                    color: _textSecondary,
                    height: 1.6,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 28),
                Center(child: widget.preview),
                const SizedBox(height: 28),
              ],
            ),
          ),

          // Divider before toggle button
          Container(
            height: 1,
            color: _border,
          ),

          // Toggle button row
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.code_rounded,
                      size: 16,
                      color: _expanded ? _accent : _textSecondary,
                    ),
                    const SizedBox(width: 8),
                    RollingText(
                      text: _expanded ? 'Hide code' : 'Show code',
                      style: _inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _expanded ? _textPrimary : _textSecondary,
                      ),
                      options: RollingTextOptions(
                        direction: _expanded ? RollingDirection.up : RollingDirection.down,
                        stagger: const Duration(milliseconds: 20),
                        bounce: 0.3,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // — Animated Code block —
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity, height: 0)
                : Container(
                    width: double.infinity,
                    decoration: _codeBlockDecor().copyWith(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border(
                        top: BorderSide(color: _borderCode),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toolbar row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Row(
                            children: [
                              Text(
                                'dart',
                                style: _mono(
                                  fontSize: 10,
                                  color: _textSecondary,
                                ),
                              ),
                              const Spacer(),
                              _CopySnippetBtn(code: widget.snippet),
                            ],
                          ),
                        ),
                        // Code text
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Text(
                            widget.snippet.trim(),
                            style: _mono(fontSize: 12, color: _textCode),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Copy snippet button
// ---------------------------------------------------------------------------

class _CopySnippetBtn extends StatefulWidget {
  const _CopySnippetBtn({required this.code});
  final String code;

  @override
  State<_CopySnippetBtn> createState() => _CopySnippetBtnState();
}

class _CopySnippetBtnState extends State<_CopySnippetBtn> {
  final RollingTextController _ctrl = RollingTextController(initial: 'Copy');
  RollingDirection _direction = RollingDirection.up;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChange);
  }

  void _onTextChange() {
    if (mounted) {
      setState(() {
        _direction = _ctrl.value == 'Copy'
            ? RollingDirection.down
            : RollingDirection.up;
      });
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code.trim()));
    _ctrl.flash('Copied ✓', revertAfter: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChange);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCopy = _ctrl.value == 'Copy';
    return GestureDetector(
      onTap: _copy,
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        tween: Tween<double>(begin: 0.0, end: isCopy ? 0.0 : 1.0),
        builder: (context, value, child) {
          final bgColor = Color.lerp(Colors.transparent, _accent.withOpacity(0.1), value);
          final borderColor = Color.lerp(_border, _accent.withOpacity(0.3), value);
          final textColor = Color.lerp(_textSecondary, _accent, value);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: borderColor ?? _border,
                width: 1,
              ),
            ),
            child: RollingText(
              controller: _ctrl,
              style: _mono(
                fontSize: 10,
                color: textColor!,
                fontWeight: FontWeight.w500,
              ),
              options: RollingTextOptions(
                direction: _direction,
                stagger: const Duration(milliseconds: 30),
                bounce: 0.4,
                skipUnchanged: false,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 1 — Copy / Copied
// ---------------------------------------------------------------------------

class _CopyDemo extends StatefulWidget {
  const _CopyDemo();

  @override
  State<_CopyDemo> createState() => _CopyDemoState();
}

class _CopyDemoState extends State<_CopyDemo> {
  final RollingTextController _ctrl = RollingTextController(initial: 'Copy');
  RollingDirection _direction = RollingDirection.up;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    if (mounted) {
      setState(() {
        // Roll UP when showing "Copied ✓" and roll DOWN when reverting back to "Copy"
        _direction = _ctrl.value == 'Copy' ? RollingDirection.down : RollingDirection.up;
      });
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_handleTextChange);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCopied = _ctrl.value != 'Copy';
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _ctrl.flash('Copied ✓', revertAfter: const Duration(milliseconds: 1600));
      },
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        tween: Tween<double>(begin: 0.0, end: isCopied ? 1.0 : 0.0),
        builder: (context, value, child) {
          final bgColor = Color.lerp(_accent, _green, value);
          final textColor = Color.lerp(_bg, Colors.white, value);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: RollingText(
              controller: _ctrl,
              style: _inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor!,
                letterSpacing: -0.3,
              ),
              options: RollingTextOptions(
                direction: _direction,
                stagger: const Duration(milliseconds: 35),
                bounce: 0.5,
                skipUnchanged: false,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 2 — Number roller
// ---------------------------------------------------------------------------

class _NumberDemo extends StatefulWidget {
  const _NumberDemo();

  @override
  State<_NumberDemo> createState() => _NumberDemoState();
}

class _NumberDemoState extends State<_NumberDemo> {
  int _value = 42;
  bool _fadeEdges = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _StepBtn(
              icon: Icons.remove_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _value = (_value - 1).clamp(0, 999));
              },
            ),
            Expanded(
              child: Center(
                child: RollingNumber(
                  value: _value,
                  wholePartPadding: 3,
                  style: _inter(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                  options: RollingTextOptions(
                    stagger: const Duration(milliseconds: 28),
                    duration: const Duration(milliseconds: 260),
                    springStiffness: 250,
                    springDamping: 19,
                    bounce: 0.65,
                    fadeEdges: _fadeEdges ? 0.22 : 0.0,
                  ),
                ),
              ),
            ),
            _StepBtn(
              icon: Icons.add_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _value = (_value + 1).clamp(0, 999));
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Fade-edges toggle
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _fadeEdges = !_fadeEdges);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _fadeEdges
                  ? _accent.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _fadeEdges
                    ? _accent.withValues(alpha: 0.55)
                    : _border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    _fadeEdges
                        ? Icons.blur_on_rounded
                        : Icons.blur_off_rounded,
                    key: ValueKey(_fadeEdges),
                    size: 14,
                    color: _fadeEdges ? _accent : _textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'fade edges',
                  style: _inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _fadeEdges ? _accent : _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 3 — Currency + percent
// ---------------------------------------------------------------------------

class _CurrencyDemo extends StatefulWidget {
  const _CurrencyDemo();

  @override
  State<_CurrencyDemo> createState() => _CurrencyDemoState();
}

class _CurrencyDemoState extends State<_CurrencyDemo> {
  double _balance = 1234.56;
  double _percent = 4.2;

  static const _opts = RollingTextOptions(
    stagger: Duration(milliseconds: 22),
    duration: Duration(milliseconds: 240),
    springStiffness: 260,
    springDamping: 20,
    bounce: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _StepBtn(
              icon: Icons.remove_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _balance = (_balance - 100).clamp(-9999.99, 9999.99));
              },
            ),
            Expanded(
              child: Center(
                child: RollingNumber(
                  value: _balance,
                  fractionDigits: 2,
                  prefix: '\$',
                  style: _inter(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: _balance >= 0 ? _green : _red,
                    letterSpacing: -1.5,
                    height: 1,
                  ),
                  options: _opts,
                ),
              ),
            ),
            _StepBtn(
              icon: Icons.add_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _balance = (_balance + 100).clamp(-9999.99, 9999.99));
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _StepBtn(
              icon: Icons.remove_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _percent = (_percent - 0.5).clamp(-99.9, 99.9));
              },
            ),
            Expanded(
              child: Center(
                child: RollingNumber(
                  value: _percent,
                  fractionDigits: 1,
                  suffix: '%',
                  positiveSign: true,
                  style: _inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: _percent >= 0 ? _green : _red,
                    letterSpacing: -0.8,
                    height: 1,
                  ),
                  options: _opts,
                ),
              ),
            ),
            _StepBtn(
              icon: Icons.add_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _percent = (_percent + 0.5).clamp(-99.9, 99.9));
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 4 — Chromatic
// ---------------------------------------------------------------------------

class _ChromaticDemo extends StatefulWidget {
  const _ChromaticDemo();

  @override
  State<_ChromaticDemo> createState() => _ChromaticDemoState();
}

class _ChromaticDemoState extends State<_ChromaticDemo> {
  static const List<String> _words = [
    'Beautiful',
    'Chromatic',
    'Iridescent',
    'Prismatic',
    'Luminous',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => setState(() => _index = (_index + 1) % _words.length),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RollingText(
      text: _words[_index],
      style: _inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1,
      ),
      options: RollingTextOptions(
        direction: RollingDirection.down,
        stagger: const Duration(milliseconds: 38),
        duration: const Duration(milliseconds: 300),
        color: chromatic(from: 190, spread: 260),
        colorFadeDuration: const Duration(milliseconds: 420),
        bounce: 0.55,
        skipUnchanged: false,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 5 — Stagger playground
// ---------------------------------------------------------------------------

class _StaggerDemo extends StatefulWidget {
  const _StaggerDemo();

  @override
  State<_StaggerDemo> createState() => _StaggerDemoState();
}

class _StaggerDemoState extends State<_StaggerDemo> {
  static const List<String> _labels = [
    'Slot Text',
    'Flutter',
    'Animation',
    'Physics',
  ];

  int _idx = 0;
  RollingDirection _dir = RollingDirection.down;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RollingText(
          text: _labels[_idx],
          style: _inter(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            height: 1,
          ),
          options: RollingTextOptions(
            direction: _dir,
            stagger: const Duration(milliseconds: 50),
            bounce: 0.8,
            skipUnchanged: false,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _dir = _idx % 2 == 0 ? RollingDirection.up : RollingDirection.down;
              _idx = (_idx + 1) % _labels.length;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _border),
            ),
            child: Text(
              'Next word',
              style: _inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared — step button (+/−)
// ---------------------------------------------------------------------------

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _surface,
          border: Border.all(color: _border),
        ),
        child: Icon(icon, size: 17, color: _textSecondary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 6 — Waiting & Progress Loops
// ---------------------------------------------------------------------------

class _WaitingDemo extends StatefulWidget {
  const _WaitingDemo();

  @override
  State<_WaitingDemo> createState() => _WaitingDemoState();
}

class _WaitingDemoState extends State<_WaitingDemo> {
  final RollingTextController _ctrl = RollingTextController(initial: 'Idle');
  RollingWaitingHandle? _handle;
  String _mode = 'idle';

  void _stop() {
    _handle?.cancel();
    _handle = null;
    _ctrl.set('Idle');
    setState(() => _mode = 'idle');
  }

  void _startEllipsis() {
    _handle?.cancel();
    setState(() => _mode = 'ellipsis');
    _handle = _ctrl.startWaiting(
      'Loading',
      waiting: const RollingWaiting.ellipsis(
        interval: Duration(milliseconds: 400),
      ),
    );
  }

  void _startWave() {
    _handle?.cancel();
    setState(() => _mode = 'wave');
    _handle = _ctrl.startWaiting(
      'Processing',
      waiting: const RollingWaiting.wave(
        interval: Duration(milliseconds: 120),
        rest: Duration(milliseconds: 1000),
      ),
      options: const RollingTextOptions(
        stagger: Duration(milliseconds: 25),
        bounce: 0.6,
      ),
    );
  }

  void _startShimmer() {
    _handle?.cancel();
    setState(() => _mode = 'shimmer');
    _handle = _ctrl.startWaiting(
      'Saving data',
      waiting: const RollingWaiting.shimmer(
        interval: Duration(milliseconds: 150),
        color: _accent,
      ),
    );
  }

  void _startProgress() {
    _handle?.cancel();
    setState(() => _mode = 'progress');
    _handle = _ctrl.startProgress(
      'Ready',
      frames: ['Working.', 'Working..', 'Working...'],
      interval: const Duration(milliseconds: 500),
    );
  }

  void _complete() {
    _handle?.complete('Success ✓', options: RollingTextOptions(
      color: chromatic(from: 100, spread: 80),
    ));
    _handle = null;
    setState(() => _mode = 'idle');
  }

  void _fail() {
    _handle?.fail('Failed ✗', options: RollingTextOptions(
      color: chromatic(from: 0, spread: 20),
    ));
    _handle = null;
    setState(() => _mode = 'idle');
  }

  @override
  void dispose() {
    _handle?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Widget _btn(String label, VoidCallback onTap, bool active) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _accent.withOpacity(0.15) : _surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? _accent : _border),
        ),
        child: Text(
          label,
          style: _inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? _accent : _textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: Center(
            child: RollingText(
              controller: _ctrl,
              style: _inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _btn('Ellipsis', _startEllipsis, _mode == 'ellipsis'),
            _btn('Wave', _startWave, _mode == 'wave'),
            _btn('Shimmer', _startShimmer, _mode == 'shimmer'),
            _btn('Progress', _startProgress, _mode == 'progress'),
            if (_mode != 'idle') ...[
              _btn('Complete', _complete, false),
              _btn('Fail', _fail, false),
              _btn('Stop', _stop, false),
            ],
          ],
        ),
      ],
    );
  }
}
