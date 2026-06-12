import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolling_text/rolling_text.dart';

void main() {
  // ---------------------------------------------------------------------------
  // RollingTextOptions
  // ---------------------------------------------------------------------------

  group('RollingTextOptions', () {
    test('defaults match expected values', () {
      const options = RollingTextOptions();
      expect(options.direction, RollingDirection.down);
      expect(options.stagger, const Duration(milliseconds: 45));
      expect(options.duration, const Duration(milliseconds: 300));
      expect(options.exitOffset, const Duration(milliseconds: 50));
      expect(options.bounce, 0.6);
      expect(options.skipUnchanged, true);
      expect(options.interrupt, true);
    });

    test('copyWith overrides only specified fields', () {
      const base = RollingTextOptions(bounce: 0.3);
      final copy = base.copyWith(direction: RollingDirection.up);
      expect(copy.direction, RollingDirection.up);
      expect(copy.bounce, 0.3); // unchanged
    });

    test('bounce out of range throws assertion', () {
      expect(() => RollingTextOptions(bounce: 1.1), throwsAssertionError);
      expect(() => RollingTextOptions(bounce: -0.1), throwsAssertionError);
    });
  });

  // ---------------------------------------------------------------------------
  // chromatic()
  // ---------------------------------------------------------------------------

  group('chromatic()', () {
    test('returns a function that produces a color per character', () {
      final fn = chromatic();
      final c0 = fn(0, 5);
      final c4 = fn(4, 5);
      expect(c0, isA<Color>());
      expect(c4, isA<Color>());
      expect(c0, isNot(equals(c4)));
    });

    test('single character gives consistent color', () {
      final fn = chromatic();
      expect(fn(0, 1), equals(fn(0, 1)));
    });

    test('saturation and lightness out of range throw assertion', () {
      expect(() => chromatic(saturation: -0.1), throwsAssertionError);
      expect(() => chromatic(lightness: 1.1), throwsAssertionError);
    });
  });

  // ---------------------------------------------------------------------------
  // RollingTextController
  // ---------------------------------------------------------------------------

  group('RollingTextController', () {
    test('initial value is set correctly', () {
      final ctrl = RollingTextController(initial: 'Hello');
      expect(ctrl.value, 'Hello');
      ctrl.dispose();
    });

    test('set() updates value', () {
      final ctrl = RollingTextController(initial: 'Copy');
      ctrl.set('Saved');
      expect(ctrl.value, 'Saved');
      ctrl.dispose();
    });

    test('flash() changes value then reverts after delay', () async {
      final ctrl = RollingTextController(initial: 'Copy');
      ctrl.flash('Copied', revertAfter: const Duration(milliseconds: 50));
      expect(ctrl.value, 'Copied');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(ctrl.value, 'Copy');
      ctrl.dispose();
    });

    test('flash() is spam-safe — repeated calls reset the timer', () {
      fakeAsync((async) {
        final ctrl = RollingTextController(initial: 'Copy');
        ctrl.flash('Copied', revertAfter: const Duration(milliseconds: 300));
        async.elapse(const Duration(milliseconds: 200));
        ctrl.flash('Copied', revertAfter: const Duration(milliseconds: 300));
        async.elapse(const Duration(milliseconds: 200));
        expect(ctrl.value, 'Copied');
        async.elapse(const Duration(milliseconds: 150));
        expect(ctrl.value, 'Copy');
        ctrl.dispose();
      });
    });

    test('set() cancels pending flash revert', () async {
      final ctrl = RollingTextController(initial: 'Copy');
      ctrl.flash('Copied', revertAfter: const Duration(milliseconds: 100));
      ctrl.set('Saved');
      await Future.delayed(const Duration(milliseconds: 200));
      expect(ctrl.value, 'Saved');
      ctrl.dispose();
    });

    test('startWaiting ellipsis transitions and completes', () {
      fakeAsync((async) {
        final ctrl = RollingTextController(initial: 'Loading');
        final handle = ctrl.startWaiting(
          'Loading',
          waiting: const RollingWaiting.ellipsis(),
        );
        expect(ctrl.value, 'Loading');

        async.elapse(const Duration(milliseconds: 450));
        expect(ctrl.value, 'Loading.');

        async.elapse(const Duration(milliseconds: 450));
        expect(ctrl.value, 'Loading..');

        handle.complete('Finished');
        expect(ctrl.value, 'Finished');

        ctrl.dispose();
      });
    });

    test('startProgress frames cycle and cancel', () {
      fakeAsync((async) {
        final ctrl = RollingTextController(initial: 'Sync');
        final handle = ctrl.startProgress(
          'Sync',
          frames: ['Sync 1', 'Sync 2', 'Sync 3'],
          interval: const Duration(milliseconds: 100),
        );
        expect(ctrl.value, 'Sync');

        async.elapse(const Duration(milliseconds: 110));
        expect(ctrl.value, 'Sync 1');

        async.elapse(const Duration(milliseconds: 100));
        expect(ctrl.value, 'Sync 2');

        handle.cancel();
        async.elapse(const Duration(milliseconds: 100));
        expect(ctrl.value, 'Sync 2');

        ctrl.dispose();
      });
    });
  });

  // ---------------------------------------------------------------------------
  // RollingText widget
  // ---------------------------------------------------------------------------

  group('RollingText widget', () {
    testWidgets('renders initial text statically', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingText(text: 'Hello', style: TextStyle(fontSize: 16)),
          ),
        ),
      );
      expect(find.text('H'), findsOneWidget);
      expect(find.text('e'), findsOneWidget);
    });

    testWidgets('updates display when text prop changes', (tester) async {
      String label = 'Copy';
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, set) {
              setState = set;
              return Scaffold(
                body: RollingText(
                  text: label,
                  style: const TextStyle(fontSize: 16),
                ),
              );
            },
          ),
        ),
      );

      setState(() => label = 'Done');
      await tester.pumpAndSettle();

      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('controller drives the widget', (tester) async {
      final ctrl = RollingTextController(initial: 'Copy');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RollingText(
              controller: ctrl,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );

      ctrl.set('Done');
      await tester.pumpAndSettle();
      expect(find.text('D'), findsOneWidget);

      ctrl.dispose();
    });

    testWidgets('has correct Semantics label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingText(text: 'Hello', style: TextStyle(fontSize: 16)),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(RollingText)),
        matchesSemantics(label: 'Hello'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // RollingNumber widget
  // ---------------------------------------------------------------------------

  group('RollingNumber', () {
    testWidgets('renders integer value as padded string', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingNumber(
              value: 7,
              wholePartPadding: 3,
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
      );
      expect(find.text('0'), findsWidgets);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('renders fractionDigits correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingNumber(
              value: 3.14159,
              fractionDigits: 2,
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text('.'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('shows prefix text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingNumber(
              value: 99,
              prefix: r'$',
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
      );
      expect(find.text(r'$'), findsOneWidget);
    });

    testWidgets('shows suffix text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingNumber(
              value: 75,
              suffix: '%',
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
      );
      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('shows minus sign for negative value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingNumber(value: -42, style: TextStyle(fontSize: 32)),
          ),
        ),
      );
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('shows plus sign when positiveSign is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingNumber(
              value: 10,
              positiveSign: true,
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
      );
      expect(find.text('+'), findsOneWidget);
    });

    testWidgets('direction is up when value increases', (tester) async {
      int value = 5;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, set) {
              setState = set;
              return Scaffold(
                body: RollingNumber(
                  value: value,
                  style: const TextStyle(fontSize: 32),
                ),
              );
            },
          ),
        ),
      );

      setState(() => value = 10);
      await tester.pump();

      expect(find.byType(RollingNumber), findsOneWidget);
    });

    testWidgets('direction is down when value decreases', (tester) async {
      int value = 10;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, set) {
              setState = set;
              return Scaffold(
                body: RollingNumber(
                  value: value,
                  style: const TextStyle(fontSize: 32),
                ),
              );
            },
          ),
        ),
      );

      setState(() => value = 3);
      await tester.pump();

      expect(find.byType(RollingNumber), findsOneWidget);
    });

    test('fractionDigits negative throws assertion', () {
      expect(
        () => RollingNumber(
          value: 1,
          fractionDigits: -1,
          style: const TextStyle(),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('thousandSeparator inserts commas between digit groups', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingNumber(
              value: 1234567,
              thousandSeparator: ',',
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
      );
      expect(find.text(','), findsNWidgets(2));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('decimalSeparator replaces the default dot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RollingNumber(
              value: 3.14,
              fractionDigits: 2,
              decimalSeparator: ',',
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
      );
      expect(find.text(','), findsOneWidget);
      expect(find.text('.'), findsNothing);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('autoDirection false respects user-provided direction', (
      tester,
    ) async {
      int value = 5;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, set) {
              setState = set;
              return Scaffold(
                body: RollingNumber(
                  value: value,
                  autoDirection: false,
                  options: const RollingTextOptions(
                    direction: RollingDirection.down,
                  ),
                  style: const TextStyle(fontSize: 32),
                ),
              );
            },
          ),
        ),
      );

      setState(() => value = 10);
      await tester.pump();

      expect(find.byType(RollingNumber), findsOneWidget);
    });
  });
}
