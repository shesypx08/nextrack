import 'package:flutter_test/flutter_test.dart';
import 'package:nextrack/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NexTrackApp());

    // Verify that Splash Screen is shown.
    expect(find.text('NexTrack'), findsOneWidget);
  });
}
