import 'dart:math';

import 'package:flutter/material.dart';
import 'package:newrelic_mobile/loglevel.dart';
import 'package:newrelic_mobile/newrelic_mobile.dart';

import 'app_state.dart';

const int _exceptionCount = 5;

class PaymentDeclinedException implements Exception {
  PaymentDeclinedException(this.reason);
  final String reason;

  @override
  String toString() => 'PaymentDeclinedException: $reason';
}

// Each entry really throws, so the stack trace points at the failing code.
final Map<String, void Function()> _throwers = {
  'FormatException': () => int.parse('not-a-number'),
  'RangeError': () => <int>[1, 2, 3][10],
  'StateError': () => <int>[].first,
  'ArgumentError': () =>
      throw ArgumentError.value(-1, 'quantity', 'must be positive'),
  'TypeError': () => (Object() as String).length,
  'UnsupportedError': () => List<int>.unmodifiable([1]).add(2),
  'PaymentDeclinedException': () =>
      throw PaymentDeclinedException('card expired'),
  'UnimplementedError': () => throw UnimplementedError('export to PDF'),
};

final Random _random = Random();

class _Result {
  _Result(this.name, this.message);
  final String name;
  final String message;
}

class ExceptionsPage extends StatefulWidget {
  const ExceptionsPage({super.key});

  @override
  State<ExceptionsPage> createState() => _ExceptionsPageState();
}

class _ExceptionsPageState extends State<ExceptionsPage> {
  final List<_Result> _results = [];

  void _runAll() {
    recordAction('run_handled_exceptions', {'count': _exceptionCount});
    appLog(LogLevel.INFO, 'Running handled exceptions', {
      'count': _exceptionCount,
    });
    final names = _throwers.keys.toList();
    final results = <_Result>[];
    for (var i = 0; i < _exceptionCount; i++) {
      final name = names[_random.nextInt(names.length)];
      try {
        _throwers[name]!();
      } catch (error, stackTrace) {
        // Handled: report to New Relic without crashing the app.
        NewrelicMobile.instance.recordError(
          error,
          stackTrace,
          attributes: {
            'exceptionType': name,
            'username': currentUsername.value,
            'screen': 'ExceptionsPage',
          },
        );
        appLog(LogLevel.ERROR, 'Handled exception: $error', {
          'exceptionType': name,
        });
        results.add(_Result(name, error.toString()));
      }
    }
    setState(() {
      _results
        ..clear()
        ..addAll(results);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Handled exceptions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _runAll,
                icon: const Icon(Icons.bug_report),
                label: const Text('Run $_exceptionCount random exceptions'),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.orange),
                title: Text(_results[i].name),
                subtitle: Text(_results[i].message),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
