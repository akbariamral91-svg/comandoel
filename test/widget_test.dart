import 'package:flutter_test/flutter_test.dart';

import 'package:komandoel/main.dart';

void main() {
  testWidgets('Komandoel app starts on the home screen', (tester) async {
    await tester.pumpWidget(const KomandoelApp());
    await tester.pump();

    expect(find.text('بازی حدس و هوش'), findsOneWidget);
  });
}
