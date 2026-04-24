// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:tilemate/main.dart';

void main() {
  testWidgets('Tilemate app starts on calculator tab', (WidgetTester tester) async {
    await tester.pumpWidget(const TileMateApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Calculate'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Tiles'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
