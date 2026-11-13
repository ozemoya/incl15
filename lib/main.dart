import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ScienceSignalApp());
}

class ScienceSignalApp extends StatelessWidget {
  const ScienceSignalApp({super.key, this.client});
  final http.Client? client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Science Signal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: ScienceQuizScreen(client: client),
    );
  }
}

class ScienceQuestion {
  const ScienceQuestion({required this.text, required this.correctAnswer});

  final String text;
  final String correctAnswer;

  factory ScienceQuestion.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['question'] is! String ||
        value['correct_answer'] is! String ||
        value['incorrect_answers'] is! List) {
      throw const FormatException('Invalid question data.');
    }

    final text = Uri.decodeComponent(value['question'] as String);
    final correctAnswer = Uri.decodeComponent(
      value['correct_answer'] as String,
    );
    final incorrectAnswers = value['incorrect_answers'] as List;
    if (text.trim().isEmpty ||
        (correctAnswer != 'True' && correctAnswer != 'False') ||
        incorrectAnswers.length != 1 ||
        incorrectAnswers.first is! String) {
      throw const FormatException('Invalid true-or-false question.');
    }
    final incorrectAnswer = Uri.decodeComponent(
      incorrectAnswers.first as String,
    );
    if ((incorrectAnswer != 'True' && incorrectAnswer != 'False') ||
        incorrectAnswer == correctAnswer) {
      throw const FormatException('Invalid true-or-false answers.');
    }
    return ScienceQuestion(text: text, correctAnswer: correctAnswer);
  }
}

class ScienceQuizScreen extends StatefulWidget {
  const ScienceQuizScreen({super.key, this.client});
  final http.Client? client;

  @override
  State<ScienceQuizScreen> createState() => _ScienceQuizScreenState();
}

class _ScienceQuizScreenState extends State<ScienceQuizScreen> {
  static final _questionUri = Uri.https('opentdb.com', '/api.php', {
    'amount': '5',
    'category': '17',
    'difficulty': 'medium',
    'type': 'boolean',
    'encode': 'url3986',
  });

  List<ScienceQuestion> _questions = [];
  final _answers = <String>[];
  bool _sending = false;
  bool _simulated = false;
  bool _loading = true;

  int get _score => _answers
      .asMap()
      .entries
      .where((entry) => entry.value == _questions[entry.key].correctAnswer)
      .length;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
      _questions = [];
      _answers.clear();
      _simulated = false;
    });

    try {
      final response =
          await (widget.client?.get(_questionUri) ?? http.get(_questionUri))
              .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw FormatException('Server returned HTTP ${response.statusCode}.');
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['response_code'] != 0) {
        throw const FormatException('The trivia API did not return questions.');
      }
      final results = data['results'];
      if (results is! List || results.length != 5) {
        throw const FormatException('Expected five trivia questions.');
      }
      final questions = results.map(ScienceQuestion.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } on TimeoutException {
      _showError('The request timed out. Please try again.');
    } on http.ClientException catch (error) {
      _showError('The request failed: ${error.message}');
    } on FormatException catch (error) {
      _showError('Could not load questions: ${error.message}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _loading = false;
    });
  }

  Future<void> _simulate() async {
    if (_sending || _simulated) return;
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _sending = false;
      _simulated = true;
    });
  }

  Widget _round() {
    final index = _questionIndex;
    final question = _questions[index];
    final answered = _answers.length > index;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Question ${index + 1} of 5'),
        const SizedBox(height: 16),
        Text(question.text, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        for (final choice in ['True', 'False'])
          OutlinedButton(
            style: answered
                ? OutlinedButton.styleFrom(
                    disabledForegroundColor: choice == question.correctAnswer
                        ? Colors.green.shade800
                        : _answers[index] == choice
                        ? Theme.of(context).colorScheme.error
                        : null,
                  )
                : null,
            onPressed: answered
                ? null
                : () {
                    if (_answers.length == index) {
                      setState(() => _answers.add(choice));
                    }
                  },
            child: Text(choice),
          ),
        if (answered) ...[
          Text(
            _answers[index] == question.correctAnswer
                ? 'Correct!'
                : 'Incorrect. The correct answer is ${question.correctAnswer}.',
          ),
          FilledButton(
            onPressed: () => setState(() => _questionIndex++),
            child: Text(index == 4 ? 'See results' : 'Next question'),
          ),
        ],
      ],
    );
  }

  int _questionIndex = 0;

  Widget _results() {
    final payload = jsonEncode({
      'score': _score,
      'total': _questions.length,
      'category': 'Science & Nature',
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Score: $_score / 5',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final (index, question) in _questions.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${index + 1}. ${question.text}'),
            subtitle: Text(
              'Your answer: ${_answers[index]} · Correct answer: ${question.correctAnswer}',
            ),
          ),
        FilledButton(
          onPressed: _sending || _simulated ? null : _simulate,
          child: Text(_sending ? 'Simulating…' : 'Simulate score submission'),
        ),
        if (_simulated) ...[
          const Text('Simulation complete. No server request was sent.'),
          SelectableText(payload),
        ],
        OutlinedButton(
          onPressed: _sending
              ? null
              : () {
                  _questionIndex = 0;
                  _loadQuestions();
                },
          child: const Text('Play again'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Science Signal')),
    body: SafeArea(
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading questions',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_error case final error?) ...[
                  Text(error),
                  FilledButton(
                    onPressed: _loadQuestions,
                    child: const Text('Retry'),
                  ),
                ] else if (_questionIndex == _questions.length)
                  _results()
                else
                  _round(),
              ],
            ),
    ),
  );
}
