import 'dart:math';

import 'package:flutter/material.dart';
import 'package:newrelic_mobile/loglevel.dart';
import 'package:newrelic_mobile/newrelic_mobile.dart';

import 'app_state.dart';

// Crash names show up in New Relic so each crash type is distinguishable.
const List<String> _crashNames = [
  'NullPointerCrash',
  'OutOfMemoryCrash',
  'DatabaseCorruptionCrash',
  'RenderingCrash',
  'CheckoutFlowCrash',
  'SyncWorkerCrash',
];

class CrashPage extends StatelessWidget {
  const CrashPage({super.key});

  Future<void> _crash() async {
    final name = _crashNames[Random().nextInt(_crashNames.length)];
    await NewrelicMobile.instance.setAttribute(
      'crashUsername',
      currentUsername.value,
    );
    await recordAction('about_to_crash', {'crashName': name});
    appLog(LogLevel.ERROR, 'Crashing the app on purpose', {'crashName': name});
    // Give the agent a moment to persist the breadcrumb before the app dies.
    await Future<void>.delayed(const Duration(seconds: 1));
    // Native crash: terminates the app and is reported on the next launch.
    NewrelicMobile.instance.crashNow(name: name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crash')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This will crash the app with a randomly chosen crash type. '
              'New Relic reports the crash the next time the app launches.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _crash,
              icon: const Icon(Icons.warning),
              label: const Text('Crash the app'),
            ),
          ],
        ),
      ),
    );
  }
}
