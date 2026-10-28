import 'package:flutter/foundation.dart';
import 'package:newrelic_mobile/loglevel.dart';
import 'package:newrelic_mobile/newrelic_mobile.dart';

/// Username set on the home screen, sent to the back-end services so they can
/// tag their traces with it.
final ValueNotifier<String> currentUsername = ValueNotifier<String>('');

/// Records a breadcrumb for a user action, tagged with the current username.
Future<bool> recordAction(String action, [Map<String, dynamic>? details]) {
  return NewrelicMobile.instance.recordBreadcrumb(
    'UserAction',
    eventAttributes: {
      'action': action,
      'username': currentUsername.value,
      ...?details,
    },
  );
}

/// Sends a log line to New Relic, with key=value details and the username
/// appended so it can be searched on.
void appLog(LogLevel level, String message, [Map<String, Object?>? details]) {
  final parts = <String>[
    message,
    if (details != null) ...details.entries.map((e) => '${e.key}=${e.value}'),
    'username=${currentUsername.value.isEmpty ? 'anonymous' : currentUsername.value}',
  ];
  NewrelicMobile.instance.log(level, parts.join(' | '));
}
