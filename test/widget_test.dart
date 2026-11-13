import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:science_trivia/main.dart';

void main() {
  testWidgets('failure, retry, scoring, review, simulation and replay', (
    tester,
  ) async {
    var calls = 0;
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      calls++;
      if (calls == 1) return http.Response('', 503);
      return http.Response(
        jsonEncode({
          'response_code': 0,
          'results': List.generate(
            5,
            (i) => {
              'question': 'Science%20item%20${i + 1}',
              'correct_answer': 'True',
              'incorrect_answers': ['False'],
            },
          ),
        }),
        200,
      );
    });
    await tester.pumpWidget(ScienceSignalApp(client: client));
    await tester.pumpAndSettle();
    expect(find.textContaining('503'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text(i == 0 ? 'False' : 'True'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          i == 0 ? 'Incorrect. The correct answer is True.' : 'Correct!',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(i == 4 ? 'See results' : 'Next question'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Score: 4 / 5'), findsOneWidget);
    final submit = find.text('Simulate score submission');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(
      find.text('Simulation complete. No server request was sent.'),
      findsOneWidget,
    );
    final replay = find.text('Play again');
    await tester.ensureVisible(replay);
    await tester.tap(replay);
    await tester.pumpAndSettle();
    expect(find.text('Question 1 of 5'), findsOneWidget);
    expect(calls, 3);
  });
}
