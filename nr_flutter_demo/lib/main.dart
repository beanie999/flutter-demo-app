import 'package:flutter/material.dart';
import 'package:newrelic_mobile/config.dart';
import 'package:newrelic_mobile/loglevel.dart';
import 'package:newrelic_mobile/newrelic_mobile.dart';
import 'package:newrelic_mobile/newrelic_navigation_observer.dart';

import 'app_state.dart';
import 'crash_page.dart';
import 'exceptions_page.dart';
import 'network_page.dart';
import 'tracing_page.dart';

// Supply at run time: flutter run --dart-define=NR_IOS_TOKEN=<mobile app token>
const String nrIosToken = String.fromEnvironment('NR_IOS_TOKEN');

void main() {
  final config = Config(
    accessToken: nrIosToken,
    analyticsEventEnabled: true,
    crashReportingEnabled: true,
    interactionTracingEnabled: true,
    networkRequestEnabled: true,
    httpInstrumentationEnabled: true,
    loggingEnabled: true,
    logLevel: LogLevel.DEBUG,
  );

  // start() initialises bindings, error handlers and the agent, then runs the app.
  NewrelicMobile.instance.start(config, () {
    runApp(const DemoApp());
  });
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NR Flutter Demo',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      navigatorObservers: [NewRelicNavigationObserver()],
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _username = TextEditingController();
  final _country = TextEditingController();
  final _animal = TextEditingController();

  @override
  void initState() {
    super.initState();
    appLog(LogLevel.INFO, 'Home screen opened');
  }

  @override
  void dispose() {
    _username.dispose();
    _country.dispose();
    _animal.dispose();
    super.dispose();
  }

  Future<void> _setUsername() async {
    final name = _username.text.trim();
    if (name.isEmpty) {
      appLog(LogLevel.WARN, 'Set username ignored: empty value');
      return;
    }
    currentUsername.value = name;
    recordAction('set_username');
    final ok = await NewrelicMobile.instance.setUserId(name);
    appLog(
      ok == true ? LogLevel.INFO : LogLevel.ERROR,
      ok == true ? 'Username set' : 'Username could not be set',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok == true
              ? 'Username set to "$name"'
              : 'Username was not set (is the agent started?)',
        ),
      ),
    );
  }

  Future<void> _sendEvent() async {
    recordAction('send_custom_event', {
      'country': _country.text.trim(),
      'animal': _animal.text.trim(),
    });
    final attributes = <String, dynamic>{
      'country': _country.text.trim(),
      'animal': _animal.text.trim(),
    };
    final ok = await NewrelicMobile.instance.recordCustomEvent(
      'DemoEvent',
      eventName: 'CountryAnimalSelected',
      eventAttributes: attributes,
    );
    appLog(
      ok ? LogLevel.INFO : LogLevel.ERROR,
      ok ? 'Custom event recorded' : 'Custom event was not recorded',
      attributes,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Sent DemoEvent: $attributes'
              : 'Event was not recorded (is the agent started?)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NR Flutter Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _username,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _setUsername(),
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _setUsername,
            icon: const Icon(Icons.person),
            label: const Text('Set username'),
          ),
          const SizedBox(height: 24),
          Text('Custom event', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _country,
            decoration: const InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _animal,
            decoration: const InputDecoration(
              labelText: 'Animal',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _sendEvent,
            icon: const Icon(Icons.send),
            label: const Text('Send custom event'),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: 'NetworkPage'),
                builder: (_) => const NetworkPage(),
              ),
            ),
            icon: const Icon(Icons.network_check),
            label: const Text('Network stats'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: 'TracingPage'),
                builder: (_) => const TracingPage(),
              ),
            ),
            icon: const Icon(Icons.account_tree),
            label: const Text('Distributed tracing'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: 'ExceptionsPage'),
                builder: (_) => const ExceptionsPage(),
              ),
            ),
            icon: const Icon(Icons.bug_report),
            label: const Text('Handled exceptions'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: 'CrashPage'),
                builder: (_) => const CrashPage(),
              ),
            ),
            icon: const Icon(Icons.warning_amber),
            label: const Text('Crash'),
          ),
        ],
      ),
    );
  }
}
