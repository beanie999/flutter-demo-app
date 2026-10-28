import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:newrelic_mobile/loglevel.dart';

import 'app_state.dart';

// The iOS simulator shares the Mac's network, so localhost reaches the front-end.
const String _frontEndUrl = 'http://localhost:3001/api/order';
const int _requestCount = 10;

class _Result {
  _Result(this.orderId, this.status, this.millis, this.message);
  final String orderId;
  final int? status;
  final int millis;
  final String message;
}

class TracingPage extends StatefulWidget {
  const TracingPage({super.key});

  @override
  State<TracingPage> createState() => _TracingPageState();
}

class _TracingPageState extends State<TracingPage> {
  final List<_Result> _results = [];
  bool _sending = false;

  Future<_Result> _request(HttpClient client, int n) async {
    final orderId = 'order-${DateTime.now().millisecondsSinceEpoch}-$n';
    final sw = Stopwatch()..start();
    try {
      final req = await client.getUrl(
        Uri.parse('$_frontEndUrl?orderId=$orderId'),
      );
      // The New Relic agent adds the distributed tracing headers to this call.
      final username = currentUsername.value;
      req.headers.set('x-username', username.isEmpty ? 'anonymous' : username);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      String message = 'ok';
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        message = json['ok'] == true
            ? 'ok'
            : 'back-end ${json['backendStatus'] ?? '?'}: ${json['error'] ?? ''}';
      } catch (_) {}
      return _Result(orderId, res.statusCode, sw.elapsedMilliseconds, message);
    } catch (e) {
      return _Result(orderId, null, sw.elapsedMilliseconds, e.toString());
    }
  }

  void _logResult(_Result r) {
    final details = {'orderId': r.orderId, 'status': r.status, 'ms': r.millis};
    if (r.status == null) {
      appLog(LogLevel.ERROR, 'Traced request failed: ${r.message}', details);
    } else if (r.status! >= 400) {
      appLog(
        LogLevel.ERROR,
        'Traced request returned an error: ${r.message}',
        details,
      );
    } else {
      appLog(LogLevel.INFO, 'Traced request succeeded', details);
    }
  }

  Future<void> _sendAll() async {
    recordAction('send_traced_requests', {'count': _requestCount});
    appLog(LogLevel.INFO, 'Sending traced requests', {
      'count': _requestCount,
      'target': _frontEndUrl,
    });
    setState(() {
      _sending = true;
      _results.clear();
    });
    final client = HttpClient();
    try {
      for (var i = 1; i <= _requestCount; i++) {
        final result = await _request(client, i);
        _logResult(result);
        if (!mounted) return;
        setState(() => _results.add(result));
      }
    } finally {
      client.close();
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = currentUsername.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Distributed tracing')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              username.isEmpty
                  ? 'No username set - requests will be sent as "anonymous".'
                  : 'Sending as "$username"',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sending ? null : _sendAll,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_tree),
                label: Text(
                  _sending
                      ? 'Sending...'
                      : 'Send $_requestCount traced requests',
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = _results[i];
                final ok = r.status != null && r.status! < 400;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ok ? Colors.green : Colors.red,
                    child: Text(
                      '${r.status ?? '—'}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text(r.orderId),
                  subtitle: Text('${r.millis} ms - ${r.message}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
