import 'rolling_text_options.dart';

/// A handle to control or complete an active waiting or progress loop.
class RollingWaitingHandle {
  /// Creates a handle with the given callbacks.
  RollingWaitingHandle({
    required void Function(String text, {RollingTextOptions? options})
    onComplete,
    required void Function(String text, {RollingTextOptions? options}) onFail,
    required void Function() onCancel,
  }) : _onComplete = onComplete,
       _onFail = onFail,
       _onCancel = onCancel;

  final void Function(String text, {RollingTextOptions? options}) _onComplete;
  final void Function(String text, {RollingTextOptions? options}) _onFail;
  final void Function() _onCancel;

  /// Transition the widget to a final success text, canceling the loop.
  void complete(String text, {RollingTextOptions? options}) {
    _onComplete(text, options: options);
  }

  /// Transition the widget to a final failure text, canceling the loop.
  void fail(String text, {RollingTextOptions? options}) {
    _onFail(text, options: options);
  }

  /// Cancel the loop immediately without updating the text.
  void cancel() {
    _onCancel();
  }
}
