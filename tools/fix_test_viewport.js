const fs = require('fs');
let code = fs.readFileSync('mobile/test/widget_test.dart', 'utf8');

code = code.replace(
  `    testWidgets('HomeScreen renders dashboard with current balance and metrics', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen(), locale: const Locale('ar')));`,
  `    testWidgets('HomeScreen renders dashboard with current balance and metrics', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const HomeScreen(), locale: const Locale('ar')));`
);

fs.writeFileSync('mobile/test/widget_test.dart', code, 'utf8');
console.log('Updated test viewport');
