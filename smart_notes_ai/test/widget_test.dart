import 'package:flutter_test/flutter_test.dart';
import 'package:smart_notes_ai/main.dart';

void main() {
  testWidgets('App start smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartNotesApp());

    // Verify that the initial text is displayed.
    expect(find.text('Smart Notes AI is ready!'), findsOneWidget);
  });
}
