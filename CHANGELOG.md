## 0.1.3

* Shorten the pubspec description to meet the pub.dev 180 characters limit.

## 0.1.2

* Apply `dart format` to fix spacing and indentation issues and conform to pub.dev Dart file conventions.

## 0.1.1

* Fix pub.dev markdown image rendering by migrating relative `doc/` paths to absolute GitHub raw URLs.

## 0.1.0

- Initial release of `rolling_text`.
- **Core Animation Engine**: Per-character vertical rolling text animations utilizing real spring physics (`SpringSimulation`).
- **Programmatic Control**: `RollingTextController` supporting permanent `set()` changes and `flash()` temporary copy indicators (spam-safe auto-revert).
- **Asynchronous Loop Presets**:
  - `startWaiting()` supporting ellipsis loops, spring-physics wave ripple rolls, and resting color shimmer spotlights.
  - `startProgress()` to cycle through list-defined frames.
- **Accessibility**: Built-in support for OS-level reduced motion via `respectDisableAnimations` to snap values instantly.
- **RollingNumber wrapper**: Helper for direction-aware numeric rolls, prefix/suffix decoration, decimal precision, and formatting separators.
- **Style Sweeps**: Chromatic color sweeps during animation and static resting colors.
- **Depth Effects**: Top and bottom cell edge fading (`fadeEdges`) for an odometer appearance.
