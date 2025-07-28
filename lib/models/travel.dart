/// 旅行记录模型
class Travel {
  final String id;
  final String title;
  final String locationName;
  final double latitude;
  final double longitude;
  final String mood;
  final String description;
  final List<String> tags;
  final List<String> photos;
  final DateTime date;
  bool isFavorite;

  Travel({
    required this.id,
    required this.title,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.mood,
    required this.description,
    required this.tags,
    required this.photos,
    required this.date,
    this.isFavorite = false,
  });

  /// 从JSON创建Travel实例
  factory Travel.fromJson(Map<String, dynamic> json) {
    return Travel(
      id: json['id'] as String,
      title: json['title'] as String,
      locationName: json['locationName'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      mood: json['mood'] as String,
      description: json['description'] as String,
      tags: List<String>.from(json['tags']),
      photos: List<String>.from(json['photos']),
      date: DateTime.parse(json['date'] as String),
      isFavorite: json['isFavorite'] as bool,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'mood': mood,
      'description': description,
      'tags': tags,
      'photos': photos,
      'date': date.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  /// 创建Travel的副本
  Travel copyWith({
    String? id,
    String? title,
    String? locationName,
    double? latitude,
    double? longitude,
    String? mood,
    String? description,
    List<String>? tags,
    List<String>? photos,
    DateTime? date,
    bool? isFavorite,
  }) {
    return Travel(
      id: id ?? this.id,
      title: title ?? this.title,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mood: mood ?? this.mood,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      photos: photos ?? this.photos,
      date: date ?? this.date,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// 旅行统计数据
class TravelStats {
  final int totalRecords;
  final int totalPlaces;
  final List<String> mostVisitedPlaces;
  final List<String> mostUsedTags;
  final String mostCommonMood;

  TravelStats({
    required this.totalRecords,
    required this.totalPlaces,
    required this.mostVisitedPlaces,
    required this.mostUsedTags,
    required this.mostCommonMood,
  });

  /// 从旅行记录列表计算统计数据
  factory TravelStats.fromRecords(List<Travel> records) {
    // 总记录数
    final totalRecords = records.length;

    // 统计地点
    final places = <String, int>{};
    for (final record in records) {
      places[record.locationName] = (places[record.locationName] ?? 0) + 1;
    }

    // 最常访问的地点
    final sortedPlaces = places.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostVisitedPlaces = sortedPlaces.take(3).map((e) => e.key).toList();

    // 统计标签
    final tagCounts = <String, int>{};
    for (final record in records) {
      for (final tag in record.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // 最常用的标签
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostUsedTags = sortedTags.take(5).map((e) => e.key).toList();

    // 统计心情
    final moodCounts = <String, int>{};
    for (final record in records) {
      moodCounts[record.mood] = (moodCounts[record.mood] ?? 0) + 1;
    }

    // 最常见的心情
    String mostCommonMood = '未知';
    if (moodCounts.isNotEmpty) {
      mostCommonMood =
          moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    return TravelStats(
      totalRecords: totalRecords,
      totalPlaces: places.length,
      mostVisitedPlaces: mostVisitedPlaces,
      mostUsedTags: mostUsedTags,
      mostCommonMood: mostCommonMood,
    );
  }
}

/// 表示经纬度坐标的类，代替高德地图的LatLng类
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}
