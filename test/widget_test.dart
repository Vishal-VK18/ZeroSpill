import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospill/app.dart';

void main() {
  testWidgets('App launches correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ZerospillApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
