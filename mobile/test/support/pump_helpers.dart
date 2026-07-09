import 'package:flutter_test/flutter_test.dart';

/// Bounded alternative to `tester.pumpAndSettle()`. pumpAndSettle's
/// default 10-minute timeout means any widget that never fully "settles"
/// (a lingering ripple, an implicit animation edge case) hangs the test
/// for the full 10 minutes AND leaves TestAsyncUtils' guard in a bad
/// state, cascading failures into every subsequent test in the process.
/// Our animations are all short-lived (<=300ms), so two bounded pumps
/// are enough and can never hang.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}
