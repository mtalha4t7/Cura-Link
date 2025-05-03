import 'package:cura_link/src/utils/app_bindings.dart';
import 'package:cura_link/src/utils/theme/theme.dart';
import 'package:cura_link/app.dart'; // Update with correct path if needed
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('App widget test', (WidgetTester tester) async {
    // Build the App widget and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that the CircularProgressIndicator is present (home screen)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Verify that the GetMaterialApp is initialized with correct theme
    final themeData = Theme.of(tester.element(find.byType(GetMaterialApp)));
    expect(themeData.brightness,
        Brightness.light); // Check for light theme by default

    // Verify if the initial binding is set up
    final binding = Get.isRegistered<InitialBinding>();
    expect(binding, isTrue);

    // Verify if the Scaffold widget is present
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
