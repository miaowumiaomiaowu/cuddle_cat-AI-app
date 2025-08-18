import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cuddle_cat/screens/metrics_debug_screen.dart';
import 'package:cuddle_cat/services/metrics_api_client.dart';

class TestMetricsApiClient extends MetricsApiClient {
  final List<Map<String, dynamic>> snapshots;
  int _i = 0;
  TestMetricsApiClient(this.snapshots);
  @override
  Future<Map<String, dynamic>?> fetchMetrics() async {
    final idx = _i < snapshots.length ? _i : snapshots.length - 1;
    final v = snapshots[idx];
    _i++;
    return Future.value(v);
  }
}

Map<String, dynamic> makeMetrics(Map<String, num> counters, {int uptime = 100, double? p95, double? avg, double? vec}) => {
      'counters': counters,
      'uptime_seconds': uptime,
      'latency_ms_p95': p95,
      'latency_ms_avg': avg,
      'mem_vector_score_avg': vec,
    };

void main() {
  testWidgets('MetricsDebugScreen shows deltas and auto-refresh updates', (tester) async {
    final m1 = makeMetrics({'chat_reply_requests': 10, 'mem_retrieval_total': 5}, uptime: 100);
    final m2 = makeMetrics({'chat_reply_requests': 13, 'mem_retrieval_total': 7}, uptime: 105);
    final m3 = makeMetrics({'chat_reply_requests': 15, 'mem_retrieval_total': 8}, uptime: 110);

    final client = TestMetricsApiClient([m1, m2, m3]);

    await tester.pumpWidget(MaterialApp(home: MetricsDebugScreen(client: client)));
    await tester.pumpAndSettle();

    // First load: delta is from 0 -> 10
    expect(find.text('Counters (Δ since last refresh)'), findsOneWidget);
    expect(find.text('chat_reply_requests'), findsOneWidget);
    expect(find.text('10 (+10)'), findsWidgets);

    // Manual refresh: 10 -> 13, delta +3
    await tester.tap(find.text('刷新'));
    await tester.pumpAndSettle();
    expect(find.text('13 (+3)'), findsWidgets);

    // Auto refresh: 13 -> 15 after 5s, delta +2
    await tester.tap(find.text('自动刷新(5s)'));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('15 (+2)'), findsWidgets);
  });
}

