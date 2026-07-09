import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Grows the test viewport so long forms/scroll screens render fully
/// without needing scroll gestures — `scrollUntilVisible` is fragile
/// here (its `.single` check throws if the target briefly double-matches
/// mid-scroll). Call once per test, right after `pumpWidget`.
void useTallTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Bounded alternative to `tester.pumpAndSettle()`. pumpAndSettle's
/// default 10-minute timeout means any widget that never fully "settles"
/// hangs the test for the full 10 minutes AND leaves TestAsyncUtils'
/// guard in a bad state, cascading failures into every subsequent test
/// in the process. A 5s cap is generous for our short-lived (<=300ms)
/// animations and GoRouter's initial route resolution, while still
/// failing fast (not 10 minutes) if something genuinely never settles.
///
/// A tap that triggers a repository write (e.g. an upvote, a dismissal
/// toggle) fires a real async sqflite_common_ffi call that isn't tied to
/// any Timer/animation frame, so `pump()` alone can return before it
/// resolves. The `runAsync` flush lets that real I/O actually complete
/// before we pump again to reflect the resulting state.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}
