import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yarmouk_water_app/main_web.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Demo login -> Reports -> Excel export works without errors',
      (tester) async {
    await tester.pumpWidget(const YarmoukWebApp());
    await _settle(tester);

    // Demo login (no server)
    final demoBtn = find.text('دخول تجريبي (بدون سيرفر)');
    expect(demoBtn, findsOneWidget);
    await tester.tap(demoBtn);
    await _settle(tester);

    // We should now be in the admin shell (dashboard visible)
    expect(find.text('لوحة المعلومات'), findsWidgets);

    // Open Reports module
    final reportsNav = find.text('التقارير');
    expect(reportsNav, findsOneWidget);
    await tester.tap(reportsNav);
    await _settle(tester);

    // Trigger Excel export
    final exportBtn = find.text('تصدير Excel');
    expect(exportBtn, findsOneWidget);
    await tester.tap(exportBtn);
    await _settle(tester);

    // No uncaught exceptions during the whole flow
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settle(tester) async {
  try {
    await tester.pumpAndSettle(const Duration(seconds: 5));
  } on Object {
    // Ignore settle timeouts caused by ongoing animations/timers.
    await tester.pump(const Duration(seconds: 1));
  }
}
