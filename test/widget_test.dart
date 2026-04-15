import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_user/sanyan_user.dart';

import 'package:sanyan_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await LocalStorage.init();
    await tester.pumpWidget(const SanyanApp());
    // Flush the Future.delayed timer in SplashPage
    await tester.pump(const Duration(seconds: 1));
  });
}
