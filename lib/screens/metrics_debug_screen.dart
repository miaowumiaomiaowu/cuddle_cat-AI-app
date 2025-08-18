import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/artistic_theme.dart';
import '../services/metrics_api_client.dart';

class MetricsDebugScreen extends StatefulWidget {
  final MetricsApiClient? client;
  const MetricsDebugScreen({super.key, this.client});

  @override
  State<MetricsDebugScreen> createState() => _MetricsDebugScreenState();
}

class _MetricsDebugScreenState extends State<MetricsDebugScreen> {
  late final MetricsApiClient _api = widget.client ?? MetricsApiClient();
  Map<String, dynamic>? _data;
  Map<String, num>? _lastCounters;
  bool _loading = false;
  bool _auto = false;
  Timer? _timer;

  // History for trends
  final List<double> _histP95 = [];
  final List<double> _histAvg = [];
  final List<double> _histVec = [];
  final int _histCap = 50;

  void _pushHist(List<double> list, double v) {
    list.add(v);
    if (list.length > _histCap) list.removeRange(0, list.length - _histCap);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await _api.fetchMetrics();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _lastCounters = (_data?['counters'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num)));
      _data = d;
      final p95 = (d?['latency_ms_p95'] as num?);
      final avg = (d?['latency_ms_avg'] as num?);
      final vec = (d?['mem_vector_score_avg'] as num?);
      if (p95 != null) _pushHist(_histP95, p95.toDouble());
      if (avg != null) _pushHist(_histAvg, avg.toDouble());
      if (vec != null) _pushHist(_histVec, vec.toDouble());
    });
  }

  void _toggleAuto() {
    setState(() => _auto = !_auto);
    _timer?.cancel();
    if (_auto) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counters = (_data?['counters'] as Map<String, dynamic>?) ?? {};
    final vecAvg = _data?['mem_vector_score_avg'];
    return Scaffold(
      appBar: AppBar(title: const Text('Metrics Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _load,
                    icon: _loading ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.refresh),
                    label: const Text('刷新'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _toggleAuto,
                    icon: Icon(_auto ? Icons.pause : Icons.play_arrow),
                    label: Text(_auto ? '停止自动刷新' : '自动刷新(5s)'),
                  ),
                  const SizedBox(width: 12),
                  Text('运行: ${_data?['uptime_seconds'] ?? '-'}s'),
                  const SizedBox(width: 12),
                  Text('p95: ${_data?['latency_ms_p95'] ?? '-'}ms'),
                  const SizedBox(width: 12),
                  Text('avg: ${_data?['latency_ms_avg']?.toStringAsFixed(1) ?? '-'}ms'),
                  const SizedBox(width: 12),
                  Text('vecμ: ${vecAvg == null ? '-' : (vecAvg as num).toStringAsFixed(3)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Alerts based on recent deltas
            if (_data != null) ...() {
              final m = counters;
              num d(String k) => (m[k] as num? ?? 0) - (_lastCounters?[k] ?? 0);
              final memTotal = d('mem_retrieval_total');
              final memFallback = d('mem_retrieval_fallback');
              final fbRatio = (memTotal > 0) ? (memFallback / memTotal) : 0;
              final req = d('chat_reply_requests');
              final errs = d('chat_reply_errors');
              final errRatio = (req > 0) ? (errs / req) : 0;
              Color toColor(num r) => r >= 0.5 ? Colors.redAccent : (r >= 0.3 ? Colors.orangeAccent : Colors.green);
              return [
                if (memTotal > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: toColor(fbRatio).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text('检索回退: ${memFallback.toStringAsFixed(0)}/${memTotal.toStringAsFixed(0)} (${(fbRatio*100).toStringAsFixed(1)}%)',
                      style: TextStyle(color: toColor(fbRatio))),
                  ),
                const SizedBox(height: 8),
                if (req > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: toColor(errRatio).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text('回复错误率: ${errs.toStringAsFixed(0)}/${req.toStringAsFixed(0)} (${(errRatio*100).toStringAsFixed(1)}%)',
                      style: TextStyle(color: toColor(errRatio))),
                  ),
                const SizedBox(height: 12),
              ];
            }(),
            if (_data == null) const Text('尚未获取到指标数据'),
            if (_data?['error'] == 'forbidden') Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: const Text('无法访问指标：请在 .env 配置 METRICS_API_KEY 并确保后端匹配', style: TextStyle(color: Colors.orange)),
            ),
            if (_data != null && _data?['error'] != 'forbidden') Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  Text('趋势 (最近50个样本)', style: ArtisticTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildTrendRow('p95(ms)', _histP95, color: Colors.redAccent),
                  const SizedBox(height: 6),
                  _buildTrendRow('avg(ms)', _histAvg, color: Colors.orangeAccent),
                  const SizedBox(height: 6),
                  _buildTrendRow('vecμ', _histVec, color: Colors.blueAccent),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Row(
                      children: [
                        Text('cur: ${_histP95.isEmpty ? '-' : _histP95.last.toStringAsFixed(1)}ms', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        const SizedBox(width: 8),
                        Text('min: ${_histP95.isEmpty ? '-' : _histP95.reduce((a,b)=>a<b?a:b).toStringAsFixed(1)}ms', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        const SizedBox(width: 8),
                        Text('max: ${_histP95.isEmpty ? '-' : _histP95.reduce((a,b)=>a>b?a:b).toStringAsFixed(1)}ms', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Row(
                      children: [
                        Text('cur: ${_histAvg.isEmpty ? '-' : _histAvg.last.toStringAsFixed(1)}ms', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        const SizedBox(width: 8),
                        Text('min: ${_histAvg.isEmpty ? '-' : _histAvg.reduce((a,b)=>a<b?a:b).toStringAsFixed(1)}ms', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        const SizedBox(width: 8),
                        Text('max: ${_histAvg.isEmpty ? '-' : _histAvg.reduce((a,b)=>a>b?a:b).toStringAsFixed(1)}ms', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Row(
                      children: [
                        Text('cur: ${_histVec.isEmpty ? '-' : _histVec.last.toStringAsFixed(3)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        const SizedBox(width: 8),
                        Text('min: ${_histVec.isEmpty ? '-' : _histVec.reduce((a,b)=>a<b?a:b).toStringAsFixed(3)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        const SizedBox(width: 8),
                        Text('max: ${_histVec.isEmpty ? '-' : _histVec.reduce((a,b)=>a>b?a:b).toStringAsFixed(3)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Counters (Δ since last refresh)', style: ArtisticTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...counters.entries.map((e) {
                    final prev = _lastCounters?[e.key] ?? 0;
                    final now = (e.value as num);
                    final delta = now - prev;
                    final deltaStr = delta == 0 ? '' : ' (+${delta.toStringAsFixed(0)})';
                    return ListTile(
                      dense: true,
                      title: Text(e.key),
                      trailing: Text('${e.value}$deltaStr'),
                    );

                  }),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

Widget _buildTrendRow(String label, List<double> data, {Color color = Colors.blueGrey}) {
  final points = data;
  return SizedBox(
    height: 60,
    child: CustomPaint(
      painter: _TrendPainter(points: points, color: color, label: label),
      child: Container(),
    ),
  );
}

class _TrendPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final String label;
  _TrendPainter({required this.points, required this.color, required this.label});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      text: TextSpan(text: label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(0, 0));

    if (points.isEmpty) return;
    final minV = points.reduce((a,b)=> a < b ? a : b);
    final maxV = points.reduce((a,b)=> a > b ? a : b);
    final pad = 8.0;
    final w = size.width - pad*2;
    final h = size.height - pad*2 - 14; // leave space for label
    final dx = points.length > 1 ? w / (points.length - 1) : 0;

    Path path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = pad + i * dx;
      double y;
      if ((maxV - minV).abs() < 1e-6) {
        y = pad + h/2;
      } else {
        final norm = (points[i] - minV) / (maxV - minV);
        y = pad + 14 + (1 - norm) * h;
      }
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color || oldDelegate.label != label;
  }
}

