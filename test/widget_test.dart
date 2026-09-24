import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sina/main.dart';

void main() {
  testWidgets('SinaStoreApp renders LoginScreen by default in Kurdish', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Allow flutter_animate timers to finish
    await tester.pumpAndSettle();

    // Verify that Kurdish Sign In text is rendered
    expect(find.text('چوونە ژوورەوە'), findsWidgets);
  });
}
