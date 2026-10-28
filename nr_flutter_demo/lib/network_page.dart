import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:newrelic_mobile/loglevel.dart';

import 'app_state.dart';

// httpbin echoes back whatever status code is in the path.
const String _baseUrl = 'https://httpbin.org/status';

// Relative likelihood of each status code, so the mix is uneven like real traffic.
const Map<int, int> _weights = {
  200: 40, 201: 8, 204: 5, // success
  301: 3, 302: 3, // redirects (not followed, so the 3xx itself is recorded)
  400: 5, 401: 4, 403: 3, 404: 10, 429: 4, // client errors
  500: 6, 502: 3, 503: 3, 504: 3, // server errors
};

const int _requestCount = 10;

final Random _random = Random();

int _randomStatusCode() {
  final total = _weights.values.reduce((a, b) => a + b);
  var pick = _random.nextInt(total);
  for (final entry in _weights.entries) {
    pick -= entry.value;
    if (pick < 0) return entry.key;
  }
  return 200;
}

class _Result {
  _Result(this.code, this.actual, this.millis, [this.error]);
  final int code;
  final int? actual;
  final int millis;
  final String? error;
}

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  final List<_Result> _results = [];
  bool _sending = false;

  Future<_Result> _request(HttpClient client, int code) async {
    final sw = Stopwatch()..start();
    try {
      final req = await client.getUrl(Uri.parse('$_baseUrl/$code'));
      req.followRedirects = false;
      final res = await req.close();
      await res.drain<void>();
      return _Result(code, res.statusCode, sw.elapsedMilliseconds);
    } catch (e) {
      return _Result(code, null, sw.elapsedMilliseconds, e.toString());
    }
  }

  void _logResult(_Result r) {
    final details = {
      'url': '$_baseUrl/${r.code}',
      'status': r.actual,
      'ms': r.millis,
    };
    if (r.actual == null) {
      appLog(LogLevel.ERROR, 'Network request failed: ${r.error}', details);
    } else if (r.actual! >= 500) {
      appLog(LogLevel.ERROR, 'Server error response', details);
    } else if (r.actual! >= 400) {
      appLog(LogLevel.WARN, 'Client error response', details);
    } else {
      appLog(LogLevel.INFO, 'Request succeeded', details);
    }
  }

  Future<void> _sendAll() async {
    recordAction('send_network_requests', {'count': _requestCount});
    appLog(LogLevel.INFO, 'Sending network requests', {'count': _requestCount});
    setState(() {
      _sending = true;
      _results.clear();
    });
    // dart:io HttpClient calls are captured by the New Relic agent.
    final client = HttpClient();
    try {
      for (var i = 0; i < _requestCount; i++) {
        final result = await _request(client, _randomStatusCode());
        _logResult(result);
        if (!mounted) return;
        setState(() => _results.add(result));
      }
    } finally {
      client.close();
      if (mounted) setState(() => _sending = false);
    }
  }

  Color _colorFor(BuildContext context, int? code) {
    if (code == null) return Colors.grey;
    if (code >= 500) return Colors.red;
    if (code >= 400) return Colors.orange;
    if (code >= 300) return Colors.blue;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network')),
      body: Column(
        children: [
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
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _sending
                      ? 'Sending...'
                      : 'Send $_requestCount random network requests',
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
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _colorFor(context, r.actual),
                    child: Text(
                      '${r.actual ?? '—'}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text('GET /status/${r.code}'),
                  subtitle: Text(r.error ?? '${r.millis} ms'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
