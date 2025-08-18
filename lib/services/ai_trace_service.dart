import 'dart:convert';

class AiTraceEntry {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final String baseUrl;
  final String path;
  final Map<String, dynamic> requestSummary; // e.g. counts, preview
  int? statusCode;
  bool success;
  String? error;
  Map<String, dynamic>? responseSummary; // e.g. scores size, gifts count

  AiTraceEntry({
    required this.id,
    required this.startTime,
    required this.baseUrl,
    required this.path,
    required this.requestSummary,
    this.statusCode,
    this.success = false,
    this.error,
    this.responseSummary,
  });

  Duration? get duration => endTime != null ? endTime!.difference(startTime) : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'baseUrl': baseUrl,
        'path': path,
        'requestSummary': requestSummary,
        'statusCode': statusCode,
        'success': success,
        'error': error,
        'responseSummary': responseSummary,
      };

  @override
  String toString() => jsonEncode(toJson());
}

class AiTraceService {
  AiTraceService._();
  static final AiTraceService instance = AiTraceService._();

  final List<AiTraceEntry> _entries = [];
  int _maxEntries = 50;

  List<AiTraceEntry> get entries => List.unmodifiable(_entries);

  void recordStart({
    required String id,
    required String baseUrl,
    required String path,
    required Map<String, dynamic> requestSummary,
  }) {
    _entries.insert(
      0,
      AiTraceEntry(
        id: id,
        startTime: DateTime.now(),
        baseUrl: baseUrl,
        path: path,
        requestSummary: requestSummary,
      ),
    );
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
  }

  void recordSuccess({
    required String id,
    required int statusCode,
    required Map<String, dynamic> responseSummary,
  }) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      final e = _entries[idx];
      _entries[idx] = AiTraceEntry(
        id: e.id,
        startTime: e.startTime,
        baseUrl: e.baseUrl,
        path: e.path,
        requestSummary: e.requestSummary,
        statusCode: statusCode,
        success: true,
        responseSummary: responseSummary,
      )..endTime = DateTime.now();
    }
  }

  void recordError({
    required String id,
    int? statusCode,
    required String error,
  }) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      final e = _entries[idx];
      _entries[idx] = AiTraceEntry(
        id: e.id,
        startTime: e.startTime,
        baseUrl: e.baseUrl,
        path: e.path,
        requestSummary: e.requestSummary,
        statusCode: statusCode,
        success: false,
        error: error,
      )..endTime = DateTime.now();
    }
  }
}

