import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiBase;
  final String? apiKey;
  WeatherService({required this.apiBase, this.apiKey});

  Future<Map<String, dynamic>?> getCurrentWeather({required double lat, required double lon}) async {
    try {
      final sep = apiBase.contains('?') ? '&' : '?';
      final keyPart = (apiKey != null && apiKey!.isNotEmpty) ? '${sep}key=$apiKey' : '';
      final uri = Uri.parse('$apiBase${sep}lat=$lat&lon=$lon$keyPart');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getOpenMeteoCurrentWeather({required double lat, required double lon}) async {
    try {
      final uri = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

