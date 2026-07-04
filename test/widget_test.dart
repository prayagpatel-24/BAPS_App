import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vachanamrut_app/main.dart';

void main() {
  testWidgets('shows the Vachanamrut quote experience', (tester) async {
    await tester.pumpWidget(const VachanamrutApp());
    await pumpUntilFound(tester, find.text('Widget Preview'));

    expect(find.text('Vachanamrut Daily'), findsOneWidget);
    expect(find.text('Widget Preview'), findsOneWidget);
    expect(find.byWidgetPredicate(_hasGujaratiText), findsWidgets);
    expect(find.byIcon(Icons.widgets_rounded), findsOneWidget);
  });

  testWidgets('shows an English translation button for Gujarati mode', (
    tester,
  ) async {
    await tester.pumpWidget(const VachanamrutApp());
    await pumpUntilFound(tester, find.text('Show English'));

    expect(find.text('Show English'), findsOneWidget);
  });
}

bool _hasGujaratiText(Widget widget) {
  return widget is Text &&
      widget.data != null &&
      RegExp(r'[\u0A80-\u0AFF]').hasMatch(widget.data!);
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 10,
}) async {
  for (var i = 0; i < attempts; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}
