import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vachanamrut_app/main.dart';
import 'package:vachanamrut_app/services/app_settings_service.dart';
import 'package:vachanamrut_app/widgets/settings_page.dart';

void main() {
  testWidgets('shows the Vachanamrut quote experience', (tester) async {
    await tester.pumpWidget(const VachanamrutApp());
    await pumpUntilFound(tester, find.text('Widget Preview'));

    expect(find.text('Vachanamrut Daily'), findsOneWidget);
    expect(find.text('Widget Preview'), findsOneWidget);
    expect(find.byWidgetPredicate(_hasGujaratiText), findsWidgets);
    expect(find.byIcon(Icons.widgets_rounded), findsOneWidget);
  });

  testWidgets('handles a zero quote interval without crashing', (tester) async {
    SharedPreferences.setMockInitialValues({'quote_interval_minutes': 0});

    await tester.pumpWidget(const VachanamrutApp());
    await pumpUntilFound(tester, find.text('Vachanamrut Daily'));

    expect(find.text('Vachanamrut Daily'), findsOneWidget);
  });

  testWidgets('opens settings without crashing when intervals are not in the dropdown options', (
    tester,
  ) async {
    final service = AppSettingsService();
    await service.initialize();

    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(settingsService: service)),
    );
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
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
