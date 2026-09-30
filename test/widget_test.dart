import 'package:devhub/main.dart';
import 'package:devhub/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell shows tools and about tab', (tester) async {
    await tester.pumpWidget(const DevhubApp());
    expect(find.text('Devhub'), findsWidgets);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('Features'), findsOneWidget);
  });

  testWidgets('switching tools changes the output', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    String out() => tester
        .widget<SelectableText>(find.byKey(const Key('tool-output')))
        .data!;
    expect(out(), contains('"name": "devhub"'));

    await tester.tap(find.text('JSON minify'));
    await tester.pump();
    expect(out(), '{"name":"devhub","tools":9}');

    await tester.enterText(find.byKey(const Key('tool-input')), 'hello world');
    await tester.tap(find.text('snake_case'));
    await tester.pump();
    expect(out(), 'hello_world');
  });
}
