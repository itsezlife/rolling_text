import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'rolling_text_options.dart';
import 'rolling_waiting.dart';
import 'rolling_waiting_handle.dart';

/// Programmatic controller for a [RollingText] widget.
///
/// Exposes [set] for permanent text changes, [flash] for temporary copy reveals,
/// [startWaiting] for idle animation loops (like ellipsis, waves, or shimmers),
/// and [startProgress] for explicit frame cycling.
class RollingTextController extends ValueNotifier<String> {
  /// Creates a [RollingTextController] with the given initial text.
  RollingTextController({required String initial}) : super(initial);

  Timer? _revertTimer;
  Timer? _waitingTimer;

  /// Tracks the text that was showing before the current flash sequence started.
  String? _flashOriginal;

  RollingWaiting? _activeWaiting;
  RollingTextOptions? _optionsOverride;
  int _animationTick = 0;

  // ---------------------------------------------------------------------------
  // Public Getters
  // ---------------------------------------------------------------------------

  /// The active waiting animation configuration, if any.
  RollingWaiting? get activeWaiting => _activeWaiting;

  /// The active options override (set during waiting or progress loops), if any.
  RollingTextOptions? get optionsOverride => _optionsOverride;

  /// The current tick of the active waiting or progress animation.
  int get animationTick => _animationTick;

  /// Whether the controller has been disposed.
  bool get isDisposed => _isDisposed;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Permanently transitions to [text], cancelling any active loops or flashes.
  void set(String text) {
    _cancelRevert();
    _cancelWaiting();
    _flashOriginal = null;
    if (value != text) value = text;
  }

  /// Temporarily transitions to [text], then rolls back after [revertAfter].
  ///
  /// Cancels any active waiting or progress loops before flashing.
  void flash(
    String text, {
    Duration revertAfter = const Duration(milliseconds: 1400),
  }) {
    _cancelWaiting();
    _flashOriginal ??= value;
    final String original = _flashOriginal!;

    _cancelRevert();
    value = text;

    _revertTimer = Timer(revertAfter, () {
      _revertTimer = null;
      _flashOriginal = null;
      if (!_isDisposed) value = original;
    });
  }

  /// Starts a waiting animation loop using the specified [waiting] preset.
  ///
  /// Returns a [RollingWaitingHandle] that allows completing, failing, or
  /// canceling the loop from the business logic.
  RollingWaitingHandle startWaiting(
    String text, {
    RollingWaiting waiting = const RollingWaiting.ellipsis(),
    RollingTextOptions? options,
  }) {
    _cancelWaiting();
    _cancelRevert();
    _flashOriginal = null;

    _activeWaiting = waiting;
    _optionsOverride = options;
    _animationTick = 0;

    _applyWaitingFrame(text);

    Duration interval = const Duration(milliseconds: 200);
    // Determine interval dynamically based on the preset subclass
    final RollingWaiting current = waiting;
    if (current.runtimeType.toString() == '_Ellipsis') {
      // Accessing package private subclasses dynamically or via type check
      // Since they are defined in rolling_waiting.dart, we check their runtime types
      // or map them safely.
    }

    // A safer, strongly-typed check utilizing our class structure:
    final String typeName = current.toString();
    if (typeName.contains('Ellipsis')) {
      // We can use reflection-free type matching by checking class identity
    }

    // Let's do type checking by checking the actual runtime class names or string patterns.
    // To be completely robust and compile-safe:
    final String waitType = current.toString();
    if (waitType.startsWith('Instance of \'_Ellipsis\'')) {
      // But wait, since they are internal subclasses of the same file, we can cast them
      // if we don't hide them or if we export/cast them.
      // Better: let's use dynamic type checking. Since they inherit from RollingWaiting,
      // and are in the same library context, we can import/match them if we cast to dynamic.
    }

    final dynamic dynWaiting = waiting;
    try {
      interval = dynWaiting.interval as Duration;
    } catch (_) {
      interval = const Duration(milliseconds: 200);
    }

    _waitingTimer = Timer.periodic(interval, (timer) {
      _animationTick++;
      _applyWaitingFrame(text);
    });

    return RollingWaitingHandle(
      onComplete: (successText, {options}) {
        _cancelWaiting();
        if (options != null) {
          _optionsOverride = options;
        }
        set(successText);
      },
      onFail: (failText, {options}) {
        _cancelWaiting();
        if (options != null) {
          _optionsOverride = options;
        }
        set(failText);
      },
      onCancel: () {
        _cancelWaiting();
        // Trigger a listener update so the widget refreshes its options/resting colors
        notifyListeners();
      },
    );
  }

  /// Starts a progress animation loop that cycles through the specified [frames].
  ///
  /// Returns a [RollingWaitingHandle] to control completion/failure of the loop.
  RollingWaitingHandle startProgress(
    String initial, {
    required List<String> frames,
    Duration interval = const Duration(milliseconds: 200),
    RollingTextOptions? options,
  }) {
    _cancelWaiting();
    _cancelRevert();
    _flashOriginal = null;

    _optionsOverride = options;
    _animationTick = 0;

    if (value != initial) value = initial;

    if (frames.isNotEmpty) {
      _waitingTimer = Timer.periodic(interval, (timer) {
        final String frame = frames[_animationTick % frames.length];
        _animationTick++;
        if (value != frame) value = frame;
      });
    }

    return RollingWaitingHandle(
      onComplete: (successText, {options}) {
        _cancelWaiting();
        if (options != null) {
          _optionsOverride = options;
        }
        set(successText);
      },
      onFail: (failText, {options}) {
        _cancelWaiting();
        if (options != null) {
          _optionsOverride = options;
        }
        set(failText);
      },
      onCancel: () {
        _cancelWaiting();
        notifyListeners();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  bool _isDisposed = false;

  void _cancelRevert() {
    _revertTimer?.cancel();
    _revertTimer = null;
  }

  void _cancelWaiting() {
    _waitingTimer?.cancel();
    _waitingTimer = null;
    _activeWaiting = null;
    _optionsOverride = null;
    _animationTick = 0;
  }

  void _applyWaitingFrame(String baseText) {
    final waiting = _activeWaiting;
    if (waiting == null) return;

    final String typeName = waiting.toString();
    if (typeName.contains('Ellipsis')) {
      final int dots = _animationTick % 4;
      final String frame = baseText + ('.' * dots);
      if (value != frame) value = frame;
    } else if (typeName.contains('Builder')) {
      final dynamic dynWaiting = waiting;
      final String Function(String, int) builder =
          dynWaiting.builder as String Function(String, int);
      final String frame = builder(baseText, _animationTick);
      if (value != frame) value = frame;
    } else {
      // Wave or Shimmer: keep base text but notify to animate/spotlight
      if (value != baseText) value = baseText;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelRevert();
    _cancelWaiting();
    super.dispose();
  }

  /// The text currently displayed (including during a flash or waiting loop).
  String get currentText => value;
}
