import 'package:flutter_test/flutter_test.dart';

import 'package:parkinsons_project/main.dart';

void main() {
  testWidgets('Parkinson Care app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ParkinsonApp());

    expect(find.byType(ParkinsonApp), findsOneWidget);
  });
}